param([int]$port = 8080)
$root = (Split-Path -Parent $MyInvocation.MyCommand.Path).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$mime = @{ '.html'='text/html'; '.js'='text/javascript'; '.mjs'='text/javascript'; '.css'='text/css'; '.wasm'='application/wasm'; '.task'='application/octet-stream'; '.png'='image/png'; '.json'='application/json' }
function Send-Json($context, $status, $value) {
  $bytes = [Text.Encoding]::UTF8.GetBytes(($value | ConvertTo-Json -Compress))
  $context.Response.StatusCode = $status
  $context.Response.ContentType = 'application/json'
  $context.Response.ContentLength64 = $bytes.Length
  $context.Response.Headers['Cache-Control'] = 'no-store'
  $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
}
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add("http://localhost:$port/")
try { $l.Start() } catch { Write-Host "Cannot start on port $port. Close the old server window and retry. $($_.Exception.Message)"; Read-Host; exit 1 }
Write-Host "Puzzle Cam running at http://localhost:$port/ (keep this window open)"
Write-Host 'Videos are saved inside the project recordings folder. Press F in the browser to start/stop.'
try { Start-Process "http://localhost:$port/" } catch { Write-Host "Open http://localhost:$port/ manually." }
while ($l.IsListening) {
  try { $c = $l.GetContext() } catch { continue }
  $tempFile = $null
  try {
    if ($c.Request.HttpMethod -eq 'POST') {
      if ($c.Request.Url.AbsolutePath -ne '/api/recordings' -or $c.Request.Headers['Origin'] -ne "http://localhost:$port" -or $c.Request.Headers['X-PuzzleCam'] -ne 'recording-v1') {
        Send-Json $c 403 @{ saved=$false; error='Local app requests only' }
        continue
      }
      $length = $c.Request.ContentLength64
      if ($length -le 0 -or $length -gt 314572800) {
        Send-Json $c 413 @{ saved=$false; error='Empty video or video exceeds 300 MB' }
        continue
      }
      $folder = Join-Path $root 'recordings'
      [void][IO.Directory]::CreateDirectory($folder)
      $name = 'puzzle-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [Guid]::NewGuid().ToString('N') + '.webm'
      $target = Join-Path $folder $name
      $tempFile = $target + '.part'
      $output = [IO.File]::Open($tempFile, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
      try {
        $buffer = New-Object byte[] 65536
        $remaining = $length
        while ($remaining -gt 0) {
          $take = [int][Math]::Min([long]$buffer.Length, $remaining)
          $count = $c.Request.InputStream.Read($buffer, 0, $take)
          if ($count -le 0) { throw 'Incomplete upload' }
          $output.Write($buffer, 0, $count)
          $remaining -= $count
        }
        $output.Flush($true)
      } finally { $output.Dispose() }
      [IO.File]::Move($tempFile, $target)
      $tempFile = $null
      Send-Json $c 201 @{ saved=$true; path=('recordings/' + $name) }
      Write-Host "Saved recordings/$name"
      continue
    }
    if ($c.Request.HttpMethod -ne 'GET' -and $c.Request.HttpMethod -ne 'HEAD') { $c.Response.StatusCode = 405; continue }
    $p = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath).TrimStart('/')
    if ($p -eq '') { $p = 'index.html' }
    $f = [IO.Path]::GetFullPath((Join-Path $root $p))
    $recordings = [IO.Path]::GetFullPath((Join-Path $root 'recordings')) + [IO.Path]::DirectorySeparatorChar
    if ($f.StartsWith($recordings, [StringComparison]::OrdinalIgnoreCase)) { $c.Response.StatusCode = 403; continue }
    if ($f.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path $f -PathType Leaf)) {
      $b = [IO.File]::ReadAllBytes($f)
      $e = [IO.Path]::GetExtension($f).ToLower()
      $c.Response.ContentType = if ($mime.ContainsKey($e)) { $mime[$e] } else { 'application/octet-stream' }
      $c.Response.ContentLength64 = $b.Length
      if ($c.Request.HttpMethod -eq 'GET') { $c.Response.OutputStream.Write($b, 0, $b.Length) }
    } else { $c.Response.StatusCode = 404 }
  } catch {
    if ($tempFile -and [IO.File]::Exists($tempFile)) { [IO.File]::Delete($tempFile) }
    try { Send-Json $c 500 @{ saved=$false; error='Could not save video. Check folder permissions and free disk space.' } } catch {}
  } finally { try { $c.Response.Close() } catch {} }
}
