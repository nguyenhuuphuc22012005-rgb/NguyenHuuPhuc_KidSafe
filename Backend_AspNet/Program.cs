using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using KidSafe.Api.Data;
using KidSafe.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// 1. Cấu hình DbContext kết nối SQL Server
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
    ?? "Server=.;Database=KidSafeDb;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true";

builder.Services.AddDbContext<KidSafeDbContext>(options =>
    options.UseSqlServer(connectionString));

// 2. Đăng ký Services (EmailService, JwtService)
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IJwtService, JwtService>();

// 3. Cấu hình JWT Authentication & Phân quyền
var key = Encoding.UTF8.GetBytes(JwtService.SecretKey);
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = true,
        ValidIssuer = JwtService.Issuer,
        ValidateAudience = true,
        ValidAudience = JwtService.Audience,
        ClockSkew = TimeSpan.Zero
    };
});

// 4. Cấu hình CORS mở cho mọi thiết bị Flutter di động / Web kết nối
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

builder.Services.AddControllers();

// 5. Cấu hình Swagger / OpenAPI Documentation
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "KidSafe ASP.NET Core Web API",
        Version = "v1",
        Description = "Hệ thống Web API quản lý & giám sát điện thoại trẻ em (.NET 9 + SQL Server)"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Nhập token JWT theo định dạng: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// Enable Swagger UI
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "KidSafe API v1");
    c.RoutePrefix = "swagger";
});

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Root ping
app.MapGet("/", () => Results.Ok(new
{
    service = "KidSafe ASP.NET Core Web API",
    status = "running",
    database = "Microsoft SQL Server",
    swagger_docs = "/swagger"
}));

Console.WriteLine("==========================================================");
Console.WriteLine("🛡️  KIDSAFE ASP.NET CORE WEB API (.NET 9 + SQL SERVER)  ");
Console.WriteLine("    Swagger UI: http://localhost:8000/swagger             ");
Console.WriteLine("==========================================================");

app.Run();
