import uuid
import random
import datetime
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from database import init_db, get_db
from email_service import send_otp_email, send_otp_sms
import schemas

app = FastAPI(
    title="KidSafe API - Hệ Thống Giám Sát Điện Thoại Trẻ Em",
    version="1.0.0",
    description="Hệ thống Backend RESTful API phục vụ đồ án Lập trình di động: Quản lý điện thoại trẻ em"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Lưu trữ tạm thời mã OTP trong bộ nhớ: {email: {"otp": "123456", "expires_at": datetime}}
otp_store = {}

def seed_initial_data():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM users")
    count = cursor.fetchone()[0]
    if count == 0:
        # Tạo Admin (Nguyễn Hữu Phúc), Staff, Parent, Child mẫu
        users = [
            ("usr_admin_01", "Nguyễn Hữu Phúc", "nguyenhuuphuc22012005@gmail.com", "phuc2201", "0901234567", "admin", "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150"),
            ("usr_parent_01", "Nguyễn Hữu Phúc", "parent@kidsafe.vn", "123456", "0988776655", "parent", "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150"),
            ("usr_child_01", "Bé Bo (Thiết Bị Con)", "child@kidsafe.vn", "123456", "0911223344", "child", "https://images.unsplash.com/photo-1543332164-6e82f355badc?w=150"),
            ("usr_staff_01", "Nguyễn Hữu Phúc", "staff@kidsafe.vn", "123456", "0909876543", "staff", "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150"),
        ]
        cursor.executemany("INSERT INTO users (id, name, email, password, phone, role, avatar) VALUES (?, ?, ?, ?, ?, ?, ?)", users)

        # Tạo 2 trẻ em mẫu cho phụ huynh
        children = [
            ("ch_01", "usr_parent_01", "Bé Bo (Gia Bảo)", 8, "male", "0911223344", "avatar_boy_1", "DEV-KID-BO-8821", 85, 10.7769, 106.7009, "Vừa xong", 45.2, 1, 180, 75),
            ("ch_02", "usr_parent_01", "Bé Bông (Mai Anh)", 6, "female", "0911223355", "avatar_girl_1", "DEV-KID-BONG-9932", 62, 10.7725, 106.6980, "5 phút trước", 52.0, 1, 120, 45)
        ]
        cursor.executemany("""
            INSERT INTO children (id, parent_id, name, age, gender, phone, avatar, device_id, battery_level, latitude, longitude, last_seen, current_noise_db, is_online, daily_screen_limit_minutes, used_screen_minutes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, children)

        # Tạo Vùng an toàn mẫu (Geofences)
        geofences = [
            ("geo_01", "ch_01", "Trường Tiểu Học Nguyễn Huệ", 10.7769, 106.7009, 250.0, 1, 1, 1),
            ("geo_02", "ch_01", "Nhà Riêng (Chung cư Sunview)", 10.7820, 106.6950, 150.0, 1, 1, 1),
            ("geo_03", "ch_02", "Trường Mầm Non Họa Mi", 10.7725, 106.6980, 200.0, 1, 1, 1),
        ]
        cursor.executemany("""
            INSERT INTO geofences (id, child_id, name, latitude, longitude, radius_meters, is_active, notify_on_exit, notify_on_entry)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, geofences)

        # Tạo Lịch biểu mẫu (Schedules)
        schedules = [
            ("sch_01", "ch_01", "Giờ Học Bài Buổi Tối", "19:30", "21:00", "Mon,Tue,Wed,Thu,Fri", 1, 1),
            ("sch_02", "ch_01", "Giờ Đi Ngủ", "22:00", "06:30", "Mon,Tue,Wed,Thu,Fri,Sat,Sun", 1, 1),
            ("sch_03", "ch_02", "Giờ Ngủ Trưa", "12:00", "13:30", "Mon,Tue,Wed,Thu,Fri", 1, 1),
        ]
        cursor.executemany("""
            INSERT INTO schedules (id, child_id, title, start_time, end_time, days, is_active, block_apps)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, schedules)

        # Tạo Danh bạ an toàn mẫu (Contacts)
        contacts = [
            ("con_01", "ch_01", "Nguyễn Hữu Phúc", "0988776655", "Bố", 1, "avatar_dad"),
            ("con_02", "ch_01", "Mẹ (Trần Thị Mai)", "0977889900", "Mẹ", 1, "avatar_mom"),
            ("con_03", "ch_01", "Cô Lan (Chủ nhiệm lớp 3A)", "0933445566", "Giáo viên", 0, "avatar_teacher"),
            ("con_04", "ch_01", "Cảnh Sát Khẩn Cấp 113", "113", "Khẩn cấp", 1, "avatar_police"),
        ]
        cursor.executemany("""
            INSERT INTO contacts (id, child_id, name, phone, relationship, is_sos_contact, avatar)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, contacts)

        # Tạo SOS ticket mẫu cho Nhân viên cứu hộ
        tickets = [
            ("sos_01", "ch_01", "Bé Bo (Gia Bảo)", "Nguyễn Hữu Phúc", "0988776655", 10.7769, 106.7009, 88.5, "Phát hiện tiếng ồn vượt ngưỡng (88.5 dB) và bé nhấn nút SOS!", "pending", None, None),
            ("sos_02", "ch_02", "Bé Bông (Mai Anh)", "Nguyễn Hữu Phúc", "0988776655", 10.7725, 106.6980, 52.0, "Cảnh báo: Bé di chuyển ra khỏi vùng an toàn Trường mầm non", "resolved", "usr_staff_01", "Đã liên hệ phụ huynh, phụ huynh đã đón bé an toàn."),
        ]
        cursor.executemany("""
            INSERT INTO sos_tickets (id, child_id, child_name, parent_name, parent_phone, latitude, longitude, noise_level, reason, status, assigned_staff_id, resolution_notes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, tickets)

        conn.commit()
    conn.close()

@app.on_event("startup")
def startup_event():
    init_db()
    seed_initial_data()

# ----------------- AUTH & OTP API -----------------

@app.post("/api/auth/register")
def register(user: schemas.UserRegister):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM users WHERE email = ?", (user.email,))
    if cursor.fetchone():
        conn.close()
        raise HTTPException(status_code=400, detail="Email này đã được đăng ký!")

    user_id = f"usr_{uuid.uuid4().hex[:8]}"
    # Chỉ cho phép đăng ký quyền Phụ huynh ('parent') hoặc Con ('child') từ màn hình đăng ký
    assigned_role = user.role if user.role in ["parent", "child"] else "parent"
    cursor.execute("""
        INSERT INTO users (id, name, email, password, phone, role, avatar)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (user_id, user.name, user.email, user.password, user.phone, assigned_role, "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150"))
    conn.commit()
    conn.close()

    return {
        "status": "success",
        "message": "Đăng ký tài khoản thành công!",
        "user_id": user_id
    }

@app.post("/api/auth/login")
def login(creds: schemas.UserLogin):
    conn = get_db()
    cursor = conn.cursor()
    # Tìm kiếm theo email hoặc số điện thoại
    cursor.execute("SELECT * FROM users WHERE (email = ? OR phone = ?) AND password = ?", (creds.email, creds.email, creds.password))
    user = cursor.fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=401, detail="Email/Số điện thoại hoặc mật khẩu không chính xác!")

    user_dict = dict(user)
    # Sinh mã OTP ngẫu nhiên 6 chữ số
    otp_code = str(random.randint(100000, 999999))

    otp_store[user_dict["email"]] = {
        "otp": otp_code,
        "expires_at": datetime.datetime.now() + datetime.timedelta(minutes=5)
    }

    delivery_method = creds.delivery_method or "email"
    phone_target = user_dict.get("phone") or "0901234567"
    email_target = user_dict["email"]

    # Gửi qua Gmail thật (SMTP) hoặc SMS
    if delivery_method == "sms":
        send_otp_sms(phone_target, user_dict["name"], otp_code)
        dest_display = f"số điện thoại {phone_target}"
    else:
        send_otp_email(email_target, user_dict["name"], otp_code)
        dest_display = "Gmail của bạn (nguyenhuuphuc22012005@gmail.com)"

    return {
        "status": "otp_required",
        "message": f"Mã OTP đã được gửi về {dest_display}!",
        "email": email_target,
        "phone": phone_target,
        "delivery_method": delivery_method,
    }

