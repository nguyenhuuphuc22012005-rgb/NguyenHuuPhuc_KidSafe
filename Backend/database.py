import sqlite3
import os

BACKEND_DIR = os.path.dirname(__file__)
KIDSAFE_DB = os.path.join(BACKEND_DIR, "kidsafe.db")
DB_DIR = os.path.abspath(os.path.join(BACKEND_DIR, "..", "Database"))
os.makedirs(DB_DIR, exist_ok=True)
DB_PATH = KIDSAFE_DB if os.path.exists(KIDSAFE_DB) else os.path.join(DB_DIR, "NguyenHuuPhuc.db")

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    cursor = conn.cursor()
    
    # Bảng người dùng (Users)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        phone TEXT,
        role TEXT NOT NULL, -- admin, staff, parent, child
        avatar TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # Bảng Trẻ em (Children)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS children (
        id TEXT PRIMARY KEY,
        parent_id TEXT NOT NULL,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT DEFAULT 'male',
        phone TEXT,
        avatar TEXT,
        device_id TEXT UNIQUE,
        battery_level INTEGER DEFAULT 85,
        latitude REAL DEFAULT 10.7769,
        longitude REAL DEFAULT 106.7009,
        last_seen TEXT,
        current_noise_db REAL DEFAULT 42.0,
        is_online INTEGER DEFAULT 1,
        daily_screen_limit_minutes INTEGER DEFAULT 180,
        used_screen_minutes INTEGER DEFAULT 65,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE CASCADE
    );
    """)

    # Bảng Vùng an toàn (Geofences)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS geofences (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius_meters REAL NOT NULL,
        is_active INTEGER DEFAULT 1,
        notify_on_exit INTEGER DEFAULT 1,
        notify_on_entry INTEGER DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (child_id) REFERENCES children(id) ON DELETE CASCADE
    );
    """)

    # Bảng Lịch biểu sử dụng (Schedules)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS schedules (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        title TEXT NOT NULL,
        start_time TEXT NOT NULL, -- HH:mm
        end_time TEXT NOT NULL,   -- HH:mm
        days TEXT NOT NULL,       -- "Mon,Tue,Wed,Thu,Fri"
        is_active INTEGER DEFAULT 1,
        block_apps INTEGER DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (child_id) REFERENCES children(id) ON DELETE CASCADE
    );
    """)

    # Bảng Danh bạ an toàn (Safe Contacts)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS contacts (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        relationship TEXT NOT NULL,
        is_sos_contact INTEGER DEFAULT 0,
        avatar TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (child_id) REFERENCES children(id) ON DELETE CASCADE
    );
    """)

    # Bảng Nhật ký đo tiếng ồn (Noise Logs)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS noise_logs (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        decibel REAL NOT NULL,
        status TEXT NOT NULL, -- Quiet, Normal, Loud, Danger
        timestamp TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (child_id) REFERENCES children(id) ON DELETE CASCADE
    );
    """)

    # Bảng Cảnh báo khẩn cấp SOS (SOS Tickets)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS sos_tickets (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        child_name TEXT NOT NULL,
        parent_name TEXT,
        parent_phone TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        noise_level REAL DEFAULT 0.0,
        reason TEXT NOT NULL,
        status TEXT DEFAULT 'pending', -- pending, in_progress, resolved
        assigned_staff_id TEXT,
        resolution_notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    conn.commit()
    conn.close()
