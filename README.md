# PowerOps — Azure DevOps Platform

PowerOps is a portfolio project that demonstrates how a modern .NET application can be built, deployed, secured, and monitored using Microsoft Azure and DevOps practices.

The project simulates a clean-energy operations platform used to monitor solar-energy facilities, production levels, system health, and operational status.

## Project Goals

This project is being developed to demonstrate hands-on experience with:

* C# and .NET Web APIs
* REST API development
* Git and GitHub
* Docker containerization
* Azure Container Apps
* Azure Container Registry
* Azure DevOps CI/CD pipelines
* YAML pipelines
* Infrastructure as Code using Bicep
* Development, staging, and production environments
* Azure Key Vault
* Microsoft Entra ID and RBAC
* Azure Monitor
* Application Insights
* Log Analytics and KQL
* Automated testing
* Deployment health checks
* Release approvals
* Canary deployments
* Rollback procedures
* Incident response
* Root-cause analysis

## Current Features

The PowerOps API currently includes:

* Application status endpoint
* Health-check endpoint
* Energy-site information
* Solar production data
* Multiple simulated Arizona energy facilities

## API Endpoints

### Application Status

```http
GET /
```

Returns basic information about the PowerOps application.

### Health Check

```http
GET /health
```

Returns the current health of the application.

Example:

```json
{
  "status": "Healthy",
  "timestamp": "2026-08-18T17:02:00Z"
}
```

### Energy Sites

```http
GET /api/sites
```

Returns all energy facilities.

Current demonstration facilities include:

* Tempe Solar Facility
* Phoenix Solar Facility
* Mesa Solar Facility

### Energy Site

```http
GET /api/sites/{id}
```

Returns information about an individual energy facility.

### Production Information

```http
GET /api/sites/{id}/production
```

Returns production information for an individual energy facility.

## Planned Azure Architecture

```text
GitHub
   |
   v
Azure DevOps
   |
   +-- Build
   +-- Automated Tests
   +-- Quality Checks
   +-- Docker Build
   |
   v
Azure Container Registry
   |
   v
Development
   |
   v
Staging
   |
   v
Approval Gate
   |
   v
Production
   |
   v
Azure Container Apps
   |
   +-- Azure Key Vault
   +-- Cosmos DB
   +-- Azure Storage
   +-- Application Insights
   +-- Azure Monitor
   +-- Log Analytics
```

## Deployment Strategy

PowerOps will use a multi-environment deployment strategy:

```text
Development
     |
     v
Automated Validation
     |
     v
Staging
     |
     v
Approval
     |
     v
Production
```

The same tested application artifact will be promoted between environments to demonstrate a **build-once, deploy-many** approach.

## Monitoring and Reliability

The completed platform will demonstrate:

* Application health monitoring
* Centralized application logs
* Performance metrics
* Azure Monitor alerts
* Application Insights
* KQL troubleshooting queries
* Deployment validation
* Rollback procedures
* Simulated incident response
* Root-cause analysis

## Security

Planned security controls include:

* Azure Key Vault for secrets
* Managed identities
* Microsoft Entra ID
* Role-Based Access Control (RBAC)
* Secure configuration management
* Environment separation
* No secrets stored in source control

## Technology Stack

**Application**

* C#
* .NET
* ASP.NET Core Web API

**DevOps**

* Git
* GitHub
* Azure DevOps
* Azure Pipelines
* YAML
* Docker

**Microsoft Azure**

* Azure Container Apps
* Azure Container Registry
* Azure Key Vault
* Azure Monitor
* Application Insights
* Log Analytics
* Cosmos DB
* Azure Storage

**Infrastructure as Code**

* Bicep

**Automation**

* PowerShell

## Project Status

🚧 **In Development**

Current milestone:

* [x] Create PowerOps .NET API
* [x] Create application status endpoint
* [x] Create energy-site endpoints
* [x] Create health-check endpoint
* [ ] Initialize Git repository
* [ ] Publish project to GitHub
* [ ] Add automated tests
* [ ] Dockerize application
* [ ] Create Azure infrastructure with Bicep
* [ ] Deploy to Azure Container Apps
* [ ] Create Azure DevOps CI/CD pipeline
* [ ] Configure development environment
* [ ] Configure staging environment
* [ ] Configure production environment
* [ ] Add Key Vault
* [ ] Configure RBAC
* [ ] Add Application Insights
* [ ] Configure Azure Monitor alerts
* [ ] Create KQL queries
* [ ] Implement canary deployment
* [ ] Simulate deployment failure
* [ ] Perform rollback
* [ ] Complete incident root-cause analysis

## Purpose

This project is a hands-on DevOps portfolio demonstration designed to show practical experience building and operating a cloud application using Azure, automation, CI/CD, security, observability, and modern deployment practices.
