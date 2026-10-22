using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KidSafe.Api.Data;
using KidSafe.Api.Models;

namespace KidSafe.Api.Controllers
{
    // ==================== 1. GEOFENCES CRUD ====================
    [ApiController]
    [Route("api/[controller]")]
    public class GeofencesController : ControllerBase
    {
        private readonly NguyenHuuPhucDbContext _db;
        public GeofencesController(NguyenHuuPhucDbContext db) => _db = db;

        [HttpGet]
        public async Task<IActionResult> GetGeofences([FromQuery] string? child_id)
        {
            var query = _db.Geofences.AsQueryable();
            if (!string.IsNullOrEmpty(child_id)) query = query.Where(g => g.ChildId == child_id);
            return Ok(await query.ToListAsync());
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Geofence geo)
        {
            if (string.IsNullOrWhiteSpace(geo.Id)) geo.Id = $"geo_{Guid.NewGuid().ToString("N")[..8]}";
            geo.CreatedAt = DateTime.UtcNow;
            _db.Geofences.Add(geo);
            await _db.SaveChangesAsync();
            return Ok(geo);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, [FromBody] Geofence geo)
        {
            var existing = await _db.Geofences.FindAsync(id);
            if (existing == null) return NotFound();

            existing.Name = geo.Name;
            existing.Latitude = geo.Latitude;
            existing.Longitude = geo.Longitude;
            existing.RadiusMeters = geo.RadiusMeters;
            existing.IsActive = geo.IsActive;
            existing.NotifyOnExit = geo.NotifyOnExit;
            existing.NotifyOnEntry = geo.NotifyOnEntry;

            await _db.SaveChangesAsync();
            return Ok(existing);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            var existing = await _db.Geofences.FindAsync(id);
            if (existing == null) return NotFound();
            _db.Geofences.Remove(existing);
            await _db.SaveChangesAsync();
            return Ok(new { status = "success" });
        }
    }

    // ==================== 2. SCHEDULES CRUD ====================
    [ApiController]
    [Route("api/[controller]")]
    public class SchedulesController : ControllerBase
    {
        private readonly NguyenHuuPhucDbContext _db;
        public SchedulesController(NguyenHuuPhucDbContext db) => _db = db;

        [HttpGet]
        public async Task<IActionResult> GetSchedules([FromQuery] string? child_id)
        {
            var query = _db.Schedules.AsQueryable();
            if (!string.IsNullOrEmpty(child_id)) query = query.Where(s => s.ChildId == child_id);
            return Ok(await query.ToListAsync());
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Schedule sch)
        {
            if (string.IsNullOrWhiteSpace(sch.Id)) sch.Id = $"sch_{Guid.NewGuid().ToString("N")[..8]}";
            sch.CreatedAt = DateTime.UtcNow;
            _db.Schedules.Add(sch);
            await _db.SaveChangesAsync();
            return Ok(sch);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, [FromBody] Schedule sch)
        {
            var existing = await _db.Schedules.FindAsync(id);
            if (existing == null) return NotFound();

            existing.Title = sch.Title;
            existing.StartTime = sch.StartTime;
            existing.EndTime = sch.EndTime;
            existing.Days = sch.Days;
            existing.IsActive = sch.IsActive;
            existing.BlockApps = sch.BlockApps;

            await _db.SaveChangesAsync();
            return Ok(existing);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            var existing = await _db.Schedules.FindAsync(id);
            if (existing == null) return NotFound();
            _db.Schedules.Remove(existing);
            await _db.SaveChangesAsync();
            return Ok(new { status = "success" });
        }
    }

    // ==================== 3. CONTACTS CRUD ====================
    [ApiController]
    [Route("api/[controller]")]
    public class ContactsController : ControllerBase
    {
        private readonly NguyenHuuPhucDbContext _db;
        public ContactsController(NguyenHuuPhucDbContext db) => _db = db;

        [HttpGet]
        public async Task<IActionResult> GetContacts([FromQuery] string? child_id)
        {
            var query = _db.Contacts.AsQueryable();
            if (!string.IsNullOrEmpty(child_id)) query = query.Where(c => c.ChildId == child_id);
            return Ok(await query.ToListAsync());
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Contact con)
        {
            if (string.IsNullOrWhiteSpace(con.Id)) con.Id = $"con_{Guid.NewGuid().ToString("N")[..8]}";
            con.CreatedAt = DateTime.UtcNow;
            _db.Contacts.Add(con);
            await _db.SaveChangesAsync();
            return Ok(con);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, [FromBody] Contact con)
        {
            var existing = await _db.Contacts.FindAsync(id);
            if (existing == null) return NotFound();

            existing.Name = con.Name;
            existing.Phone = con.Phone;
            existing.Relationship = con.Relationship;
            existing.IsSosContact = con.IsSosContact;
            existing.Avatar = con.Avatar;

            await _db.SaveChangesAsync();
            return Ok(existing);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            var existing = await _db.Contacts.FindAsync(id);
            if (existing == null) return NotFound();
            _db.Contacts.Remove(existing);
            await _db.SaveChangesAsync();
            return Ok(new { status = "success" });
        }
    }

