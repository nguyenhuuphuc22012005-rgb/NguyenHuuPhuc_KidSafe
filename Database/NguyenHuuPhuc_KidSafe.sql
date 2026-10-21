-- ====================================================================
-- HỆ THỐNG GIÁM SÁT & BẢO VỆ ĐIỆN THOẠI TRẺ EM: KIDSAFE
-- Sinh viên thực hiện: Nguyễn Hữu Phúc
-- Hệ quản trị CSDL: Microsoft SQL Server 2022
-- ====================================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'KidSafeDb')
BEGIN
    CREATE DATABASE KidSafeDb;
END
GO

USE KidSafeDb;
GO

-- Xóa các bảng cũ nếu tồn tại (theo thứ tự khóa ngoại)
IF OBJECT_ID('dbo.TimeExtensionRequests', 'U') IS NOT NULL DROP TABLE dbo.TimeExtensionRequests;
IF OBJECT_ID('dbo.SOSTickets', 'U') IS NOT NULL DROP TABLE dbo.SOSTickets;
IF OBJECT_ID('dbo.NoiseLogs', 'U') IS NOT NULL DROP TABLE dbo.NoiseLogs;
IF OBJECT_ID('dbo.Contacts', 'U') IS NOT NULL DROP TABLE dbo.Contacts;
IF OBJECT_ID('dbo.Schedules', 'U') IS NOT NULL DROP TABLE dbo.Schedules;
IF OBJECT_ID('dbo.Geofences', 'U') IS NOT NULL DROP TABLE dbo.Geofences;
IF OBJECT_ID('dbo.Children', 'U') IS NOT NULL DROP TABLE dbo.Children;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
GO

-- 1. BẢNG TÀI KHOẢN NGƯỜI DÙNG (Users: Admin, Staff, Parent, Child)
CREATE TABLE dbo.Users (
    Id NVARCHAR(50) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(150) NOT NULL UNIQUE,
    Password NVARCHAR(255) NOT NULL,
    Phone NVARCHAR(20) NULL,
    Role NVARCHAR(20) NOT NULL, -- admin, staff, parent, child
    Avatar NVARCHAR(255) NULL,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME()
);
GO

-- 2. BẢNG THIẾT BỊ & TRẺ EM (Children & Devices: Vị trí, Pin, Giới hạn thời gian)
CREATE TABLE dbo.Children (
    Id NVARCHAR(50) PRIMARY KEY,
    ParentId NVARCHAR(50) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Age INT NOT NULL,
    Gender NVARCHAR(10) DEFAULT 'male',
    Phone NVARCHAR(20) NULL,
    Avatar NVARCHAR(50) DEFAULT 'avatar_boy_1',
    DeviceId NVARCHAR(100) UNIQUE NOT NULL,
    BatteryLevel INT DEFAULT 85,
    Latitude FLOAT DEFAULT 10.7769,
    Longitude FLOAT DEFAULT 106.7009,
    LastSeen NVARCHAR(100) DEFAULT N'Vừa xong',
    CurrentNoiseDb FLOAT DEFAULT 42.0,
    IsOnline BIT DEFAULT 1,
    DailyScreenLimitMinutes INT DEFAULT 180,
    UsedScreenMinutes INT DEFAULT 65,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Children_Users FOREIGN KEY (ParentId) REFERENCES dbo.Users(Id) ON DELETE CASCADE
);
GO

-- 3. BẢNG QUY TẮC: VÙNG AN TOÀN (Geofences)
CREATE TABLE dbo.Geofences (
    Id NVARCHAR(50) PRIMARY KEY,
    ChildId NVARCHAR(50) NOT NULL,
    Name NVARCHAR(150) NOT NULL,
    Latitude FLOAT NOT NULL,
    Longitude FLOAT NOT NULL,
    RadiusMeters FLOAT NOT NULL,
    IsActive BIT DEFAULT 1,
    NotifyOnExit BIT DEFAULT 1,
    NotifyOnEntry BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Geofences_Children FOREIGN KEY (ChildId) REFERENCES dbo.Children(Id) ON DELETE CASCADE
);
GO

-- 4. BẢNG QUY TẮC: LỊCH BIỂU SỬ DỤNG (Schedules)
CREATE TABLE dbo.Schedules (
    Id NVARCHAR(50) PRIMARY KEY,
    ChildId NVARCHAR(50) NOT NULL,
    Title NVARCHAR(150) NOT NULL,
    StartTime NVARCHAR(10) NOT NULL, -- "HH:mm"
    EndTime NVARCHAR(10) NOT NULL,   -- "HH:mm"
    Days NVARCHAR(100) NOT NULL,     -- "Mon,Tue,Wed,Thu,Fri"
    IsActive BIT DEFAULT 1,
    BlockApps BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Schedules_Children FOREIGN KEY (ChildId) REFERENCES dbo.Children(Id) ON DELETE CASCADE
);
GO

