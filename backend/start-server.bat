@echo off
echo ===================================================
echo   MEMULAI SERVER COMMUNITY SUITE...
echo ===================================================

echo [1] Menjalankan API Server & Discord Bot...
start cmd /k "npm start"

echo.
echo [2] Menjalankan Tunnel Publik...
echo URL Publik Aplikasi: https://my-community-suite-api.loca.lt
start cmd /k "npx localtunnel --port 3000 --subdomain my-community-suite-api"

echo.
echo Server dan Tunnel sedang berjalan di dua jendela baru!
echo JANGAN TUTUP dua jendela hitam tersebut jika ingin aplikasi tetap online.
pause
