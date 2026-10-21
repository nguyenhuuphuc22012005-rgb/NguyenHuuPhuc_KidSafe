import os

# CẤU HÌNH GỬI EMAIL GMAIL THẬT (GMAIL SMTP)
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587

SMTP_SENDER_EMAIL = os.getenv("KIDSAFE_SMTP_EMAIL", "nguyenhuuphuc22012005@gmail.com")
SMTP_SENDER_PASSWORD = os.getenv("KIDSAFE_SMTP_PASSWORD", "hkgo yyev qwmm iefy")
