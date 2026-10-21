using System.ComponentModel.DataAnnotations;

namespace KidSafe.Api.DTOs
{
    public class RegisterDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;

        public string? Phone { get; set; }

        public string Role { get; set; } = "parent";
    }

    public class LoginDto
    {
        [Required]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;

        public string DeliveryMethod { get; set; } = "email";
    }

    public class VerifyOtpDto
    {
        [Required]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Otp { get; set; } = string.Empty;
    }

    public class ResendOtpDto
    {
        [Required]
        public string Email { get; set; } = string.Empty;

        public string DeliveryMethod { get; set; } = "email";
    }

    public class ChildCreateDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;

        public int Age { get; set; }

        public string Gender { get; set; } = "male";

        public string? Phone { get; set; }

        public string Avatar { get; set; } = "avatar_boy_1";

        public string? DeviceId { get; set; }

        public int DailyScreenLimitMinutes { get; set; } = 180;
    }

    public class ChildUpdateDto
    {
        public string? Name { get; set; }
        public int? Age { get; set; }
        public string? Gender { get; set; }
        public string? Phone { get; set; }
        public string? Avatar { get; set; }
        public int? BatteryLevel { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public double? CurrentNoiseDb { get; set; }
        public int? DailyScreenLimitMinutes { get; set; }
        public int? UsedScreenMinutes { get; set; }
    }

    public class PairDeviceDto
    {
        [Required]
        public string ParentId { get; set; } = string.Empty;

        [Required]
        public string DeviceId { get; set; } = string.Empty;

        public string? Name { get; set; }
    }

    public class UpdateLocationDto
    {
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public int? BatteryLevel { get; set; }
    }

    public class LiveNoiseDto
    {
        public double Decibel { get; set; }
        public string Status { get; set; } = "Normal";
        public string Note { get; set; } = "Cập nhật từ micro máy con";
    }

    public class CreateTimeRequestDto
    {
        [Required]
        public string ChildId { get; set; } = string.Empty;

        public int MinutesRequested { get; set; } = 30;

        [Required]
        public string Reason { get; set; } = string.Empty;
    }

    public class ReviewTimeRequestDto
    {
        [Required]
        public string Status { get; set; } = "approved"; // approved or rejected

        public string? ReviewedBy { get; set; }
    }
}