-- 5. BẢNG QUY TẮC: DANH BẠ AN TOÀN & LIÊN HỆ KHẨN CẤP (Contacts)
CREATE TABLE dbo.Contacts (
    Id NVARCHAR(50) PRIMARY KEY,
    ChildId NVARCHAR(50) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20) NOT NULL,
    Relationship NVARCHAR(50) NOT NULL,
    IsSosContact BIT DEFAULT 0,
    Avatar NVARCHAR(50) NULL,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Contacts_Children FOREIGN KEY (ChildId) REFERENCES dbo.Children(Id) ON DELETE CASCADE
);
GO

-- 6. BẢNG TIẾNG ỒN: NHẬT KÝ ĐO TIẾNG ỒN MÔI TRƯỜNG (NoiseLogs)
CREATE TABLE dbo.NoiseLogs (
    Id NVARCHAR(50) PRIMARY KEY,
    ChildId NVARCHAR(50) NOT NULL,
    Decibel FLOAT NOT NULL,
    Status NVARCHAR(20) NOT NULL, -- Quiet, Normal, Loud, Danger
    Timestamp NVARCHAR(50) NOT NULL,
    Note NVARCHAR(255) NULL,
    CONSTRAINT FK_NoiseLogs_Children FOREIGN KEY (ChildId) REFERENCES dbo.Children(Id) ON DELETE CASCADE
);
GO

-- 7. BẢNG YÊU CẦU: YÊU CẦU XIN THÊM THỜI GIAN CỦA TRẺ (TimeExtensionRequests)
CREATE TABLE dbo.TimeExtensionRequests (
    Id NVARCHAR(50) PRIMARY KEY,
    ChildId NVARCHAR(50) NOT NULL,
    ChildName NVARCHAR(100) NOT NULL,
    MinutesRequested INT NOT NULL, -- ví dụ 15, 30, 60 phút
    Reason NVARCHAR(255) NOT NULL,
    Status NVARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    ReviewedAt DATETIME2 NULL,
    ReviewedBy NVARCHAR(50) NULL,
    CONSTRAINT FK_TimeRequests_Children FOREIGN KEY (ChildId) REFERENCES dbo.Children(Id) ON DELETE CASCADE
);
GO

-- 8. BẢNG YÊU CẦU: CẢNH BÁO CỨU HỘ KHẨN CẤP SOS (SOSTickets)
CREATE TABLE dbo.SOSTickets (
    Id NVARCHAR(50) PRIMARY KEY,
    ChildId NVARCHAR(50) NOT NULL,
    ChildName NVARCHAR(100) NOT NULL,
    ParentName NVARCHAR(100) NULL,
    ParentPhone NVARCHAR(20) NULL,
    Latitude FLOAT NOT NULL,
    Longitude FLOAT NOT NULL,
    NoiseLevel FLOAT DEFAULT 0.0,
    Reason NVARCHAR(255) NOT NULL,
    Status NVARCHAR(20) DEFAULT 'pending', -- pending, in_progress, resolved
    AssignedStaffId NVARCHAR(50) NULL,
    ResolutionNotes NVARCHAR(500) NULL,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_SOSTickets_Children FOREIGN KEY (ChildId) REFERENCES dbo.Children(Id) ON DELETE CASCADE
);
GO

-- ====================================================================
-- DỮ LIỆU KHỞI TẠO MẪU (SEED DATA)
-- ====================================================================