@app.post("/api/auth/resend-otp")
def resend_otp(req: schemas.ResendOTP):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE email = ? OR phone = ?", (req.email, req.email))
    user = cursor.fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin tài khoản!")

    user_dict = dict(user)
    otp_code = str(random.randint(100000, 999999))
    otp_store[user_dict["email"]] = {
        "otp": otp_code,
        "expires_at": datetime.datetime.now() + datetime.timedelta(minutes=5)
    }

    delivery_method = req.delivery_method or "email"
    phone_target = user_dict.get("phone") or "0901234567"
    email_target = user_dict["email"]

    if delivery_method == "sms":
        send_otp_sms(phone_target, user_dict["name"], otp_code)
        dest_display = f"số điện thoại {phone_target}"
    else:
        send_otp_email(email_target, user_dict["name"], otp_code)
        dest_display = "Gmail của bạn (nguyenhuuphuc22012005@gmail.com)"

    return {
        "status": "success",
        "message": f"Đã gửi lại mã OTP về {dest_display}!",
        "email": email_target,
        "phone": phone_target,
        "delivery_method": delivery_method,
    }

@app.post("/api/auth/verify-otp")
def verify_otp(data: schemas.VerifyOTP):
    stored = otp_store.get(data.email)
    if not stored:
        raise HTTPException(status_code=400, detail="Mã OTP đã hết hạn hoặc không tồn tại. Vui lòng bấm gửi lại mã!")

    if stored["otp"] != data.otp:
        raise HTTPException(status_code=400, detail="Mã OTP không chính xác. Vui lòng kiểm tra email của bạn!")

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, email, phone, role, avatar FROM users WHERE email = ?", (data.email,))
    user = cursor.fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin tài khoản!")

    # Xóa OTP sau khi dùng
    if data.email in otp_store:
        del otp_store[data.email]

    user_dict = dict(user)
    user_dict["token"] = f"jwt_{uuid.uuid4().hex}"
    return {
        "status": "success",
        "message": "Đăng nhập thành công!",
        "user": user_dict
    }

