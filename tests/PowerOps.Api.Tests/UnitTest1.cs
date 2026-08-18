using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace PowerOps.Api.Tests;

public class ApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public ApiTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task RootEndpoint_ReturnsSuccess()
    {
        var response = await _client.GetAsync("/");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task HealthEndpoint_ReturnsSuccess()
    {
        var response = await _client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task SitesEndpoint_ReturnsSuccess()
    {
        var response = await _client.GetAsync("/api/sites");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task InvalidSite_ReturnsNotFound()
    {
        var response = await _client.GetAsync("/api/sites/999");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}