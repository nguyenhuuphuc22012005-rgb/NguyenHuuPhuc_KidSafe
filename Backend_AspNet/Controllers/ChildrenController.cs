using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KidSafe.Api.Data;
using KidSafe.Api.DTOs;
using KidSafe.Api.Models;

namespace KidSafe.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ChildrenController : ControllerBase
    {
        private readonly KidSafeDbContext _db;

        public ChildrenController(KidSafeDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> GetChildren([FromQuery] string? parent_id)
        {
            var query = _db.Children.AsQueryable();
            if (!string.IsNullOrEmpty(parent_id))
            {
                query = query.Where(c => c.ParentId == parent_id);
            }

            var list = await query.ToListAsync();
            return Ok(list);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetChild(string id)
        {
            var child = await _db.Children.FindAsync(id);
            if (child == null) return NotFound(new { detail = "Không tìm thấy hồ sơ trẻ em!" });
            return Ok(child);
        }

        [HttpPost]
        public async Task<IActionResult> CreateChild([FromBody] ChildCreateDto dto, [FromQuery] string parent_id = "usr_parent_01")
        {
            var childId = $"ch_{Guid.NewGuid().ToString("N")[..8]}";
            var deviceId = string.IsNullOrWhiteSpace(dto.DeviceId)
                ? $"DEV-KID-{new Random().Next(1000, 9999)}"
                : dto.DeviceId;

            var child = new Child
            {
                Id = childId,
                ParentId = parent_id,
                Name = dto.Name,
                Age = dto.Age,
                Gender = dto.Gender,
                Phone = dto.Phone,
                Avatar = dto.Avatar ?? "avatar_boy_1",
                DeviceId = deviceId,
                DailyScreenLimitMinutes = dto.DailyScreenLimitMinutes,
                UsedScreenMinutes = 0,
                BatteryLevel = 85,
                Latitude = 10.7769,
                Longitude = 106.7009,
                LastSeen = "Vừa xong",
                IsOnline = true,
                CreatedAt = DateTime.UtcNow
            };

            _db.Children.Add(child);
            await _db.SaveChangesAsync();

            return Ok(new
            {
                status = "success",
                id = childId,
                device_id = deviceId,
                child
            });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateChild(string id, [FromBody] ChildUpdateDto dto)
        {
            var child = await _db.Children.FindAsync(id);
            if (child == null) return NotFound(new { detail = "Không tìm thấy hồ sơ trẻ em!" });

            if (!string.IsNullOrWhiteSpace(dto.Name)) child.Name = dto.Name;
            if (dto.Age.HasValue) child.Age = dto.Age.Value;
            if (!string.IsNullOrWhiteSpace(dto.Gender)) child.Gender = dto.Gender;
            if (dto.Phone != null) child.Phone = dto.Phone;
            if (!string.IsNullOrWhiteSpace(dto.Avatar)) child.Avatar = dto.Avatar;
            if (dto.BatteryLevel.HasValue) child.BatteryLevel = dto.BatteryLevel.Value;
            if (dto.Latitude.HasValue) child.Latitude = dto.Latitude.Value;
            if (dto.Longitude.HasValue) child.Longitude = dto.Longitude.Value;
            if (dto.CurrentNoiseDb.HasValue) child.CurrentNoiseDb = dto.CurrentNoiseDb.Value;
            if (dto.DailyScreenLimitMinutes.HasValue) child.DailyScreenLimitMinutes = dto.DailyScreenLimitMinutes.Value;
            if (dto.UsedScreenMinutes.HasValue) child.UsedScreenMinutes = dto.UsedScreenMinutes.Value;

            child.LastSeen = "Vừa xong";
            await _db.SaveChangesAsync();

            return Ok(new { status = "success", message = "Đã cập nhật hồ sơ bé", child });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteChild(string id)
        {
            var child = await _db.Children.FindAsync(id);
            if (child == null) return NotFound(new { detail = "Không tìm thấy hồ sơ trẻ em!" });

            _db.Children.Remove(child);
            await _db.SaveChangesAsync();

            return Ok(new { status = "success", message = "Đã xóa hồ sơ bé" });
        }

        // ==================== CÁC TÍNH NĂNG THEO SƠ ĐỒ ĐỀ BÀI ====================

        /// <summary>
        /// Ghép nối thiết bị qua quét mã QR (Gửi mã QR đến Web API để xác minh và ghép nối)
        /// </summary>
        [HttpPost("pair")]
        public async Task<IActionResult> PairDevice([FromBody] PairDeviceDto dto)
        {
            // Kiểm tra xem thiết bị này đã tồn tại trong CSDL chưa
            var existingChild = await _db.Children.FirstOrDefaultAsync(c => c.DeviceId == dto.DeviceId);
            if (existingChild != null)
            {
                // Cập nhật gán thiết bị này về phụ huynh hiện tại
                existingChild.ParentId = dto.ParentId;
                existingChild.LastSeen = "Vừa xong";
                if (!string.IsNullOrWhiteSpace(dto.Name)) existingChild.Name = dto.Name;
                await _db.SaveChangesAsync();

                return Ok(new
                {
                    status = "success",
                    message = "Đã xác minh mã QR và ghép nối thiết bị thành công!",
                    child = existingChild
                });
            }

            // Nếu thiết bị mới hoàn toàn thì tạo hồ sơ mới cho phụ huynh
            var newChildId = $"ch_{Guid.NewGuid().ToString("N")[..8]}";
            var newChild = new Child
            {
                Id = newChildId,
                ParentId = dto.ParentId,
                Name = !string.IsNullOrWhiteSpace(dto.Name) ? dto.Name : $"Thiết bị trẻ em ({dto.DeviceId})",
                Age = 7,
                Avatar = "avatar_boy_1",
                DeviceId = dto.DeviceId,
                BatteryLevel = 90,
                Latitude = 10.7769,
                Longitude = 106.7009,
                LastSeen = "Vừa xong",
                DailyScreenLimitMinutes = 180,
                UsedScreenMinutes = 0,
                IsOnline = true,
                CreatedAt = DateTime.UtcNow
            };

            _db.Children.Add(newChild);
            await _db.SaveChangesAsync();

            return Ok(new
            {
                status = "success",
                message = "Đã ghép nối thiết bị mới vào tài khoản phụ huynh thành công!",
                child = newChild
            });
        }

        /// <summary>
        /// Gửi tọa độ GPS từ máy con về Web API và lưu vào SQL Server
        /// </summary>
        [HttpPost("{id}/location")]
        public async Task<IActionResult> UpdateLocation(string id, [FromBody] UpdateLocationDto dto)
        {
            var child = await _db.Children.FindAsync(id);
            if (child == null) return NotFound(new { detail = "Không tìm thấy thiết bị trẻ em!" });

            child.Latitude = dto.Latitude;
            child.Longitude = dto.Longitude;
            if (dto.BatteryLevel.HasValue) child.BatteryLevel = dto.BatteryLevel.Value;
            child.LastSeen = "Vừa xong";
            child.IsOnline = true;

            await _db.SaveChangesAsync();

            return Ok(new
            {
                status = "success",
                message = "Đã cập nhật vị trí GPS vào SQL Server",
                latitude = child.Latitude,
                longitude = child.Longitude
            });
        }

        /// <summary>
        /// Thu nhận mức độ tiếng ồn thời gian thực từ Micro máy con
        /// </summary>
        [HttpPost("{id}/live-noise")]
        public async Task<IActionResult> ReportLiveNoise(string id, [FromBody] LiveNoiseDto dto)
        {
            var child = await _db.Children.FindAsync(id);
            if (child == null) return NotFound(new { detail = "Không tìm thấy thiết bị trẻ em!" });

            child.CurrentNoiseDb = dto.Decibel;
            child.LastSeen = "Vừa xong";

            // Nếu mức ồn vượt ngưỡng nguy hiểm (>80 dB), lưu vào bảng nhật ký NoiseLogs
            if (dto.Decibel >= 75.0)
            {
                var log = new NoiseLog
                {
                    Id = $"nl_{Guid.NewGuid().ToString("N")[..8]}",
                    ChildId = id,
                    Decibel = dto.Decibel,
                    Status = dto.Status,
                    Timestamp = DateTime.Now.ToString("HH:mm dd/MM"),
                    Note = dto.Note
                };
                _db.NoiseLogs.Add(log);
            }

            await _db.SaveChangesAsync();

            return Ok(new
            {
                status = "success",
                decibel = dto.Decibel,
                message = "Đã cập nhật mức âm thanh môi trường vào SQL Server"
            });
        }

        [HttpGet("{id}/live-noise")]
        public async Task<IActionResult> GetLiveNoise(string id)
        {
            var child = await _db.Children.FindAsync(id);
            if (child == null) return NotFound(new { detail = "Không tìm thấy thiết bị trẻ em!" });

            return Ok(new
            {
                child_id = child.Id,
                name = child.Name,
                decibel = child.CurrentNoiseDb,
                last_seen = child.LastSeen
            });
        }
    }
}