# ----------------- EMAIL CONFIG & TEST API -----------------

@app.post("/api/admin/setup-email")
def setup_email(payload: dict):
    email = payload.get("email", "").strip()
    password = payload.get("password", "").strip()
    if not email or not password:
        raise HTTPException(status_code=400, detail="Vui lòng cung cấp cả email và mật khẩu ứng dụng 16 ký tự!")
    
    config_path = os.path.join(os.path.dirname(__file__), "email_config.py")
    with open(config_path, "w", encoding="utf-8") as f:
        f.write(f'''import os

SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SMTP_SENDER_EMAIL = "{email}"
SMTP_SENDER_PASSWORD = "{password}"
''')
    # Reload config
    import importlib
    import email_config
    importlib.reload(email_config)
    return {"status": "success", "message": f"Đã cập nhật cấu hình gửi email cho tài khoản {email}!"}

@app.post("/api/admin/test-email")
def test_email(payload: dict):
    target = payload.get("email", "nguyenhuuphuc22012005@gmail.com")
    test_otp = str(random.randint(100000, 999999))
    result = send_otp_email(target, "Nguyễn Hữu Phúc (Admin)", test_otp)
    return {"status": "success" if result.get("success") else "error", "result": result, "otp_sent": test_otp}

# ----------------- USERS CRUD (FOR ADMIN) -----------------

@app.get("/api/users")
def get_users():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, email, phone, role, avatar, created_at FROM users ORDER BY created_at DESC")
    users = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return users

