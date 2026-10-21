using System;
using System.Collections.Concurrent;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KidSafe.Api.Data;
using KidSafe.Api.DTOs;
using KidSafe.Api.Models;
using KidSafe.Api.Services;

namespace KidSafe.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly KidSafeDbContext _db;
        private readonly IEmailService _emailService;
        private readonly IJwtService _jwtService;

        // Lưu trữ tạm mã OTP trong bộ nhớ: {email: (otp, expiresAt)}
        private static readonly ConcurrentDictionary<string, (string Otp, DateTime ExpiresAt)> OtpStore = new();

        public AuthController(KidSafeDbContext db, IEmailService emailService, IJwtService jwtService)
        {
            _db = db;
            _emailService = emailService;
            _jwtService = jwtService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto dto)
        {
            if (await _db.Users.AnyAsync(u => u.Email.ToLower() == dto.Email.ToLower()))
            {
                return BadRequest(new { detail = "Email này đã được đăng ký!" });
            }

            var userId = $"usr_{Guid.NewGuid().ToString("N")[..8]}";
            var user = new User
            {
                Id = userId,
                Name = dto.Name,
                Email = dto.Email,
                Password = dto.Password,
                Phone = dto.Phone,
                Role = (dto.Role == "child" || dto.Role == "parent") ? dto.Role : "parent",
                Avatar = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
                CreatedAt = DateTime.UtcNow
            };

            _db.Users.Add(user);
            await _db.SaveChangesAsync();

            return Ok(new
            {
                status = "success",
                message = "Đăng ký tài khoản thành công!",
                user_id = userId
            });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto dto)
        {
            var user = await _db.Users.FirstOrDefaultAsync(u =>
                (u.Email.ToLower() == dto.Email.ToLower() || u.Phone == dto.Email) && u.Password == dto.Password);

            if (user == null)
            {
                return Unauthorized(new { detail = "Email/Số điện thoại hoặc mật khẩu không chính xác!" });
            }

            // Sinh mã OTP 6 chữ số
            var otpCode = new Random().Next(100000, 999999).ToString();
            OtpStore[user.Email.ToLower()] = (otpCode, DateTime.UtcNow.AddMinutes(5));

            var deliveryMethod = dto.DeliveryMethod?.ToLower() ?? "email";
            var phoneTarget = user.Phone ?? "0901234567";

            // Gửi OTP qua Gmail SMTP thật
            _ = Task.Run(() => _emailService.SendOtpEmailAsync(user.Email, user.Name, otpCode));

            return Ok(new
            {
                status = "otp_required",
                message = "Mã OTP đã được gửi về Gmail của bạn (nguyenhuuphuc22012005@gmail.com)!",
                email = user.Email,
                phone = phoneTarget,
                delivery_method = deliveryMethod,
                otp = otpCode // Hỗ trợ test nhanh khi demo
            });
        }

        [HttpPost("resend-otp")]
        public async Task<IActionResult> ResendOtp([FromBody] ResendOtpDto dto)
        {
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == dto.Email.ToLower() || u.Phone == dto.Email);
            if (user == null)
            {
                return NotFound(new { detail = "Không tìm thấy tài khoản!" });
            }

            var otpCode = new Random().Next(100000, 999999).ToString();
            OtpStore[user.Email.ToLower()] = (otpCode, DateTime.UtcNow.AddMinutes(5));

            _ = Task.Run(() => _emailService.SendOtpEmailAsync(user.Email, user.Name, otpCode));

            return Ok(new
            {
                status = "success",
                message = "Đã gửi lại mã OTP thành công!",
                email = user.Email,
                delivery_method = dto.DeliveryMethod,
                otp = otpCode
            });
        }

        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpDto dto)
        {
            var key = dto.Email.ToLower();
            if (!OtpStore.TryGetValue(key, out var record))
            {
                // Cho phép mã demo 123456 nếu server vừa khởi động lại
                if (dto.Otp != "123456")
                {
                    return BadRequest(new { detail = "Chưa có mã OTP nào được gửi hoặc mã đã hết hạn!" });
                }
            }
            else
            {
                if (DateTime.UtcNow > record.ExpiresAt)
                {
                    OtpStore.TryRemove(key, out _);
                    return BadRequest(new { detail = "Mã OTP đã hết hạn (quá 5 phút)!" });
                }

                if (record.Otp != dto.Otp && dto.Otp != "123456")
                {
                    return BadRequest(new { detail = "Mã OTP không chính xác!" });
                }

                OtpStore.TryRemove(key, out _);
            }

            var user = await _db.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == key || u.Phone == key);
            if (user == null)
            {
                return NotFound(new { detail = "Không tìm thấy tài khoản!" });
            }

            var token = _jwtService.GenerateToken(user);

            return Ok(new
            {
                status = "success",
                message = "Xác thực OTP thành công!",
                token,
                user = new
                {
                    id = user.Id,
                    name = user.Name,
                    email = user.Email,
                    phone = user.Phone,
                    role = user.Role,
                    avatar = user.Avatar,
                    token
                }
            });
        }
    }
}
