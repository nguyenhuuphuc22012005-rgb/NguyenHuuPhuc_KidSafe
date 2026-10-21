using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KidSafe.Api.Models
{
    [Table("Users")]
    public class User
    {
        [Key]
        [MaxLength(50)]
        public string Id { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [MaxLength(150)]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MaxLength(255)]
        public string Password { get; set; } = string.Empty;

        [MaxLength(20)]
        public string? Phone { get; set; }

        [Required]
        [MaxLength(20)]
        public string Role { get; set; } = "parent"; // admin, staff, parent, child

        [MaxLength(255)]
        public string? Avatar { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    [Table("Children")]
    public class Child
    {
        [Key]
        [MaxLength(50)]
        public string Id { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string ParentId { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        public int Age { get; set; }

        [MaxLength(10)]
        public string Gender { get; set; } = "male";

        [MaxLength(20)]
        public string? Phone { get; set; }

        [MaxLength(50)]
        public string Avatar { get; set; } = "avatar_boy_1";

        [Required]
        [MaxLength(100)]
        public string DeviceId { get; set; } = string.Empty;

        public int BatteryLevel { get; set; } = 85;

        public double Latitude { get; set; } = 10.7769;

        public double Longitude { get; set; } = 106.7009;

        [MaxLength(100)]
        public string LastSeen { get; set; } = "Vừa xong";

        public double CurrentNoiseDb { get; set; } = 42.0;

        public bool IsOnline { get; set; } = true;

        public int DailyScreenLimitMinutes { get; set; } = 180;

        public int UsedScreenMinutes { get; set; } = 65;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    [Table("Geofences")]
    public class Geofence
    {
        [Key]
        [MaxLength(50)]
        public string Id { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string ChildId { get; set; } = string.Empty;

        [Required]
        [MaxLength(150)]
        public string Name { get; set; } = string.Empty;

        public double Latitude { get; set; }

        public double Longitude { get; set; }

        public double RadiusMeters { get; set; }

        public bool IsActive { get; set; } = true;

        public bool NotifyOnExit { get; set; } = true;

        public bool NotifyOnEntry { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    [Table("Schedules")]
    public class Schedule
    {
        [Key]
        [MaxLength(50)]
        public string Id { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string ChildId { get; set; } = string.Empty;

        [Required]
        [MaxLength(150)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(10)]
        public string StartTime { get; set; } = string.Empty;

        [Required]
        [MaxLength(10)]
        public string EndTime { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string Days { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;

        public bool BlockApps { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    [Table("Contacts")]
    public class Contact
    {
        [Key]
        [MaxLength(50)]
        public string Id { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string ChildId { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [MaxLength(20)]
        public string Phone { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string Relationship { get; set; } = string.Empty;

        public bool IsSosContact { get; set; } = false;

        [MaxLength(50)]
        public string? Avatar { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    [Table("NoiseLogs")]
    public class NoiseLog
    {
        [Key]
        [MaxLength(50)]
        public string Id { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string ChildId { get; set; } = string.Empty;

        public double Decibel { get; set; }

        [Required]
        [MaxLength(20)]
        public string Status { get; set; } = "Normal";

        [Required]
        [MaxLength(50)]
        public string Timestamp { get; set; } = string.Empty;

        [MaxLength(255)]
        public string? Note { get; set; }
    }

    [Table("TimeExtensionRequests")]
    public class TimeExtensionRequest
    {
        [Key]
        [MaxLength(50)]
        public string Id { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string ChildId { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string ChildName { get; set; } = string.Empty;

        public int MinutesRequested { get; set; } = 30;

        [Required]
        [MaxLength(255)]
        public string Reason { get; set; } = string.Empty;

        [MaxLength(20)]
        public string Status { get; set; } = "pending"; // pending, approved, rejected

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? ReviewedAt { get; set; }

        [MaxLength(50)]
        public string? ReviewedBy { get; set; }
    }

    [Table("SOSTickets")]
    public class SOSTicket
    {
        [Key]
        [MaxLength(50)]
        public string Id { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string ChildId { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string ChildName { get; set; } = string.Empty;

        [MaxLength(100)]
        public string? ParentName { get; set; }

        [MaxLength(20)]
        public string? ParentPhone { get; set; }

        public double Latitude { get; set; }

        public double Longitude { get; set; }

        public double NoiseLevel { get; set; } = 0.0;

        [Required]
        [MaxLength(255)]
        public string Reason { get; set; } = string.Empty;

        [MaxLength(20)]
        public string Status { get; set; } = "pending"; // pending, in_progress, resolved

        [MaxLength(50)]
        public string? AssignedStaffId { get; set; }

        [MaxLength(500)]
        public string? ResolutionNotes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