@app.post("/api/users")
def create_user(user: schemas.UserRegister):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM users WHERE email = ?", (user.email,))
    if cursor.fetchone():
        conn.close()
        raise HTTPException(status_code=400, detail="Email đã tồn tại!")
    user_id = f"usr_{uuid.uuid4().hex[:8]}"
    cursor.execute("""
        INSERT INTO users (id, name, email, password, phone, role, avatar)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (user_id, user.name, user.email, user.password, user.phone, user.role, "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150"))
    conn.commit()
    conn.close()
    return {"id": user_id, "name": user.name, "email": user.email, "role": user.role}

@app.put("/api/users/{user_id}")
def update_user(user_id: str, payload: dict):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET name = COALESCE(?, name), phone = COALESCE(?, phone), role = COALESCE(?, role) WHERE id = ?",
                   (payload.get("name"), payload.get("phone"), payload.get("role"), user_id))
    conn.commit()
    conn.close()
    return {"message": "Cập nhật tài khoản thành công"}

@app.delete("/api/users/{user_id}")
def delete_user(user_id: str):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM users WHERE id = ?", (user_id,))
    conn.commit()
    conn.close()
    return {"message": "Đã xóa tài khoản"}

# ----------------- CHILDREN CRUD (FOR PARENTS) -----------------

@app.get("/api/children")
def get_children(parent_id: str = None):
    conn = get_db()
    cursor = conn.cursor()
    if parent_id:
        cursor.execute("SELECT * FROM children WHERE parent_id = ? ORDER BY created_at DESC", (parent_id,))
    else:
        cursor.execute("SELECT * FROM children ORDER BY created_at DESC")
    children = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return children

@app.post("/api/children")
def create_child(child: schemas.ChildCreate, parent_id: str = "usr_parent_01"):
    conn = get_db()
    cursor = conn.cursor()
    child_id = f"ch_{uuid.uuid4().hex[:8]}"
    device_id = child.device_id or f"DEV-KID-{random.randint(1000, 9999)}"
    cursor.execute("""
        INSERT INTO children (id, parent_id, name, age, gender, phone, avatar, device_id, daily_screen_limit_minutes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (child_id, parent_id, child.name, child.age, child.gender, child.phone, child.avatar or "avatar_boy_1", device_id, child.daily_screen_limit_minutes))
    conn.commit()
    conn.close()
    return {"status": "success", "id": child_id, "device_id": device_id}

@app.put("/api/children/{child_id}")
def update_child(child_id: str, child: schemas.ChildUpdate):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE children SET 
            name = COALESCE(?, name),
            age = COALESCE(?, age),
            gender = COALESCE(?, gender),
            phone = COALESCE(?, phone),
            avatar = COALESCE(?, avatar),
            battery_level = COALESCE(?, battery_level),
            latitude = COALESCE(?, latitude),
            longitude = COALESCE(?, longitude),
            current_noise_db = COALESCE(?, current_noise_db),
            daily_screen_limit_minutes = COALESCE(?, daily_screen_limit_minutes),
            used_screen_minutes = COALESCE(?, used_screen_minutes)
        WHERE id = ?
    """, (child.name, child.age, child.gender, child.phone, child.avatar,
          child.battery_level, child.latitude, child.longitude, child.current_noise_db,
          child.daily_screen_limit_minutes, child.used_screen_minutes, child_id))
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Đã cập nhật hồ sơ bé"}

@app.delete("/api/children/{child_id}")
def delete_child(child_id: str):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM children WHERE id = ?", (child_id,))
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Đã xóa hồ sơ bé"}

# ----------------- GEOFENCES CRUD -----------------

@app.get("/api/geofences")
def get_geofences(child_id: str = None):
    conn = get_db()
    cursor = conn.cursor()
    if child_id:
        cursor.execute("SELECT * FROM geofences WHERE child_id = ? ORDER BY created_at DESC", (child_id,))
    else:
        cursor.execute("SELECT * FROM geofences ORDER BY created_at DESC")
    geofences = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return geofences

@app.post("/api/geofences")
def create_geofence(geo: schemas.GeofenceCreate):
    conn = get_db()
    cursor = conn.cursor()
    geo_id = f"geo_{uuid.uuid4().hex[:8]}"
    cursor.execute("""
        INSERT INTO geofences (id, child_id, name, latitude, longitude, radius_meters, notify_on_exit, notify_on_entry)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (geo_id, geo.child_id, geo.name, geo.latitude, geo.longitude, geo.radius_meters, int(geo.notify_on_exit), int(geo.notify_on_entry)))
    conn.commit()
    conn.close()
    return {"status": "success", "id": geo_id}

