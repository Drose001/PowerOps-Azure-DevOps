FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

WORKDIR /src

COPY ["src/PowerOps.Api/PowerOps.Api.csproj", "src/PowerOps.Api/"]

RUN dotnet restore "src/PowerOps.Api/PowerOps.Api.csproj"

COPY . .

WORKDIR "/src/src/PowerOps.Api"

RUN dotnet publish "PowerOps.Api.csproj" -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final

WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 8080

ENV ASPNETCORE_HTTP_PORTS=8080

ENTRYPOINT ["dotnet", "PowerOps.Api.dll"]