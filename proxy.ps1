# Postlite local CORS proxy - PowerShell version (no Python needed).
# Runs on this machine, calls the target API server-side (no browser CORS),
# returns the response with CORS headers. Run on the machine that has the VPN.
#
#   powershell -ExecutionPolicy Bypass -File proxy.ps1            (port 8010)
#   powershell -ExecutionPolicy Bypass -File proxy.ps1 9000       (custom port)
#
# Uses a raw TCP listener on 127.0.0.1 (no admin / no URL reservation needed).

param([int]$Port = 8010)

$ErrorActionPreference = 'Stop'
# accept self-signed / TLS-inspected corporate certs (like Postman "disable SSL verify")
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
try {
  [System.Net.ServicePointManager]::SecurityProtocol =
    [System.Net.SecurityProtocolType]::Tls12 -bor `
    [System.Net.SecurityProtocolType]::Tls11 -bor `
    [System.Net.SecurityProtocolType]::Tls
} catch {}

$CRLF = "`r`n"
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
try { $listener.Start() }
catch { Write-Host "Could not bind port $Port : $($_.Exception.Message)"; Write-Host "Try another port: proxy.ps1 9000"; exit 1 }

Write-Host "Postlite proxy running at http://localhost:$Port"
Write-Host "In Postlite: click 'Proxy', tick it on, set URL to http://localhost:$Port, Save."
Write-Host "Keep this window open. Press Ctrl+C to stop."

function Find-HeaderEnd([byte[]]$b, [int]$len) {
  for ($i = 0; $i -le $len - 4; $i++) {
    if ($b[$i] -eq 13 -and $b[$i+1] -eq 10 -and $b[$i+2] -eq 13 -and $b[$i+3] -eq 10) { return $i }
  }
  return -1
}
function Send-Raw($stream, [string]$head, [byte[]]$body) {
  $hb = [System.Text.Encoding]::ASCII.GetBytes($head)
  $stream.Write($hb, 0, $hb.Length)
  if ($body -and $body.Length -gt 0) { $stream.Write($body, 0, $body.Length) }
  $stream.Flush()
}

