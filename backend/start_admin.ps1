Set-Location "h:\AibitSoft\book-reading\backend"
$php = "C:\Users\hm862\AppData\Local\Microsoft\WinGet\Packages\PHP.PHP.8.3_Microsoft.Winget.Source_8wekyb3d8bbwe\php.exe"

while ($true) {
    & $php -S 0.0.0.0:8000 -t public server.php
    Start-Sleep -Seconds 1
}
