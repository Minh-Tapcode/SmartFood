using Microsoft.EntityFrameworkCore;
using SmartFood.Data;
using SmartFood.Hubs;
using SmartFood.Repositories;
using SmartFood.Options;
using SmartFood.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// ===== 1. Add services =====
builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddCors(o => o.AddDefaultPolicy(p =>
    p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

// DbContext với SQL Server
builder.Services.AddDbContext<SmartFoodContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("SmartFoodDB")));
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey =
                new SymmetricSecurityKey(Encoding.UTF8.GetBytes("12345678901234567890123456789012"))
        };
    });

// Swagger / OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddScoped<UserService>();
builder.Services.AddScoped<UserRepository>();
builder.Services.AddScoped<ProductRepository>();
builder.Services.AddScoped<ProductService>();
builder.Services.AddScoped<CartRepository>();
builder.Services.AddScoped<CartService>();
builder.Services.AddScoped<OrderRepository>();
builder.Services.AddScoped<OrderService>();
builder.Services.AddScoped<PaymentRepository>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<CategoryRepository>();
builder.Services.AddScoped<CategoryService>();
builder.Services.AddScoped<FavoriteRepository>();
builder.Services.AddScoped<FavoriteService>();
builder.Services.AddScoped<RatingRepository>();
builder.Services.AddScoped<RatingService>();
builder.Services.AddScoped<PromotionRepository>();
builder.Services.AddScoped<ChatRepository>();
builder.Services.AddScoped<RecommendationService>();
builder.Services.AddScoped<ChatSuggestionService>();
builder.Services.Configure<GroqOptions>(builder.Configuration.GetSection(GroqOptions.SectionName));
builder.Services.AddHttpClient<IAiChatService, GroqChatService>();
builder.Services.AddScoped<ChatService>();

// ===== 2. Build app =====
var app = builder.Build();

// ===== 3. Configure middleware =====
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<ChatHub>("/hubs/chat");

// ===== 4. Run app =====
app.Run();