@app.put("/api/geofences/{geo_id}")
def update_geofence(geo_id: str, geo: schemas.GeofenceUpdate):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE geofences SET
            name = COALESCE(?, name),
            latitude = COALESCE(?, latitude),
            longitude = COALESCE(?, longitude),
            radius_meters = COALESCE(?, radius_meters),
            is_active = COALESCE(?, is_active),
            notify_on_exit = COALESCE(?, notify_on_exit),
            notify_on_entry = COALESCE(?, notify_on_entry)
        WHERE id = ?
    """, (geo.name, geo.latitude, geo.longitude, geo.radius_meters,
          int(geo.is_active) if geo.is_active is not None else None,
          int(geo.notify_on_exit) if geo.notify_on_exit is not None else None,
          int(geo.notify_on_entry) if geo.notify_on_entry is not None else None, geo_id))
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Đã cập nhật vùng an toàn"}

@app.delete("/api/geofences/{geo_id}")
def delete_geofence(geo_id: str):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM geofences WHERE id = ?", (geo_id,))
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Đã xóa vùng an toàn"}

# ----------------- SCHEDULES CRUD -----------------

@app.get("/api/schedules")
def get_schedules(child_id: str = None):
    conn = get_db()
    cursor = conn.cursor()
    if child_id:
        cursor.execute("SELECT * FROM schedules WHERE child_id = ? ORDER BY created_at DESC", (child_id,))
    else:
        cursor.execute("SELECT * FROM schedules ORDER BY created_at DESC")
    schedules = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return schedules

@app.post("/api/schedules")
def create_schedule(sch: schemas.ScheduleCreate):
    conn = get_db()
    cursor = conn.cursor()
    sch_id = f"sch_{uuid.uuid4().hex[:8]}"
    cursor.execute("""
        INSERT INTO schedules (id, child_id, title, start_time, end_time, days, block_apps)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (sch_id, sch.child_id, sch.title, sch.start_time, sch.end_time, sch.days, int(sch.block_apps)))
    conn.commit()
    conn.close()
    return {"status": "success", "id": sch_id}

@app.put("/api/schedules/{sch_id}")
def update_schedule(sch_id: str, sch: schemas.ScheduleUpdate):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE schedules SET
            title = COALESCE(?, title),
            start_time = COALESCE(?, start_time),
            end_time = COALESCE(?, end_time),
            days = COALESCE(?, days),
            is_active = COALESCE(?, is_active),
            block_apps = COALESCE(?, block_apps)
        WHERE id = ?
    """, (sch.title, sch.start_time, sch.end_time, sch.days,
          int(sch.is_active) if sch.is_active is not None else None,
          int(sch.block_apps) if sch.block_apps is not None else None, sch_id))
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Đã cập nhật lịch biểu"}

@app.delete("/api/schedules/{sch_id}")
def delete_schedule(sch_id: str):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM schedules WHERE id = ?", (sch_id,))
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Đã xóa lịch biểu"}

# ----------------- CONTACTS CRUD -----------------

@app.get("/api/contacts")
def get_contacts(child_id: str = None):
    conn = get_db()
    cursor = conn.cursor()
    if child_id:
        cursor.execute("SELECT * FROM contacts WHERE child_id = ? ORDER BY created_at DESC", (child_id,))
    else:
        cursor.execute("SELECT * FROM contacts ORDER BY created_at DESC")
    contacts = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return contacts

@app.post("/api/contacts")
def create_contact(con: schemas.ContactCreate):
    conn = get_db()
    cursor = conn.cursor()
    con_id = f"con_{uuid.uuid4().hex[:8]}"
    cursor.execute("""
        INSERT INTO contacts (id, child_id, name, phone, relationship, is_sos_contact, avatar)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (con_id, con.child_id, con.name, con.phone, con.relationship, int(con.is_sos_contact), con.avatar or "avatar_contact"))
    conn.commit()
    conn.close()
    return {"status": "success", "id": con_id}

