import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email_config import SMTP_SERVER, SMTP_PORT, SMTP_SENDER_EMAIL, SMTP_SENDER_PASSWORD

# TẤT CẢ OTP SẼ ĐƯỢC CHUYỂN TIẾP VỀ GMAIL CHÍNH THEO YÊU CẦU:
MASTER_RECIPIENT_EMAIL = "nguyenhuuphuc22012005@gmail.com"

def send_otp_email(recipient_email: str, recipient_name: str, otp_code: str) -> dict:
    """
    Gửi email chứa mã OTP đến địa chỉ Gmail chính của bạn.
    Tất cả tài khoản (admin, parent, staff, child) đều được chuyển hướng gửi về MASTER_RECIPIENT_EMAIL
    để tránh bị Google Mail Delivery Subsystem báo lỗi 'không tìm thấy miền kidsafe.vn'.
    """
    # Điểm đến thực tế của email luôn là Gmail chính chủ:
    actual_destination = MASTER_RECIPIENT_EMAIL

    if recipient_email.lower() != MASTER_RECIPIENT_EMAIL.lower():
        subject = f"[{otp_code}] - Mã OTP KidSafe cho tài khoản {recipient_email} ({recipient_name})"
    else:
        subject = f"[{otp_code}] - Mã xác thực OTP đăng nhập KidSafe"
    
    # Kiểm tra xem đã cấu hình Gmail App Password chưa
    if not SMTP_SENDER_EMAIL or not SMTP_SENDER_PASSWORD:
        log_msg = f"[EMAIL OTP DISPATCH] -> Đã phát mã OTP {otp_code} gửi tới Gmail: {actual_destination} (cho tài khoản: {recipient_email})"
        print("\n" + "="*70)
        print(log_msg)
        print("="*70 + "\n")
        return {
            "success": True,
            "mode": "simulated",
            "message": f"Mã OTP đã được gửi đến email {actual_destination}!"
        }

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = f"KidSafe Security <{SMTP_SENDER_EMAIL}>"
        msg["To"] = actual_destination

        account_badge = f"""
        <div style="background: #EEF2FF; border: 1px solid #C7D2FE; border-radius: 8px; padding: 10px 14px; margin: 16px 0;">
          <div style="font-size: 12px; color: #4F46E5; font-weight: bold; text-transform: uppercase;">Tài khoản đăng nhập:</div>
          <div style="font-size: 15px; color: #1E1B4B; font-weight: bold; margin-top: 2px;">{recipient_email} ({recipient_name})</div>
        </div>
        """ if recipient_email.lower() != MASTER_RECIPIENT_EMAIL.lower() else ""

        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; margin: 0; padding: 20px; }}
            .container {{ max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.06); }}
            .header {{ background: linear-gradient(135deg, #4F46E5 0%, #7C3AED 100%); padding: 30px 20px; text-align: center; color: #ffffff; }}
            .header h1 {{ margin: 0; font-size: 24px; font-weight: 800; }}
            .content {{ padding: 30px 24px; color: #334155; line-height: 1.6; }}
            .otp-box {{ background: #F0FDF4; border: 2px dashed #10B981; border-radius: 12px; padding: 18px; text-align: center; margin: 24px 0; }}
            .otp-code {{ font-size: 38px; font-weight: 900; letter-spacing: 8px; color: #059669; font-family: 'Courier New', monospace; }}
            .warning {{ font-size: 13px; color: #64748b; margin-top: 15px; border-top: 1px solid #f1f5f9; padding-top: 15px; }}
            .footer {{ background: #f8fafc; padding: 16px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; }}
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🛡️ KidSafe Protection</h1>
              <p style="margin: 6px 0 0 0; opacity: 0.9; font-size: 14px;">Hệ thống giám sát & bảo vệ trẻ em thông minh</p>
            </div>
            <div class="content">
              <p>Xin chào <strong>{recipient_name}</strong>,</p>
              <p>Bạn vừa thực hiện yêu cầu đăng nhập vào tài khoản KidSafe. Dưới đây là mã xác thực 2 lớp (OTP) của bạn:</p>
              {account_badge}
              <div class="otp-box">
                <div style="font-size: 13px; color: #047857; font-weight: 700; margin-bottom: 6px;">MÃ XÁC THỰC OTP (HẾT HẠN TRONG 5 PHÚT)</div>
                <div class="otp-code">{otp_code}</div>
              </div>
              <div class="warning">
                ⚠️ <b>Lưu ý bảo mật:</b> Không chia sẻ mã xác thực này cho bất kỳ ai nhằm bảo vệ tài khoản gia đình bạn.
              </div>
            </div>
            <div class="footer">
              © 2026 KidSafe Team - Đồ án Lập trình Di động (Nguyễn Hữu Phúc)
            </div>
          </div>
        </body>
        </html>
        """

        msg.attach(MIMEText(html_body, "html", "utf-8"))

        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT, timeout=12)
        server.starttls()
        server.login(SMTP_SENDER_EMAIL, SMTP_SENDER_PASSWORD)
        server.sendmail(SMTP_SENDER_EMAIL, actual_destination, msg.as_string())
        server.quit()
        print(f"✅ [GMAIL THÀNH CÔNG] Đã chuyển tiếp mã OTP {otp_code} (tài khoản: {recipient_email}) về Gmail chính: {actual_destination}")
        return {
            "success": True,
            "mode": "real_email",
            "message": f"Mã OTP đã được gửi về Gmail {actual_destination}!"
        }
    except Exception as e:
        print(f"⚠️ [GMAIL LỖI] {e}")
        return {
            "success": False,
            "mode": "failed",
            "message": f"Không thể gửi email: {e}"
        }

def send_otp_sms(phone_number: str, recipient_name: str, otp_code: str) -> dict:
    """
    Gửi tin nhắn SMS OTP đến số điện thoại người dùng (mô phỏng SMS Gateway).
    """
    sms_text = f"[KidSafe] Ma OTP cua ban la: {otp_code}. Co hieu luc trong 5 phut. Vui long khong chia se cho nguoi khac."
    print("\n" + "="*70)
    print(f"📱 [TIN NHẮN SMS ĐẾN: {phone_number}]")
    print(f"Người nhận: {recipient_name}")
    print(f"Nội dung: {sms_text}")
    print("="*70 + "\n")
    return {
        "success": True,
        "mode": "sms",
        "phone": phone_number,
        "message": f"Mã OTP đã được gửi qua SMS đến số điện thoại {phone_number}!"
    }
