# Example: .NET Framework to .NET 8 Migration
# Each line is one task. Lines starting with # are skipped.

Convert MyProject.csproj from old format to SDK-style targeting net8.0
Remove packages.config and migrate all NuGet references to PackageReference in csproj
Migrate web.config settings to appsettings.json and appsettings.Development.json
Replace Global.asax and Startup.cs with Program.cs minimal hosting pattern for .NET 8
Migrate Services/PaymentService.cs from .NET Framework APIs to .NET 8 equivalents
Migrate Services/AuthService.cs from .NET Framework APIs to .NET 8 equivalents
Migrate Controllers/ApiController.cs to .NET 8 controller pattern with [ApiController] attribute
Replace System.Web.HttpContext usage with IHttpContextAccessor across all files
Replace ConfigurationManager usage with IConfiguration dependency injection
Run dotnet build and fix all compilation errors
Run dotnet test and fix all failing tests