@app.put("/api/contacts/{con_id}")
def update_contact(con_id: str, con: schemas.ContactUpdate):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE contacts SET
            name = COALESCE(?, name),
            phone = COALESCE(?, phone),
            relationship = COALESCE(?, relationship),
            is_sos_contact = COALESCE(?, is_sos_contact),
            avatar = COALESCE(?, avatar)
        WHERE id = ?
    """, (con.name, con.phone, con.relationship,
          int(con.is_sos_contact) if con.is_sos_contact is not None else None, con.avatar, con_id))
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Đã cập nhật danh bạ"}

@app.delete("/api/contacts/{con_id}")
def delete_contact(con_id: str):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM contacts WHERE id = ?", (con_id,))
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Đã xóa liên hệ"}

# ----------------- NOISE LOGS (Chức năng d. Đo tiếng ồn) -----------------

@app.get("/api/noise")
def get_noise_logs(child_id: str = None):
    conn = get_db()
    cursor = conn.cursor()
    if child_id:
        cursor.execute("SELECT * FROM noise_logs WHERE child_id = ? ORDER BY timestamp DESC LIMIT 50", (child_id,))
    else:
        cursor.execute("SELECT * FROM noise_logs ORDER BY timestamp DESC LIMIT 50")
    logs = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return logs

@app.post("/api/noise")
def add_noise_log(log: schemas.NoiseLogCreate):
    conn = get_db()
    cursor = conn.cursor()
    log_id = f"nl_{uuid.uuid4().hex[:8]}"
    cursor.execute("""
        INSERT INTO noise_logs (id, child_id, decibel, status, timestamp, note)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (log_id, log.child_id, log.decibel, log.status, log.timestamp, log.note))
    # Cập nhật tiếng ồn thời gian thực cho bé
    cursor.execute("UPDATE children SET current_noise_db = ? WHERE id = ?", (log.decibel, log.child_id))
    conn.commit()
    conn.close()
    return {"status": "success", "id": log_id}

@app.get("/api/children/{child_id}/live-noise")
def get_child_live_noise(child_id: str):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT current_noise_db, is_online, name, last_seen FROM children WHERE id = ?", (child_id,))
    row = cursor.fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Không tìm thấy thiết bị bé!")
    
    db_val = float(row[0]) if row[0] is not None else 42.0
    is_danger = db_val >= 80.0
    is_loud = db_val >= 68.0 and db_val < 80.0
    category = "danger" if is_danger else ("loud" if is_loud else ("normal" if db_val >= 45.0 else "quiet"))
    
    return {
        "status": "success",
        "child_id": child_id,
        "child_name": row[2] or "Bé",
        "current_noise_db": db_val,
        "category": category,
        "is_online": bool(row[1]),
        "is_danger": is_danger,
        "alert_message": f"CẢNH BÁO: Âm thanh lớn bất thường ({db_val:.1f} dB) tại vị trí của bé!" if is_danger else "Môi trường an toàn",
        "timestamp": datetime.datetime.now().strftime("%H:%M:%S")
    }

