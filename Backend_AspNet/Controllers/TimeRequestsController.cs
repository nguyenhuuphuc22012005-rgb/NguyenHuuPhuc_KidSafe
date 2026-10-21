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
    [Route("api/time-requests")]
    public class TimeRequestsController : ControllerBase
    {
        private readonly KidSafeDbContext _db;

        public TimeRequestsController(KidSafeDbContext db)
        {
            _db = db;
        }

        /// <summary>
        /// Lấy danh sách yêu cầu xin thêm thời gian
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetRequests([FromQuery] string? child_id, [FromQuery] string? parent_id)
        {
            var query = _db.TimeExtensionRequests.AsQueryable();

            if (!string.IsNullOrEmpty(child_id))
            {
                query = query.Where(r => r.ChildId == child_id);
            }

            if (!string.IsNullOrEmpty(parent_id))
            {
                var childIds = await _db.Children
                    .Where(c => c.ParentId == parent_id)
                    .Select(c => c.Id)
                    .ToListAsync();
                query = query.Where(r => childIds.Contains(r.ChildId));
            }

            var list = await query
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return Ok(list);
        }

        /// <summary>
        /// App Trẻ Em: Gửi yêu cầu xin thêm thời gian sử dụng điện thoại
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateRequest([FromBody] CreateTimeRequestDto dto)
        {
            var child = await _db.Children.FindAsync(dto.ChildId);
            if (child == null) return NotFound(new { detail = "Không tìm thấy hồ sơ trẻ em!" });

            var req = new TimeExtensionRequest
            {
                Id = $"req_{Guid.NewGuid().ToString("N")[..8]}",
                ChildId = dto.ChildId,
                ChildName = child.Name,
                MinutesRequested = dto.MinutesRequested,
                Reason = dto.Reason,
                Status = "pending",
                CreatedAt = DateTime.UtcNow
            };

            _db.TimeExtensionRequests.Add(req);
            await _db.SaveChangesAsync();

            return Ok(new
            {
                status = "success",
                message = "Đã gửi yêu cầu xin thêm thời gian đến Phụ huynh thành công!",
                request = req
            });
        }

        /// <summary>
        /// App Phụ Huynh: Duyệt yêu cầu xin thêm thời gian (Chấp nhận hoặc Từ chối)
        /// </summary>
        [HttpPut("{id}/review")]
        public async Task<IActionResult> ReviewRequest(string id, [FromBody] ReviewTimeRequestDto dto)
        {
            var req = await _db.TimeExtensionRequests.FindAsync(id);
            if (req == null) return NotFound(new { detail = "Không tìm thấy yêu cầu!" });

            var normalizedStatus = dto.Status.ToLower();
            if (normalizedStatus != "approved" && normalizedStatus != "rejected")
            {
                return BadRequest(new { detail = "Trạng thái chỉ có thể là 'approved' hoặc 'rejected'!" });
            }

            req.Status = normalizedStatus;
            req.ReviewedAt = DateTime.UtcNow;
            req.ReviewedBy = dto.ReviewedBy ?? "Phụ Huynh";

            // Nếu Phụ huynh duyệt đồng ý (Approved) -> Tự động cộng thêm số phút vào hạn mức của bé
            if (normalizedStatus == "approved")
            {
                var child = await _db.Children.FindAsync(req.ChildId);
                if (child != null)
                {
                    child.DailyScreenLimitMinutes += req.MinutesRequested;
                }
            }

            await _db.SaveChangesAsync();

            return Ok(new
            {
                status = "success",
                message = normalizedStatus == "approved"
                    ? $"Đã đồng ý cộng thêm {req.MinutesRequested} phút cho {req.ChildName}!"
                    : $"Đã từ chối yêu cầu xin thêm giờ của {req.ChildName}!",
                request = req
            });
        }
    }
}