-- Users
INSERT INTO dbo.Users (Id, Name, Email, Password, Phone, Role, Avatar) VALUES
('usr_admin_01', N'Nguyễn Hữu Phúc', 'nguyenhuuphuc22012005@gmail.com', 'phuc2201', '0901234567', 'admin', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
('usr_parent_01', N'Nguyễn Hữu Phúc', 'parent@kidsafe.vn', '123456', '0988776655', 'parent', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150'),
('usr_child_01', N'Bé Bo (Thiết Bị Con)', 'child@kidsafe.vn', '123456', '0911223344', 'child', 'https://images.unsplash.com/photo-1543332164-6e82f355badc?w=150'),
('usr_staff_01', N'Nguyễn Hữu Phúc', 'staff@kidsafe.vn', '123456', '0909876543', 'staff', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150');

-- Children
INSERT INTO dbo.Children (Id, ParentId, Name, Age, Gender, Phone, Avatar, DeviceId, BatteryLevel, Latitude, Longitude, LastSeen, CurrentNoiseDb, IsOnline, DailyScreenLimitMinutes, UsedScreenMinutes) VALUES
('ch_01', 'usr_parent_01', N'Bé Bo (Gia Bảo)', 8, 'male', '0911223344', 'avatar_boy_1', 'DEV-KID-BO-8821', 85, 10.7769, 106.7009, N'Vừa xong', 45.2, 1, 180, 75),
('ch_02', 'usr_parent_01', N'Bé Bông (Mai Anh)', 6, 'female', '0911223355', 'avatar_girl_1', 'DEV-KID-BONG-9932', 62, 10.7725, 106.6980, N'5 phút trước', 52.0, 1, 120, 45);

-- Geofences
INSERT INTO dbo.Geofences (Id, ChildId, Name, Latitude, Longitude, RadiusMeters, IsActive, NotifyOnExit, NotifyOnEntry) VALUES
('geo_01', 'ch_01', N'Trường Tiểu Học Nguyễn Huệ', 10.7769, 106.7009, 250.0, 1, 1, 1),
('geo_02', 'ch_01', N'Nhà Riêng (Chung cư Sunview)', 10.7820, 106.6950, 150.0, 1, 1, 1),
('geo_03', 'ch_02', N'Trường Mầm Non Họa Mi', 10.7725, 106.6980, 200.0, 1, 1, 1);

-- Schedules
INSERT INTO dbo.Schedules (Id, ChildId, Title, StartTime, EndTime, Days, IsActive, BlockApps) VALUES
('sch_01', 'ch_01', N'Giờ Học Bài Buổi Tối', '19:30', '21:00', 'Mon,Tue,Wed,Thu,Fri', 1, 1),
('sch_02', 'ch_01', N'Giờ Đi Ngủ', '22:00', '06:30', 'Mon,Tue,Wed,Thu,Fri,Sat,Sun', 1, 1),
('sch_03', 'ch_02', N'Giờ Ngủ Trưa', '12:00', '13:30', 'Mon,Tue,Wed,Thu,Fri', 1, 1);

-- Contacts
INSERT INTO dbo.Contacts (Id, ChildId, Name, Phone, Relationship, IsSosContact, Avatar) VALUES
('con_01', 'ch_01', N'Nguyễn Hữu Phúc', '0988776655', N'Bố', 1, 'avatar_dad'),
('con_02', 'ch_01', N'Mẹ (Trần Thị Mai)', '0977889900', N'Mẹ', 1, 'avatar_mom'),
('con_03', 'ch_01', N'Cô Lan (Chủ nhiệm lớp 3A)', '0933445566', N'Giáo viên', 0, 'avatar_teacher'),
('con_04', 'ch_01', N'Cảnh Sát Khẩn Cấp 113', '113', N'Khẩn cấp', 1, 'avatar_police');

-- NoiseLogs
INSERT INTO dbo.NoiseLogs (Id, ChildId, Decibel, Status, Timestamp, Note) VALUES
('nl_01', 'ch_01', 42.5, 'Normal', '14:20 22/10', N'Âm thanh trong lớp học'),
('nl_02', 'ch_01', 78.0, 'Loud', '15:10 22/10', N'Giờ ra chơi sân trường');

-- TimeExtensionRequests (Yêu cầu xin thêm giờ mẫu)
INSERT INTO dbo.TimeExtensionRequests (Id, ChildId, ChildName, MinutesRequested, Reason, Status) VALUES
('req_01', 'ch_01', N'Bé Bo (Gia Bảo)', 30, N'Con cần thêm 30 phút để hoàn thành bài tập toán tiếng Anh online ạ.', 'pending');

-- SOSTickets
INSERT INTO dbo.SOSTickets (Id, ChildId, ChildName, ParentName, ParentPhone, Latitude, Longitude, NoiseLevel, Reason, Status, AssignedStaffId, ResolutionNotes) VALUES
('sos_01', 'ch_01', N'Bé Bo (Gia Bảo)', N'Nguyễn Hữu Phúc', '0988776655', 10.7769, 106.7009, 88.5, N'Phát hiện tiếng ồn vượt ngưỡng (88.5 dB) và bé nhấn nút SOS!', 'pending', NULL, NULL),
('sos_02', 'ch_02', N'Bé Bông (Mai Anh)', N'Nguyễn Hữu Phúc', '0988776655', 10.7725, 106.6980, 52.0, N'Cảnh báo: Bé di chuyển ra khỏi vùng an toàn Trường mầm non', 'resolved', 'usr_staff_01', N'Đã liên hệ phụ huynh, phụ huynh đã đón bé an toàn.');
GO

PRINT N'✅ Khởi tạo CSDL KidSafeDb trên SQL Server hoàn tất!';
GO
