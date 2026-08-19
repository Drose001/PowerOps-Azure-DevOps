var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

var sites = new List<EnergySite>
{
    new(
        1,
        "Tempe Solar Facility",
        "Tempe",
        "Arizona",
        "Online",
        124.6,
        645.3
    ),

    new(
        2,
        "Phoenix Solar Facility",
        "Phoenix",
        "Arizona",
        "Online",
        152.8,
        832.4
    ),

    new(
        3,
        "Mesa Solar Facility",
        "Mesa",
        "Arizona",
        "Warning",
        67.2,
        301.5
    )
};

app.MapGet("/", () =>
{
    return Results.Ok(new
    {
        application = "PowerOps",
        description = "Azure Clean Energy Operations Platform",
        status = "Running"
    });
});

// Health endpoint used by automated tests and deployment monitoring.
app.MapGet("/health", () =>
{
    return Results.Ok(new
    {
        status = "Healthy",
        timestamp = DateTime.UtcNow
    });
});

app.MapGet("/api/sites", () =>
{
    return Results.Ok(sites);
});

app.MapGet("/api/sites/{id:int}", (int id) =>
{
    var site = sites.FirstOrDefault(s => s.Id == id);

    return site is null
        ? Results.NotFound(new
        {
            message = "Energy site not found."
        })
        : Results.Ok(site);
});

app.MapGet("/api/sites/{id:int}/production", (int id) =>
{
    var site = sites.FirstOrDefault(s => s.Id == id);

    if (site is null)
    {
        return Results.NotFound(new
        {
            message = "Energy site not found."
        });
    }

    return Results.Ok(new
    {
        siteId = site.Id,
        siteName = site.Name,
        currentProductionKw = site.CurrentProductionKw,
        dailyProductionKwh = site.DailyProductionKwh
    });
});

app.Run();

record EnergySite(
    int Id,
    string Name,
    string City,
    string State,
    string Status,
    double CurrentProductionKw,
    double DailyProductionKwh
);

public partial class Program { }