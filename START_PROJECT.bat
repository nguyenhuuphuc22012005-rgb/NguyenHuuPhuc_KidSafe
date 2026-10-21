@echo off
chcp 65001 > nul
title KIDSAFE - BỘ KHỞI ĐỘNG HỆ THỐNG ĐỒ ÁN (ASP.NET CORE + SQL SERVER + FLUTTER)
color 0B

:MENU
cls
echo ======================================================================
echo    ĐỒ ÁN LẬP TRÌNH DI ĐỘNG: ỨNG DỤNG QUẢN LÝ ĐIỆN THOẠI TRẺ EM
echo                     DỰ ÁN: KIDSAFE
echo       Kiến trúc: ASP.NET Core 9 API + SQL Server 2022 + Flutter Mobile
echo ======================================================================
echo.
echo   [1] Khởi động ASP.NET Core 9 Web API (:8000) (Chuẩn Báo Cáo & Sơ Đồ)
echo   [2] Khởi tạo CSDL SQL Server (KidSafeDb qua sqlcmd)
echo   [3] Khởi động Mobile App KidSafe trên Windows Desktop
echo   [4] Khởi động Mobile App KidSafe trên Web Chrome
echo   [5] Khởi động Python FastAPI Server (Dự phòng)
echo   [6] Chạy Kiểm thử Tự động (flutter test)
echo   [7] Mở Swagger UI (http://localhost:8000/swagger)
echo   [8] Mở thư mục Mã nguồn Dự án
echo   [0] Thoát
echo.
echo ======================================================================
set /p choice="Nhập lựa chọn của bạn [0-8]: "

if "%choice%"=="1" goto ASPNET_API
if "%choice%"=="2" goto INIT_SQL
if "%choice%"=="3" goto FLUTTER_WIN
if "%choice%"=="4" goto FLUTTER_WEB
if "%choice%"=="5" goto FASTAPI
if "%choice%"=="6" goto TEST
if "%choice%"=="7" goto OPEN_SWAGGER
if "%choice%"=="8" goto OPEN_DIR
if "%choice%"=="0" exit
goto MENU

:ASPNET_API
cls
echo Đang khởi động ASP.NET Core 9 Web API...
start cmd /k "cd Backend_AspNet && dotnet run"
goto MENU

:INIT_SQL
cls
echo Đang nạp cơ sở dữ liệu vào SQL Server...
sqlcmd -S . -E -i Database\NguyenHuuPhuc_KidSafe.sql
echo.
echo Hoàn tất nạp CSDL KidSafeDb!
pause
goto MENU

:FLUTTER_WIN
cls
echo Đang khởi động Flutter Windows Desktop...
start cmd /k "cd Mobile\nguyenhuuphuc_kidsafe && flutter run -d windows"
goto MENU

:FLUTTER_WEB
cls
echo Đang khởi động Flutter Web Chrome...
start cmd /k "cd Mobile\nguyenhuuphuc_kidsafe && flutter run -d chrome"
goto MENU

:FASTAPI
cls
echo Đang khởi động Backend FastAPI (Dự phòng)...
start cmd /k "cd Backend && run_backend.bat"
goto MENU

:TEST
cls
echo Đang chạy Kiểm thử Tự động...
cd Mobile\nguyenhuuphuc_kidsafe && flutter test
pause
goto MENU

:OPEN_SWAGGER
start http://localhost:8000/swagger
goto MENU

:OPEN_DIR
explorer .
goto MENU
