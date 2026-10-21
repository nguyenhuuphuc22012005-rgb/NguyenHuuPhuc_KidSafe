using Microsoft.EntityFrameworkCore;
using KidSafe.Api.Models;

namespace KidSafe.Api.Data
{
    public class NguyenHuuPhucDbContext : DbContext
    {
        public NguyenHuuPhucDbContext(DbContextOptions<NguyenHuuPhucDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users => Set<User>();
        public DbSet<Child> Children => Set<Child>();
        public DbSet<Geofence> Geofences => Set<Geofence>();
        public DbSet<Schedule> Schedules => Set<Schedule>();
        public DbSet<Contact> Contacts => Set<Contact>();
        public DbSet<NoiseLog> NoiseLogs => Set<NoiseLog>();
        public DbSet<TimeExtensionRequest> TimeExtensionRequests => Set<TimeExtensionRequest>();
        public DbSet<SOSTicket> SOSTickets => Set<SOSTicket>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
        }
    }
}
