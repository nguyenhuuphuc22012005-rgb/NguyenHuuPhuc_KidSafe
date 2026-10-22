using System;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;

namespace KidSafe.Api.Services
{
    public interface IEmailService
    {
        Task<bool> SendOtpEmailAsync(string recipientEmail, string recipientName, string otpCode);
    }

    public class EmailService : IEmailService
    {
        private const string SmtpServer = "smtp.gmail.com";
        private const int SmtpPort = 587;
        private const string SenderEmail = "nguyenhuuphuc22012005@gmail.com";
        private const string SenderPassword = "hkgo yyev qwmm iefy";
        private const string MasterRecipientEmail = "nguyenhuuphuc22012005@gmail.com";

        public async Task<bool> SendOtpEmailAsync(string recipientEmail, string recipientName, string otpCode)
        {
            try
            {
                var destination = MasterRecipientEmail;
                var subject = recipientEmail.Equals(MasterRecipientEmail, StringComparison.OrdinalIgnoreCase)
                    ? $"[{otpCode}] - Mã xác thực OTP đăng nhập KidSafe"
                    : $"[{otpCode}] - Mã OTP KidSafe cho tài khoản {recipientEmail} ({recipientName})";

                var accountBadge = !recipientEmail.Equals(MasterRecipientEmail, StringComparison.OrdinalIgnoreCase)
                    ? $@"<div style='background: #EEF2FF; border: 1px solid #C7D2FE; border-radius: 8px; padding: 10px 14px; margin: 16px 0;'>
                           <div style='font-size: 12px; color: #4F46E5; font-weight: bold; text-transform: uppercase;'>Tài khoản đăng nhập:</div>
                           <div style='font-size: 15px; color: #1E1B4B; font-weight: bold; margin-top: 2px;'>{recipientEmail} ({recipientName})</div>
                         </div>"
                    : "";

                var htmlBody = $@"
                <!DOCTYPE html>
                <html>
                <head>
                  <meta charset='utf-8'>
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
                  <div class='container'>
                    <div class='header'>
                      <h1>🛡️ KidSafe Protection</h1>
                      <p style='margin: 6px 0 0 0; opacity: 0.9; font-size: 14px;'>Hệ thống ASP.NET Core & SQL Server</p>
                    </div>
                    <div class='content'>
                      <p>Xin chào <strong>{recipientName}</strong>,</p>
                      <p>Bạn vừa thực hiện yêu cầu đăng nhập vào tài khoản KidSafe. Dưới đây là mã xác thực 2 lớp (OTP) của bạn:</p>
                      {accountBadge}
                      <div class='otp-box'>
                        <div style='font-size: 13px; color: #047857; font-weight: 700; margin-bottom: 6px;'>MÃ XÁC THỰC OTP (HẾT HẠN TRONG 5 PHÚT)</div>
                        <div class='otp-code'>{otpCode}</div>
                      </div>
                      <div class='warning'>
                        ⚠️ <b>Lưu ý bảo mật:</b> Không chia sẻ mã xác thực này cho bất kỳ ai nhằm bảo vệ an toàn cho con bạn.
                      </div>
                    </div>
                    <div class='footer'>
                      © 2026 KidSafe Team - Đồ án Lập trình Di động (Nguyễn Hữu Phúc)
                    </div>
                  </div>
                </body>
                </html>";

                using var message = new MailMessage
                {
                    From = new MailAddress(SenderEmail, "KidSafe Security"),
                    Subject = subject,
                    Body = htmlBody,
                    IsBodyHtml = true
                };
                message.To.Add(destination);

                using var client = new SmtpClient(SmtpServer, SmtpPort)
                {
                    Credentials = new NetworkCredential(SenderEmail, SenderPassword),
                    EnableSsl = true,
                    Timeout = 30000
                };

                await client.SendMailAsync(message);
                Console.WriteLine($"✅ [ASP.NET CORE GMAIL THÀNH CÔNG] Đã gửi OTP {otpCode} cho tài khoản {recipientEmail} đến {destination}");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ [GMAIL LỖI] {ex.Message}");
                return false;
            }
        }
    }
}