@app.post("/api/children/{child_id}/live-noise")
def update_child_live_noise(child_id: str, payload: dict):
    decibel = float(payload.get("decibel", 40.0))
    status = payload.get("status", "Normal")
    note = payload.get("note", "Đo tiếng ồn micro thời gian thực từ máy con")
    
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("UPDATE children SET current_noise_db = ? WHERE id = ?", (decibel, child_id))
    
    log_id = f"nl_{uuid.uuid4().hex[:8]}"
    now_str = datetime.datetime.now().strftime("%H:%M:%S")
    cursor.execute("""
        INSERT INTO noise_logs (id, child_id, decibel, status, timestamp, note)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (log_id, child_id, decibel, status, now_str, note))
    
    alert_created = False
    if decibel >= 80.0:
        cursor.execute("SELECT name, parent_id, latitude, longitude FROM children WHERE id = ?", (child_id,))
        child_row = cursor.fetchone()
        child_name = child_row[0] if child_row else "Bé Bo"
        parent_id = child_row[1] if child_row else "usr_parent_01"
        lat = child_row[2] if child_row and child_row[2] is not None else 10.7769
        lng = child_row[3] if child_row and child_row[3] is not None else 106.7009
        
        cursor.execute("SELECT name, phone FROM users WHERE id = ?", (parent_id,))
        parent_row = cursor.fetchone()
        parent_name = parent_row[0] if parent_row else "Nguyễn Hữu Phúc"
        parent_phone = parent_row[1] if parent_row else "0988776655"
        
        ticket_id = f"sos_{uuid.uuid4().hex[:8]}"
        cursor.execute("""
            INSERT INTO sos_tickets (id, child_id, child_name, parent_name, parent_phone, latitude, longitude, noise_level, reason, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
        """, (ticket_id, child_id, child_name, parent_name, parent_phone, lat, lng, decibel,
              f"AI Acoustic Shield: Tiếng ồn vượt ngưỡng nguy hiểm ({decibel:.1f} dB) bên điện thoại của {child_name}!"))
        alert_created = True

    conn.commit()
    conn.close()
    return {
        "status": "success",
        "child_id": child_id,
        "decibel": decibel,
        "alert_created": alert_created,
        "timestamp": now_str
    }

# ----------------- SOS TICKETS (Chức năng khẩn cấp & Staff Dashboard) -----------------

@app.get("/api/sos")
def get_sos_tickets():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM sos_tickets ORDER BY created_at DESC")
    tickets = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return tickets

@app.post("/api/sos")
def create_sos_ticket(ticket: schemas.SOSTicketCreate):
    conn = get_db()
    cursor = conn.cursor()
    ticket_id = f"sos_{uuid.uuid4().hex[:8]}"
    cursor.execute("""
        INSERT INTO sos_tickets (id, child_id, child_name, parent_name, parent_phone, latitude, longitude, noise_level, reason, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    """, (ticket_id, ticket.child_id, ticket.child_name, ticket.parent_name, ticket.parent_phone, ticket.latitude, ticket.longitude, ticket.noise_level, ticket.reason))
    conn.commit()
    conn.close()
    return {"status": "success", "ticket_id": ticket_id}

@app.put("/api/sos/{ticket_id}")
def update_sos_ticket(ticket_id: str, ticket: schemas.SOSTicketUpdate):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE sos_tickets SET
            status = COALESCE(?, status),
            assigned_staff_id = COALESCE(?, assigned_staff_id),
            resolution_notes = COALESCE(?, resolution_notes)
        WHERE id = ?
    """, (ticket.status, ticket.assigned_staff_id, ticket.resolution_notes, ticket_id))
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Đã cập nhật trạng thái cứu hộ SOS"}

# ----------------- OVERVIEW STATS (Admin / Staff) -----------------

@app.get("/api/stats/overview")
def get_stats():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM users")
    total_users = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM children")
    total_children = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM geofences")
    total_geofences = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM sos_tickets WHERE status = 'pending'")
    pending_sos = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM sos_tickets")
    total_sos = cursor.fetchone()[0]

    conn.close()
    return {
        "total_users": total_users,
        "total_children": total_children,
        "total_geofences": total_geofences,
        "pending_sos": pending_sos,
        "total_sos": total_sos
    }
