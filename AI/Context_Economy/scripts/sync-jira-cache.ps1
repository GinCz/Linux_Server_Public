<#
.SYNOPSIS
Cache-First Knowledge base sync script for Jira/Confluence.

.DESCRIPTION
Searches Jira tickets, downloads full payloads, and saves them locally as JSON and normalized Markdown files.
Supports fetching only changed tickets (via etag/updated_at).

.EXAMPLE
.\sync-jira-cache.ps1 -Action init
.\sync-jira-cache.ps1 -Action search -Query "project=ABC AND status=Resolved"
.\sync-jira-cache.ps1 -Action resync-ticket -TicketId "ABC-1234"
.\sync-jira-cache.ps1 -Action refresh
#>

param (
    [ValidateSet("init", "search", "resync-ticket", "refresh", "status")]
    [string]$Action = "status",
    
    [string]$Query = "",
    [string]$TicketId = ""
)

clear

$CacheRoot = if ($env:AI_CACHE_ROOT) { $env:AI_CACHE_ROOT } else { "C:\AI\BASE\cache" }
$JiraCachePath = Join-Path $CacheRoot "jira"
$JiraUrl = $env:JIRA_URL
$JiraToken = $env:JIRA_TOKEN

function Init-Cache {
    if (-not (Test-Path $JiraCachePath)) {
        New-Item -ItemType Directory -Path $JiraCachePath -Force | Out-Null
        Write-Host "Created Jira cache directory at $JiraCachePath" -ForegroundColor Green
    } else {
        Write-Host "Jira cache directory already exists at $JiraCachePath" -ForegroundColor Yellow
    }
}

function Invoke-JiraApi {
    param([string]$Endpoint)
    
    if ([string]::IsNullOrEmpty($JiraUrl) -or [string]::IsNullOrEmpty($JiraToken)) {
        Write-Error "Please set JIRA_URL and JIRA_TOKEN environment variables."
        exit 1
    }

    $Uri = "$JiraUrl/rest/api/2/$Endpoint"
    $Headers = @{
        "Authorization" = "Bearer $JiraToken"
        "Accept" = "application/json"
    }

    try {
        $Response = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Get
        return $Response
    } catch {
        Write-Error "Failed to fetch from Jira: $_"
        return $null
    }
}

function Save-Ticket {
    param($Ticket)
    
    $Key = $Ticket.key
    $Updated = $Ticket.fields.updated
    
    $JsonPath = Join-Path $JiraCachePath "$Key.json"
    $MdPath = Join-Path $JiraCachePath "$Key.md"
    
    $NeedsUpdate = $true
    if (Test-Path $JsonPath) {
        $CachedJson = Get-Content $JsonPath -Raw | ConvertFrom-Json
        if ($CachedJson.fields.updated -eq $Updated) {
            $NeedsUpdate = $false
        }
    }
    
    if ($NeedsUpdate) {
        Write-Host "Saving $Key..." -ForegroundColor Cyan
        
        # Save raw JSON
        $Ticket | ConvertTo-Json -Depth 10 | Set-Content -Path $JsonPath -Encoding UTF8
        
        # Save normalized MD
        $Summary = $Ticket.fields.summary
        $Status = $Ticket.fields.status.name
        $Desc = $Ticket.fields.description
        
        $NextFreshness = (Get-Date).AddDays(90).ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        $MdContent = @"
---
id: $Key
source: jira
source_updated: $Updated
cached_at: $((Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ"))
freshness_check_after: $NextFreshness
status: $Status
---
# [$Key] $Summary

## Description
$Desc
"@
        Set-Content -Path $MdPath -Value $MdContent -Encoding UTF8
    } else {
        Write-Host "$Key is up to date." -ForegroundColor Gray
    }
}

switch ($Action) {
    "init" {
        Init-Cache
    }
    "search" {
        if ([string]::IsNullOrEmpty($Query)) {
            Write-Error "Please provide a -Query string."
            exit 1
        }
        $EncodedQuery = [System.Web.HttpUtility]::UrlEncode($Query)
        $Results = Invoke-JiraApi -Endpoint "search?jql=$EncodedQuery&maxResults=50"
        foreach ($Issue in $Results.issues) {
            Save-Ticket -Ticket $Issue
        }
        Write-Host "Search and cache complete." -ForegroundColor Green
    }
    "resync-ticket" {
        if ([string]::IsNullOrEmpty($TicketId)) {
            Write-Error "Please provide a -TicketId."
            exit 1
        }
        $Issue = Invoke-JiraApi -Endpoint "issue/$TicketId"
        if ($Issue) {
            Save-Ticket -Ticket $Issue
        }
    }
    "refresh" {
        $Files = Get-ChildItem -Path $JiraCachePath -Filter "*.json"
        foreach ($File in $Files) {
            $Key = $File.BaseName
            $Issue = Invoke-JiraApi -Endpoint "issue/$Key"
            if ($Issue) {
                Save-Ticket -Ticket $Issue
            }
        }
        Write-Host "Refresh complete." -ForegroundColor Green
    }
    "status" {
        if (Test-Path $JiraCachePath) {
            $Count = (Get-ChildItem -Path $JiraCachePath -Filter "*.md").Count
            Write-Host "Knowledge Cache Status: $Count tickets cached." -ForegroundColor Cyan
        } else {
            Write-Host "Cache not initialized. Run with -Action init" -ForegroundColor Yellow
        }
    }
}