    // ==================== 4. NOISE LOGS ====================
    [ApiController]
    [Route("api/[controller]")]
    public class NoiseController : ControllerBase
    {
        private readonly NguyenHuuPhucDbContext _db;
        public NoiseController(NguyenHuuPhucDbContext db) => _db = db;

        [HttpGet]
        public async Task<IActionResult> GetLogs([FromQuery] string? child_id)
        {
            var query = _db.NoiseLogs.AsQueryable();
            if (!string.IsNullOrEmpty(child_id)) query = query.Where(n => n.ChildId == child_id);
            return Ok(await query.ToListAsync());
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] NoiseLog log)
        {
            if (string.IsNullOrWhiteSpace(log.Id)) log.Id = $"nl_{Guid.NewGuid().ToString("N")[..8]}";
            _db.NoiseLogs.Add(log);
            await _db.SaveChangesAsync();
            return Ok(log);
        }
    }

    public class SOSTicketUpdateDto
    {
        public string? Status { get; set; }
        public string? AssignedStaffId { get; set; }
        public string? ResolutionNotes { get; set; }
    }

    // ==================== 5. SOS TICKETS ====================
    [ApiController]
    [Route("api/[controller]")]
    public class SosController : ControllerBase
    {
        private readonly NguyenHuuPhucDbContext _db;
        public SosController(NguyenHuuPhucDbContext db) => _db = db;

        [HttpGet]
        public async Task<IActionResult> GetTickets()
        {
            return Ok(await _db.SOSTickets.OrderByDescending(t => t.CreatedAt).ToListAsync());
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] SOSTicket ticket)
        {
            if (string.IsNullOrWhiteSpace(ticket.Id)) ticket.Id = $"sos_{Guid.NewGuid().ToString("N")[..8]}";
            ticket.CreatedAt = DateTime.UtcNow;
            _db.SOSTickets.Add(ticket);
            await _db.SaveChangesAsync();
            return Ok(ticket);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, [FromBody] SOSTicketUpdateDto dto)
        {
            var existing = await _db.SOSTickets.FindAsync(id);
            if (existing == null) return NotFound();

            if (!string.IsNullOrWhiteSpace(dto.Status)) existing.Status = dto.Status;
            if (dto.AssignedStaffId != null) existing.AssignedStaffId = dto.AssignedStaffId;
            if (dto.ResolutionNotes != null) existing.ResolutionNotes = dto.ResolutionNotes;

            await _db.SaveChangesAsync();
            return Ok(existing);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            var existing = await _db.SOSTickets.FindAsync(id);
            if (existing == null) return NotFound();
            _db.SOSTickets.Remove(existing);
            await _db.SaveChangesAsync();
            return Ok(new { status = "success" });
        }
    }

    // ==================== 6. USERS CRUD (FOR ADMIN) ====================
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly NguyenHuuPhucDbContext _db;
        public UsersController(NguyenHuuPhucDbContext db) => _db = db;

        [HttpGet]
        public async Task<IActionResult> GetUsers([FromQuery] string? role)
        {
            var query = _db.Users.AsQueryable();
            if (!string.IsNullOrEmpty(role)) query = query.Where(u => u.Role == role);
            return Ok(await query.ToListAsync());
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] User user)
        {
            if (string.IsNullOrWhiteSpace(user.Id)) user.Id = $"usr_{Guid.NewGuid().ToString("N")[..8]}";
            user.CreatedAt = DateTime.UtcNow;
            _db.Users.Add(user);
            await _db.SaveChangesAsync();
            return Ok(user);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, [FromBody] User user)
        {
            var existing = await _db.Users.FindAsync(id);
            if (existing == null) return NotFound();

            existing.Name = user.Name;
            existing.Phone = user.Phone;
            existing.Role = user.Role;
            existing.Avatar = user.Avatar;

            await _db.SaveChangesAsync();
            return Ok(existing);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            var existing = await _db.Users.FindAsync(id);
            if (existing == null) return NotFound();
            _db.Users.Remove(existing);
            await _db.SaveChangesAsync();
            return Ok(new { status = "success" });
        }
    }
}
