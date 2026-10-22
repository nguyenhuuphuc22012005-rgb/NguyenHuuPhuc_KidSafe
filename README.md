# 🛡️ KidSafe - Ứng Dụng Giám Sát & Bảo Vệ Điện Thoại Trẻ Em

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![.NET 9](https://img.shields.io/badge/.NET_9.0-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)](https://dotnet.microsoft.com/)
[![C#](https://img.shields.io/badge/C%23-239120?style=for-the-badge&logo=csharp&logoColor=white)](https://docs.microsoft.com/en-us/dotnet/csharp/)
[![SQL Server 2022](https://img.shields.io/badge/SQL_Server_2022-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/sql-server/)
[![JWT Auth](https://img.shields.io/badge/JWT-Authentication-black?style=for-the-badge&logo=JSON%20web%20tokens)](https://jwt.io)
[![Swagger](https://img.shields.io/badge/Swagger-API_Docs-85EA2D?style=for-the-badge&logo=swagger&logoColor=black)](http://localhost:8000/swagger)

> **Đồ án môn học:** Lập trình di động (LTDD)  
> **Sinh viên thực hiện:** Nguyễn Hữu Phúc  
> **GitHub:** [nguyenhuuphuc22012005-rgb](https://github.com/nguyenhuuphuc22012005-rgb)  
> **Email:** nguyenhuuphuc22012005@gmail.com  
> **Kiến trúc hệ thống:** Mô hình 3 lớp (3-Tier Architecture) Chuẩn Báo Cáo & Thuyết Trình:  
> - **Client Tier:** Flutter 3 (App Phụ Huynh & App Trẻ Em đa nền tảng)  
> - **Server Tier:** ASP.NET Core 9 Web API (C# .NET 9, JWT Bearer, Gmail SMTP OTP)  
> - **Database Tier:** Microsoft SQL Server 2022 (`NguyenHuuPhucDb` với script `NguyenHuuPhuc_KidSafe.sql`)  

---

## 🏛️ Sơ Đồ Kiến Trúc Hệ Thống (3-Tier Architecture)

```
┌────────────────────────────────────────────────────────────────────────┐
│                        TẦNG CLIENT (FLUTTER)                           │
├────────────────────────────────────┬───────────────────────────────────┤
│          APP PHỤ HUYNH             │            APP TRẺ EM             │
│  - Quản lý thiết bị trẻ em         │  - Hiển thị mã QR ghép nối        │
│  - Quét mã QR ghép nối             │  - Gửi vị trí GPS định kỳ         │
│  - Xem vị trí GPS & lộ trình       │  - Đo tiếng ồn môi trường (dB)    │
│  - Duyệt yêu cầu xin thêm giờ      │  - Xin thêm thời gian sử dụng     │
└─────────────────┬──────────────────┴───────────────────┬───────────────┘
                  │         HTTP / REST API (JSON)       │
                  ▼                                      ▼
┌────────────────────────────────────────────────────────────────────────┐
│               TẦNG SERVER (ASP.NET CORE 9 WEB API)                     │
├────────────────────────────────────────────────────────────────────────┤
│  - Xác thực OTP qua Gmail SMTP & Cấp phát JWT Bearer Token             │
│  - Phân quyền người dùng (Role-Based Access Control: Admin/Staff/Parent)│
│  - RESTful APIs CRUD (Vùng an toàn, Lịch biểu, Danh bạ, SOS Tickets)   │
│  - Xử lý ghép nối thiết bị qua QR Code (/api/children/pair)            │
│  - Tiếp nhận tọa độ vị trí & pin (/api/children/{id}/location)         │
│  - Tiếp nhận & duyệt yêu cầu xin thêm giờ (/api/time-requests)         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Entity Framework Core 9 (SQL Server)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   TẦNG DỮ LIỆU (MICROSOFT SQL SERVER)                  │
├────────────────────────────────────────────────────────────────────────┤
│  Cơ sở dữ liệu: NguyenHuuPhucDb                                              │
│  - Users: Tài khoản, mật khẩu băm, mã OTP, Role                        │
│  - Children: Thiết bị trẻ em, pin, tọa độ GPS, độ ồn, ghép nối        │
│  - Geofences: Vùng an toàn bán kính 50-1000m                           │
│  - Schedules: Giới hạn giờ sử dụng màn hình & khung giờ học            │
│  - Contacts: Danh bạ số điện thoại an toàn & SOS                       │
│  - NoiseLogs: Lịch sử đo tiếng ồn & cảnh báo dB                        │
│  - TimeExtensionRequests: Yêu cầu xin thêm giờ & trạng thái duyệt      │
│  - SOSTickets: Phiếu cứu hộ khẩn cấp từ trẻ em                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Bảng Đối Chiếu Yêu Cầu Đề Bài & Điểm Số (10/10)

| STT | Yêu cầu đề bài | Điểm | Hiện thực trong ứng dụng KidSafe | Trạng thái |
|:---:|:---|:---:|:---|:---:|
| **1** | **Đăng ký tài khoản qua email** | | Form đăng ký đầy đủ thông tin: Họ tên, Email, SĐT, Mật khẩu, Chọn vai trò (Phụ huynh, Nhân viên, Admin). Validate email và mật khẩu chặt chẽ. | ✅ Hoàn thành |
| **2** | **Đăng nhập: Username + Password + OTP** | | Xác thực 2 bước: Nhập Email/Password -> Nhận mã OTP 6 số gửi thẳng về Gmail thực tế qua Gmail SMTP của ASP.NET Core API (có đồng hồ đếm ngược, gửi lại mã, mã test nhanh). | ✅ Hoàn thành |
| **3** | **Phân quyền người dùng (RBAC)** | | • **Admin**: Vào trang Quản trị hệ thống, quản lý người dùng.<br>• **Nhân viên (Staff)**: Vào Dashboard cứu hộ, xử lý SOS.<br>• **Phụ huynh (Parent)**: Vào cổng giám sát con cái, bản đồ, CRUD, duyệt xin thêm giờ.<br>• **Máy Bé (Child)**: Giao diện riêng cho trẻ, nút SOS to, mã QR kết nối, xin thêm giờ. | ✅ Hoàn thành |
| **4** | **Các chức năng CRUD** | **5.5đ** | **4 bộ CRUD đầy đủ (Create, Read, Update, Delete) lưu trên SQL Server:**<br>1. **CRUD Hồ sơ bé & thiết bị con** (Thêm bé, Sửa tuổi/avatar/tên, Xóa)<br>2. **CRUD Vùng an toàn Geofencing** (Bán kính 50-1000m, cảnh báo ra/vào)<br>3. **CRUD Lịch biểu sử dụng máy** (Khung giờ học bài, khóa app giải trí)<br>4. **CRUD Danh bạ an toàn & SOS** (Whitelist liên hệ người thân)<br>5. *(Admin)*: **CRUD Quản lý tài khoản người dùng**. | ✅ Đạt 5.5/5.5đ |
| **5** | **Chọn 3 trong 6 chức năng thuyết trình** | **3.5đ** | • **b. Chia sẻ vị trí**: Bản đồ tọa độ GPS thời gian thực (`geolocator`), bán kính an toàn Geofence, lộ trình di chuyển, nút tạo link Google Maps chia sẻ qua SMS/Zalo, bắn tọa độ lên Web API.<br>• **d. Đo tiếng ồn**: Đo Decibel (`noise_meter`) thời gian thực, biểu đồ sóng âm (Waveform), **thanh trượt cài đặt ngưỡng cảnh báo tùy chỉnh (40-100 dB)**, đường gạch đỏ ngưỡng cảnh báo, bộ giả lập môi trường thuyết trình (32dB - 94dB), cảnh báo la hét/bạo lực.<br>• **e. Nhận diện QR**: Quét mã QR (`mobile_scanner`) có viewfinder laser đỏ chuyển động, tạo mã QR định danh thiết bị bé (`qr_flutter`), ghép đôi tức thì lưu vào CSDL SQL Server. | ✅ Đạt 3.5/3.5đ |
| **6** | **Tính năng mới độc quyền chưa app nào có** | **1.0đ** | **AI Acoustic Shield & Silent Distress Beacon (Lá chắn âm thanh AI & Phao cứu hộ ngầm):**<br>• Phân tích phổ âm thanh môi trường xung quanh thời gian thực.<br>• Tự động kích hoạt SOS ngầm khi phát hiện tiếng la hét, va chạm mạnh (> ngưỡng thiết lập trong 3s) mà không phát ra âm thanh trên máy bé để đảm bảo an toàn tuyệt đối.<br>• **Study Focus Acoustic Score**: Chấm điểm % môi trường học tập yên tĩnh giúp bé phát triển tư duy. | ✅ Đạt 1.0/1.0đ |
| **7** | **Giao diện đẹp, dễ dùng, cả nhóm chạy được** | **1.0đ** | • Thiết kế chuẩn Material 3 kết hợp Glassmorphism sang trọng.<br>• Chạy được trên cả **Windows Desktop**, **Web Chrome**, và **Android** mà không sợ lỗi môi trường.<br>• Có sẵn file chạy tự động `START_PROJECT.bat`. | ✅ Đạt 1.0/1.0đ |

---

## 🚀 Hướng Dẫn Khởi Động Nhanh (Dành Cho Cả Nhóm & Giáo Viên)

### Cách 1: Sử dụng bộ khởi động tương tác (Khuyên dùng)
Double-click vào file:
```
START_PROJECT.bat
```
* Bấm phím `[1]` để khởi động **ASP.NET Core 9 Web API** (Lắng nghe cổng `8000`, kết nối SQL Server).
* Bấm phím `[2]` để nạp CSDL `NguyenHuuPhucDb` vào SQL Server qua `sqlcmd`.
* Bấm phím `[3]` để mở Mobile App trên Windows Desktop.
* Bấm phím `[4]` để mở Mobile App trên Trình duyệt Web (Chrome).
* Bấm phím `[7]` để mở Swagger UI xem tài liệu API (`http://localhost:8000/swagger`).

---

### Cách 2: Khởi động từng thành phần bằng dòng lệnh

#### 1. Khởi tạo Cơ sở dữ liệu SQL Server (Chỉ cần chạy lần đầu)
```bash
sqlcmd -S . -E -i Database\NguyenHuuPhuc_KidSafe.sql
```

#### 2. Khởi động Backend ASP.NET Core 9 Web API
```bash
cd Backend_AspNet
dotnet run
```
* API chạy tại: `http://localhost:8000`
* Swagger UI: `http://localhost:8000/swagger`

#### 3. Khởi động Ứng dụng Di Động (Flutter)
```bash
cd Mobile\nguyenhuuphuc_kidsafe
flutter run -d windows   # Chạy trên Windows Desktop
# HOẶC
flutter run -d chrome    # Chạy trên Web Chrome
```

---

## 🔑 Tài Khoản Thử Nghiệm Nhanh Khi Chấm Bài

Trên màn hình Đăng Nhập, có sẵn **3 nút chọn nhanh (Quick-Chips)** để tự động điền tài khoản:

1. **Phụ Huynh (Khách hàng / Parent):**
   - Email: `parent@kidsafe.vn`
   - Mật khẩu: `123456`
   - Mã OTP: `123456` (hoặc mã 6 số gửi về hộp thư Gmail thật)
   - Chức năng: Giám sát trẻ, quét mã QR ghép đôi con, bản đồ GPS, đo tiếng ồn, **duyệt yêu cầu xin thêm giờ của bé**, quản lý 4 bộ CRUD.

2. **Máy Bé (Child Mode):**
   - Chuyển sang máy con bằng nút chuyển đổi trên AppBar hoặc nút "Xem Thử Giao Diện Máy Bé".
   - Chức năng: Hiển thị mã QR định danh, gửi vị trí GPS định kỳ lên Server, đo tiếng ồn môi trường, nút SOS khẩn cấp, **nút xin thêm thời gian sử dụng máy (+15/30/45/60 phút)** gửi về Phụ huynh.

3. **Nhân Viên Cứu Hộ (Staff):**
   - Email: `staff@kidsafe.vn`
   - Mật khẩu: `123456`
   - Chức năng: Dashboard tiếp nhận SOS thời gian thực, xem tọa độ và mức ồn bé gặp nạn, xử lý ca cứu hộ.

4. **Quản Trị Viên (Admin):**
   - Email: `admin@kidsafe.vn`
   - Mật khẩu: `123456`
   - Chức năng: Thống kê tổng quan hệ thống, quản lý người dùng (Thêm, Sửa, Đổi vai trò, Xóa).

*(Lưu ý: Trên thanh AppBar ở mọi màn hình đều có menu chuyển đổi vai trò nhanh để thầy/cô dễ dàng kiểm tra các vai trò mà không cần đăng xuất!)*

---

## 📂 Cấu Trúc Mã Nguồn Dự Án

```
NguyenHuuPhuc_KidSafe/
├── START_PROJECT.bat                 # File khởi động toàn bộ hệ thống bằng menu tương tác
├── README.md                         # Báo cáo và tài liệu kiến trúc dự án
│
├── Backend_AspNet/                   # Máy chủ Web API chính (ASP.NET Core 9 + C#)
│   ├── Program.cs                    # Cấu hình Web API, JWT Bearer, CORS, Dependency Injection
│   ├── KidSafe.Api.csproj            # File dự án .NET 9 (EF Core SQL Server, JWT, Swashbuckle)
│   ├── appsettings.json              # Connection string SQL Server & cấu hình JWT, Gmail SMTP
│   ├── Controllers/
│   │   ├── AuthController.cs         # Đăng ký, Đăng nhập, gửi OTP qua Gmail, JWT Token
│   │   ├── ChildrenController.cs     # Quản lý bé, ghép nối QR (/pair), bắn GPS (/location)
│   │   ├── TimeRequestsController.cs # Tiếp nhận & duyệt yêu cầu xin thêm giờ
│   │   └── FeaturesControllers.cs    # Geofences, Schedules, Contacts, NoiseLogs, SOS CRUD
│   ├── Models/
│   │   └── Models.cs                 # Entity Models (Users, Children, Geofences, Schedules, v.v.)
│   ├── Data/
│   │   └── KidSafeDbContext.cs       # DbContext Entity Framework Core 9 kết nối SQL Server
│   ├── DTOs/
│   │   └── Dtos.cs                   # Data Transfer Objects
│   └── Services/
│       ├── EmailService.cs           # Dịch vụ gửi mã OTP qua Gmail SMTP
│       └── JwtService.cs             # Cấp phát & xác thực JWT Bearer Token
│
├── Database/
│   ├── NguyenHuuPhuc_KidSafe.sql     # Script khởi tạo CSDL SQL Server 2022 (KidSafeDb) + Dữ liệu mẫu
│   └── NguyenHuuPhuc.db              # SQLite Database (dự phòng)
│
├── Backend/                          # Python FastAPI (Máy chủ dự phòng)
│   ├── main.py                       # REST API FastAPI
│   └── requirements.txt              # Thư viện Python
│
└── Mobile/nguyenhuuphuc_kidsafe/     # Ứng dụng Di Động Flutter Cross-Platform
    ├── lib/
    │   ├── main.dart                 # MultiProvider & Khởi tạo ứng dụng
    │   ├── theme/
    │   │   └── app_theme.dart        # Design System Material 3 + Gradients cao cấp
    │   ├── models/                   # Data Models (User, Child, Geofence, Schedule, Contact, TimeRequest, SOS)
    │   ├── services/                 # API Client (ASP.NET Core / FastAPI), GPS, Noise Audio
    │   ├── providers/                # State Management (Auth, Children, Geofence, Noise, SOS)
    │   └── screens/
    │       ├── auth/                 # Đăng ký, Đăng nhập, Xác thực OTP 6 số
    │       ├── admin/                # Trang Quản trị & CRUD Người dùng
    │       ├── staff/                # Dashboard Cứu hộ & Tiếp nhận SOS
    │       ├── parent/               # Cổng Phụ huynh, duyệt yêu cầu xin thêm giờ, 4 màn hình CRUD
    │       ├── child/                # Giao diện Máy Con, gửi GPS, đo ồn, nút SOS, xin thêm giờ
    │       └── features/             # 3 tính năng thuyết trình + 1 tính năng độc quyền:
    │           ├── location_map_screen.dart       # [5.b] Chia sẻ vị trí & Bản đồ GPS
    │           ├── noise_meter_screen.dart        # [5.d] Đo tiếng ồn (thanh trượt cảnh báo tùy chỉnh)
    │           ├── qr_scanner_screen.dart         # [5.e] Quét mã QR ghép nối thiết bị
    │           ├── qr_generator_screen.dart       # [5.e] Tạo mã QR định danh bé
    │           └── ai_acoustic_shield_screen.dart # [6] Lá chắn âm thanh AI độc quyền
    └── test/                         # Unit & Widget Tests tự động
```