while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $stream = $client.GetStream()
    $buf = New-Object System.Collections.Generic.List[byte]
    $tmp = New-Object byte[] 8192
    $headerEnd = -1
    while ($headerEnd -lt 0) {
      $n = $stream.Read($tmp, 0, $tmp.Length)
      if ($n -le 0) { break }
      for ($i = 0; $i -lt $n; $i++) { [void]$buf.Add($tmp[$i]) }
      $arr = $buf.ToArray()
      $headerEnd = Find-HeaderEnd $arr $arr.Length
      if ($buf.Count -gt 4000000) { break }
    }
    if ($headerEnd -lt 0) { $client.Close(); continue }

    $arr = $buf.ToArray()
    $headerText = [System.Text.Encoding]::ASCII.GetString($arr, 0, $headerEnd)
    $lines = $headerText -split "`r`n"
    $method = ($lines[0] -split ' ')[0]
    $hdrs = @{}
    for ($i = 1; $i -lt $lines.Length; $i++) {
      $ci = $lines[$i].IndexOf(':')
      if ($ci -gt 0) { $hdrs[$lines[$i].Substring(0, $ci).Trim()] = $lines[$i].Substring($ci + 1).Trim() }
    }

    if ($method -eq 'OPTIONS') {
      $head = "HTTP/1.1 204 No Content$CRLF" +
              "Access-Control-Allow-Origin: *$CRLF" +
              "Access-Control-Allow-Methods: GET,POST,PUT,PATCH,DELETE,HEAD,OPTIONS$CRLF" +
              "Access-Control-Allow-Headers: *$CRLF" +
              "Access-Control-Max-Age: 86400$CRLF" +
              "Content-Length: 0$CRLF" + "Connection: close$CRLF$CRLF"
      Send-Raw $stream $head $null; $client.Close(); continue
    }

    $target = $null
    foreach ($k in $hdrs.Keys) { if ($k.ToLower() -eq 'x-pl-target') { $target = $hdrs[$k] } }
    if (-not $target) {
      $body = [System.Text.Encoding]::UTF8.GetBytes("Postlite proxy: missing X-PL-Target header")
      $head = "HTTP/1.1 400 Bad Request$CRLF" + "Access-Control-Allow-Origin: *$CRLF" +
              "Content-Type: text/plain$CRLF" + "Content-Length: $($body.Length)$CRLF" + "Connection: close$CRLF$CRLF"
      Send-Raw $stream $head $body; $client.Close(); continue
    }

    # body (browser fetch always sends Content-Length)
    $clen = 0
    foreach ($k in $hdrs.Keys) { if ($k.ToLower() -eq 'content-length') { [void][int]::TryParse($hdrs[$k], [ref]$clen) } }
    $bodyBytes = New-Object byte[] 0
    if ($clen -gt 0) {
      $body = New-Object System.Collections.Generic.List[byte]
      for ($i = $headerEnd + 4; $i -lt $arr.Length; $i++) { [void]$body.Add($arr[$i]) }
      while ($body.Count -lt $clen) {
        $n = $stream.Read($tmp, 0, [Math]::Min($tmp.Length, $clen - $body.Count))
        if ($n -le 0) { break }
        for ($i = 0; $i -lt $n; $i++) { [void]$body.Add($tmp[$i]) }
      }
      $bodyBytes = $body.ToArray()
    }

    try {
      $req = [System.Net.HttpWebRequest]::Create($target)
      $req.Method = $method
      $req.AllowAutoRedirect = $true
      $req.Timeout = 120000
      $req.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
      $skip = @('host','content-length','connection','x-pl-target','origin','referer','accept-encoding')
      foreach ($k in $hdrs.Keys) {
        $lk = $k.ToLower()
        if ($skip -contains $lk) { continue }
        try {
          if ($lk -eq 'content-type') { $req.ContentType = $hdrs[$k] }
          elseif ($lk -eq 'user-agent') { $req.UserAgent = $hdrs[$k] }
          elseif ($lk -eq 'accept') { $req.Accept = $hdrs[$k] }
          else { $req.Headers[$k] = $hdrs[$k] }
        } catch {}
      }
      if ($bodyBytes.Length -gt 0) {
        $req.ContentLength = $bodyBytes.Length
        $rs = $req.GetRequestStream(); $rs.Write($bodyBytes, 0, $bodyBytes.Length); $rs.Close()
      }
      try { $response = $req.GetResponse() }
      catch [System.Net.WebException] { $response = $_.Exception.Response; if (-not $response) { throw } }

      $status = [int]$response.StatusCode
      $desc = $response.StatusDescription
      $rstream = $response.GetResponseStream()
      $mem = New-Object System.IO.MemoryStream
      $rstream.CopyTo($mem); $payload = $mem.ToArray()

      $passHeaders = ""
      foreach ($hk in $response.Headers.AllKeys) {
        $lk = $hk.ToLower()
        if (@('transfer-encoding','content-length','connection','content-encoding','keep-alive') -contains $lk) { continue }
        if ($lk.StartsWith('access-control-')) { continue }
        $passHeaders += "$hk: $($response.Headers[$hk])$CRLF"
      }
      $head = "HTTP/1.1 $status $desc$CRLF" + $passHeaders +
              "Access-Control-Allow-Origin: *$CRLF" +
              "Access-Control-Expose-Headers: *$CRLF" +
              "Content-Length: $($payload.Length)$CRLF" + "Connection: close$CRLF$CRLF"
      if ($method -eq 'HEAD') { Send-Raw $stream $head $null } else { Send-Raw $stream $head $payload }
      $response.Close()
      Write-Host ("{0} -> {1}  [{2}]" -f $method, $target, $status)
    } catch {
      $body = [System.Text.Encoding]::UTF8.GetBytes("Postlite proxy error: $($_.Exception.Message)")
      $head = "HTTP/1.1 502 Bad Gateway$CRLF" + "Access-Control-Allow-Origin: *$CRLF" +
              "Content-Type: text/plain$CRLF" + "Content-Length: $($body.Length)$CRLF" + "Connection: close$CRLF$CRLF"
      Send-Raw $stream $head $body
      Write-Host ("{0} -> {1}  [ERROR] {2}" -f $method, $target, $_.Exception.Message)
    }
  } catch {
    Write-Host "connection error: $($_.Exception.Message)"
  } finally {
    try { $client.Close() } catch {}
  }
}
