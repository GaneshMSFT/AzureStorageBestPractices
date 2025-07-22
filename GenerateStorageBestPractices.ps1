# =============================================================================
# Azure Storage Best Practices Analysis Script
# =============================================================================
# 
# This script analyzes Azure Storage Accounts and Blob Services for 
# best practices and generates HTML reports with color-coded recommendations.
#
# REQUIREMENTS:
# - Azure PowerShell module (pre-installed in Azure Cloud Shell)
# - Reader access to Azure subscription and storage accounts
# - Storage Account Contributor role (for blob service properties)
#
# USAGE:
# 1. Load the script: . ./GenerateStorageBestPractices.ps1
# 2. Run analysis: Generate-StorageBestPracticesReport -SubscriptionId "your-subscription-id"
#
# For detailed instructions, see README.md
# =============================================================================

# Helper function to set subscription context and validate access
function Set-SubscriptionContext {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId
    )
    
    Write-Host "Setting subscription context to: $SubscriptionId" -ForegroundColor Cyan
    try {
        # Validate subscription ID format first
        if ($SubscriptionId -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') {
            throw "Invalid subscription ID format. Expected GUID format."
        }
        
        Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null
        
        # Verify the context was actually set correctly
        $currentContext = Get-AzContext
        if ($currentContext.Subscription.Id -ne $SubscriptionId) {
            throw "Failed to set correct subscription context. Current: $($currentContext.Subscription.Id), Expected: $SubscriptionId"
        }
        
        Write-Host "✅ Successfully connected to subscription: $SubscriptionId" -ForegroundColor Green
        return $true
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error "❌ Failed to set subscription context: $errorMessage"
        Write-Host "💡 Troubleshooting tips:" -ForegroundColor Yellow
        Write-Host "   - Verify you have access to subscription: $SubscriptionId" -ForegroundColor Yellow
        Write-Host "   - Check if you're signed in: Get-AzContext" -ForegroundColor Yellow
        Write-Host "   - Try signing in again: Connect-AzAccount" -ForegroundColor Yellow
        return $false
    }
}

# Helper function to get and validate storage accounts with detailed info (optimized, pipeline-based, minimal memory footprint)
function Get-ValidatedStorageAccounts {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId
    )
    Write-Host "Retrieving storage accounts with detailed properties..." -ForegroundColor Cyan
    
    try {
        $basicAccounts = Get-AzStorageAccount -ErrorAction Stop
        if (-not $basicAccounts) {
            Write-Warning "No storage accounts found in subscription: $SubscriptionId"
            Write-Host "Please verify you have access and there are storage accounts in this subscription." -ForegroundColor Yellow
            return $null
        }
        
        Write-Host "Found $($basicAccounts.Count) storage account(s). Retrieving detailed properties..." -ForegroundColor Cyan
        
        # Use pipeline to minimize memory and improve speed with better error handling
        $detailedAccounts = $basicAccounts | ForEach-Object {
            $currentAccount = $_
            try {
                Write-Verbose "Processing storage account: $($currentAccount.StorageAccountName)" -Verbose:$false
                Get-AzStorageAccount -ResourceGroupName $currentAccount.ResourceGroupName -Name $currentAccount.StorageAccountName -ErrorAction Stop
            } catch {
                $errorMessage = $_.Exception.Message
                Write-Warning "Failed to get detailed properties for $($currentAccount.StorageAccountName): $errorMessage"
                # Return the basic account info as fallback to maintain script continuity
                $currentAccount
            }
        }
        
        $successCount = ($detailedAccounts | Where-Object { $_.StorageAccountName } | Measure-Object).Count
        Write-Host "Successfully processed $successCount storage account(s) for analysis" -ForegroundColor Green
        return $detailedAccounts
        
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Error "❌ Failed to retrieve storage accounts: $errorMessage"
        Write-Host "💡 Troubleshooting tips:" -ForegroundColor Yellow
        Write-Host "   - Verify you have Reader access to the subscription" -ForegroundColor Yellow
        Write-Host "   - Check your Azure PowerShell module: Get-Module -Name Az" -ForegroundColor Yellow
        return $null
    }
}

# Helper function to get common CSS styles (centralized to avoid duplication)
function Get-CommonCssStyles {
    return @'
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.95);
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            padding: 30px;
            backdrop-filter: blur(10px);
        }
        
        h1 {
            color: #0078d4;
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
            font-weight: 300;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.1);
            position: relative;
        }
        
        h1:after {
            content: '';
            display: block;
            width: 100px;
            height: 4px;
            background: linear-gradient(90deg, #0078d4, #00bcf2);
            margin: 20px auto;
            border-radius: 2px;
        }
        
        h2 {
            color: #0078d4;
            margin: 40px 0 20px 0;
            font-size: 1.8em;
            font-weight: 400;
            padding-left: 15px;
            border-left: 4px solid #0078d4;
            background: linear-gradient(90deg, rgba(0, 120, 212, 0.1), transparent);
            padding: 15px;
            border-radius: 8px;
        }
        
        .legend {
            display: flex;
            justify-content: center;
            gap: 30px;
            margin: 30px 0;
            flex-wrap: wrap;
            background: rgba(248, 250, 254, 0.8);
            padding: 20px;
            border-radius: 12px;
            border: 1px solid #e0e6ed;
        }
        
        .legend-item {
            display: flex;
            align-items: center;
            gap: 8px;
            font-weight: 500;
        }
        
        .legend-color {
            width: 20px;
            height: 20px;
            border-radius: 50%;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
        }
        
        .legend-good { background: linear-gradient(135deg, #1b5e20 0%, #4caf50 100%); }
        .legend-bad { background: linear-gradient(135deg, #b71c1c 0%, #d32f2f 100%); }
        .legend-warning { background: linear-gradient(135deg, #e65100 0%, #ff9800 100%); }
        
        .section {
            margin-bottom: 50px;
            background: white;
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.05);
            border: 1px solid #e0e6ed;
        }
        
        .table-container {
            overflow-x: auto;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            margin-top: 20px;
        }
        
        table {
            border-collapse: collapse;
            width: 100%;
            background: white;
            border-radius: 12px;
            overflow: hidden;
        }
        
        th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 18px 15px;
            text-align: left;
            font-weight: 600;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            position: sticky;
            top: 0;
            z-index: 10;
        }
        
        td {
            padding: 15px;
            border-bottom: 1px solid #e0e6ed;
            transition: background-color 0.3s ease;
            font-size: 0.9em;
        }
        
        tr:hover {
            background-color: #f8fafe;
            transform: scale(1.001);
            transition: all 0.3s ease;
        }
        
        tr:nth-child(even) {
            background-color: #fafbfc;
        }
        
        .status-indicator {
            padding: 6px 12px;
            border-radius: 20px;
            font-weight: 600;
            font-size: 0.85em;
            text-align: center;
            display: inline-block;
            min-width: 120px;
            text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.1);
        }
        
        .status-good {
            background: linear-gradient(135deg, #1b5e20 0%, #4caf50 100%);
            color: #ffffff;
            box-shadow: 0 4px 8px rgba(27, 94, 32, 0.3);
        }
        
        .status-bad {
            background: linear-gradient(135deg, #b71c1c 0%, #d32f2f 100%);
            color: #ffffff;
            box-shadow: 0 4px 8px rgba(183, 28, 28, 0.3);
        }
        
        .status-warning {
            background: linear-gradient(135deg, #e65100 0%, #ff9800 100%);
            color: #ffffff;
            box-shadow: 0 4px 8px rgba(230, 81, 0, 0.3);
        }
        
        @media (max-width: 768px) {
            .container { padding: 20px; }
            h1 { font-size: 2em; }
            h2 { font-size: 1.5em; }
            th, td { padding: 12px 8px; font-size: 0.8em; }
            .legend { flex-direction: column; align-items: center; }
        }
        
        td a {
            color: #0078d4 !important;
            text-decoration: none;
            font-weight: 600;
            border-bottom: 1px solid transparent;
            transition: all 0.3s ease;
        }
        
        td a:hover {
            color: #106ebe !important;
            border-bottom: 1px solid #106ebe;
            text-shadow: 0 1px 2px rgba(16, 110, 190, 0.3);
        }
        
        td a:visited {
            color: #0078d4 !important;
        }
        
        .status-indicator a {
            text-decoration: underline !important;
            font-weight: 600;
            transition: all 0.3s ease;
        }
        
        .status-indicator a:hover {
            text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.3);
            transform: scale(1.05);
        }
        
        .status-bad a {
            color: white !important;
        }
        
        .status-warning a {
            color: #ffffff !important;
        }
        
        @media print {
            body { background: white; }
            .container { box-shadow: none; }
            .section { break-inside: avoid; }
            table { break-inside: avoid; }
        }
'@
}

# Main function - This is what users should call (optimized for performance)
function Generate-StorageBestPracticesReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Azure subscription ID in GUID format")]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$SubscriptionId,
        
        [Parameter(HelpMessage = "Output HTML file path")]
        [ValidateNotNullOrEmpty()]
        [string]$HtmlOutput = "StorageBestPractices.html",
        
        [Parameter(HelpMessage = "Show detailed execution information")]
        [switch]$ShowDetails
    )

    # Start timer to measure execution efficiency
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $startTime = Get-Date
    
    if ($ShowDetails) {
        Write-Host "🔄 Generating comprehensive Azure Storage Best Practices Report..." -ForegroundColor Cyan
        Write-Host "📋 This report includes both Storage Account and Blob Service best practices analysis" -ForegroundColor Cyan
        Write-Host "⏱️  Started at: $($startTime.ToString('yyyy-MM-dd HH:mm:ss')) (Local Time)" -ForegroundColor Gray
    }
    else {
        Write-Host "Generating Azure Storage Best Practices Report..." -ForegroundColor Cyan
    }
    
    # Use the combined function to generate the complete report
    Generate-CombinedStorageBestPractices -SubscriptionId $SubscriptionId -HtmlOutput $HtmlOutput
    
    # Stop timer and display results
    $stopwatch.Stop()
    $endTime = Get-Date
    $elapsed = $stopwatch.Elapsed
    
    Write-Host "✅ Report generated successfully: $HtmlOutput" -ForegroundColor Green
    
    if ($ShowDetails) {
        Write-Host ""
        Write-Host "⏱️  EXECUTION COMPLETED!" -ForegroundColor Green
        Write-Host "📅 Started:  $($startTime.ToString('yyyy-MM-dd HH:mm:ss')) (Local Time)" -ForegroundColor Yellow
        Write-Host "📅 Finished: $($endTime.ToString('yyyy-MM-dd HH:mm:ss')) (Local Time)" -ForegroundColor Yellow
        Write-Host "📊 Total execution time: $($elapsed.Minutes):$($elapsed.Seconds.ToString('00')):$($elapsed.Milliseconds.ToString('000'))" -ForegroundColor Cyan
        Write-Host "⚡ Script efficiency: Analyzed all storage accounts in $($elapsed.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Cyan
        if ($elapsed.TotalMinutes -lt 1) {
            Write-Host "🚀 Excellent performance! Completed in under 1 minute." -ForegroundColor Green
        }
        elseif ($elapsed.TotalMinutes -lt 3) {
            Write-Host "✅ Good performance! Completed in under 3 minutes." -ForegroundColor Green
        }
        else {
            Write-Host "📈 Analysis completed. Large subscription scanned efficiently." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Execution time: $($elapsed.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Gray
    }
}

# Combined function that generates both storage account and blob service analysis (memory optimized)
function Generate-CombinedStorageBestPractices {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        [string]$HtmlOutput = "CombinedStorageBestPractices.html"
    )

    Write-Host "🔄 Generating combined storage best practices analysis..." -ForegroundColor Cyan

    # Set subscription context and validate ONCE for the entire operation
    if (-not (Set-SubscriptionContext -SubscriptionId $SubscriptionId)) { return }
    
    # Get and validate storage accounts ONCE for the entire operation
    $storageAccounts = Get-ValidatedStorageAccounts -SubscriptionId $SubscriptionId
    if (-not $storageAccounts) { return }

    # Generate unique temp file names to avoid conflicts in concurrent runs
    $tempAccountFile = "temp_account_bestpractices_$(Get-Date -Format 'yyyyMMddHHmmss')_$([System.Guid]::NewGuid().ToString('N').Substring(0,8)).html"
    $tempBlobFile = "temp_blob_bestpractices_$(Get-Date -Format 'yyyyMMddHHmmss')_$([System.Guid]::NewGuid().ToString('N').Substring(0,8)).html"

    try {
        # HTML document start using centralized CSS (eliminates major duplication)
        $commonCss = Get-CommonCssStyles
        $htmlStart = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Storage Best Practices Analysis</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
$commonCss
    </style>
</head>
<body>
    <div class="container">
        <h1>Azure Storage Best Practices Analysis</h1>
        
        <div class="legend">
            <div class="legend-item">
                <div class="legend-color legend-good"></div>
                <span>Best Practice / Compliant</span>
            </div>
            <div class="legend-item">
                <div class="legend-color legend-bad"></div>
                <span>Not Following Best Practice</span>
            </div>
            <div class="legend-item">
                <div class="legend-color legend-warning"></div>
                <span>Review Required / Optional</span>
            </div>
        </div>
"@
        $htmlStart | Out-File -FilePath $HtmlOutput -Encoding utf8
        
        # Add Storage Account section
        "<div class='section'><h2>Storage Account Level Best Practices</h2><div class='table-container'>" | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
        
        # Generate storage account recommendations using pre-retrieved accounts (no redundant calls)
        Generate-StorageAccountBestPracticesInternal -StorageAccounts $storageAccounts -SubscriptionId $SubscriptionId -HtmlOutput $tempAccountFile
        
        # Read and append the table content with error checking
        if (Test-Path $tempAccountFile) {
            $accountContent = Get-Content $tempAccountFile -Raw -ErrorAction Stop
            $tableMatch = [regex]::Match($accountContent, '<table>.*?</table>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($tableMatch.Success) {
                $tableMatch.Value | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
            } else {
                Write-Warning "Could not extract table content from storage account analysis"
            }
        }
        
        "</div></div>" | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
        
        # Add Blob Service section
        "<div class='section'><h2>Blob Service Level Best Practices</h2><div class='table-container'>" | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
        
        # Generate blob service recommendations using pre-retrieved accounts (no redundant calls)
        Generate-BlobServiceBestPracticesInternal -StorageAccounts $storageAccounts -SubscriptionId $SubscriptionId -HtmlOutput $tempBlobFile
        
        # Read and append the table content with error checking
        if (Test-Path $tempBlobFile) {
            $blobContent = Get-Content $tempBlobFile -Raw -ErrorAction Stop
            $blobTableMatch = [regex]::Match($blobContent, '<table>.*?</table>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($blobTableMatch.Success) {
                $blobTableMatch.Value | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
            } else {
                Write-Warning "Could not extract table content from blob service analysis"
            }
        }
        
        # Close HTML
        "</div></div></div></body></html>" | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
        
        Write-Host "🎉 Combined storage best practices analysis written to $HtmlOutput" -ForegroundColor Green
        Write-Host "📁 File location: $(Get-Location)\$HtmlOutput" -ForegroundColor Yellow
        
    } finally {
        # Ensure temp files are always cleaned up, even if errors occur
        @($tempAccountFile, $tempBlobFile) | ForEach-Object {
            if (Test-Path $_) {
                try {
                    Remove-Item $_ -Force -ErrorAction Stop
                    Write-Verbose "Cleaned up temporary file: $_" -Verbose:$false
                } catch {
                    $errorMessage = $_.Exception.Message
                    Write-Warning "Could not clean up temporary file ${_}: $errorMessage"
                }
            }
        }
    }
}

# Internal helper functions that work with pre-retrieved storage accounts (no redundant calls)
function Generate-StorageAccountBestPracticesInternal {
    param (
        [Parameter(Mandatory = $true)]
        [array]$StorageAccounts,
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        [string]$HtmlOutput = "StorageAccountBestPractices.html"
    )

    # Table header using here-string for proper HTML handling
    $header = @'
<table>
<thead>
<tr>
    <th>STORAGE ACCOUNT NAME</th>
    <th>RESOURCE GROUP</th>
    <th>LOCATION</th>
    <th>allowBlobPublicAccess</th>
    <th>allowSharedKeyAccess</th>
    <th>enableHttpsTrafficOnly</th>
    <th>minimumTlsVersion</th>
    <th>networkRuleSet.defaultAction</th>
    <th>publicNetworkAccess</th>
</tr>
</thead>
<tbody>
'@
    
    # Build all HTML content in memory for better performance (avoid multiple file operations)
    $htmlContent = @()
    $htmlContent += $header

    $StorageAccounts | ForEach-Object {
        $props = $_
        
        # Using here-strings for all HTML content to avoid PowerShell parsing issues
        $allowBlobPublicAccessHtml = if ($props.AllowBlobPublicAccess -eq $false) {
            @'
<span class='status-indicator status-good'>FALSE</span>
'@
        } else {
            @'
<span class='status-indicator status-bad'>TRUE <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-prevent' target='_blank' style='color: white; text-decoration: underline;'>📖</a></span>
'@
        }
        
        $allowSharedKeyAccessHtml = if ($props.AllowSharedKeyAccess -eq $false) {
            @'
<span class='status-indicator status-good'>FALSE</span>
'@
        } elseif ($props.AllowSharedKeyAccess -eq $true) {
            @'
<span class='status-indicator status-bad'>TRUE <a href='https://docs.microsoft.com/en-us/azure/storage/common/shared-key-authorization-prevent' target='_blank' style='color: white; text-decoration: underline;'>📖</a></span>
'@
        } else {
            @'
<span class='status-indicator status-warning'>NULL/Unset <a href='https://docs.microsoft.com/en-us/azure/storage/common/shared-key-authorization-prevent' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
'@
        }
        
        $enableHttpsTrafficOnlyHtml = if ($props.EnableHttpsTrafficOnly -eq $true) {
            @'
<span class='status-indicator status-good'>TRUE</span>
'@
        } else {
            @'
<span class='status-indicator status-bad'>FALSE <a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-require-secure-transfer' target='_blank' style='color: white; text-decoration: underline;'>📖</a></span>
'@
        }
        
        $minimumTlsVersionHtml = if ($null -eq $props.MinimumTlsVersion) {
            @'
<span class='status-indicator status-warning'>NULL/Unset <a href='https://docs.microsoft.com/en-us/azure/storage/common/transport-layer-security-configure-minimum-version' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
'@
        } elseif ($props.MinimumTlsVersion -eq "TLS1_2" -or $props.MinimumTlsVersion -eq "TLS1_3") {
            @"
<span class='status-indicator status-good'>$($props.MinimumTlsVersion)</span>
"@
        } else {
            @"
<span class='status-indicator status-bad'>$($props.MinimumTlsVersion) <a href='https://docs.microsoft.com/en-us/azure/storage/common/transport-layer-security-configure-minimum-version' target='_blank' style='color: white; text-decoration: underline;'>📖</a></span>
"@
        }
        
        $networkRuleDefaultActionHtml = if ($null -eq $props.NetworkRuleSet.DefaultAction) {
            @'
<span class='status-indicator status-warning'>NULL/Unset <a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
'@
        } elseif ($props.NetworkRuleSet.DefaultAction -eq "Deny") {
            @'
<span class='status-indicator status-good'>Deny</span>
'@
        } else {
            @"
<span class='status-indicator status-bad'>$($props.NetworkRuleSet.DefaultAction) <a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security' target='_blank' style='color: white; text-decoration: underline;'>📖</a></span>
"@
        }
        
        $publicNetworkAccessHtml = if ($props.PublicNetworkAccess -eq "Disabled") {
            @'
<span class='status-indicator status-good'>DISABLED</span>
'@
        } elseif ($props.PublicNetworkAccess -eq "Enabled") {
            @'
<span class='status-indicator status-bad'>ENABLED <a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security' target='_blank' style='color: white; text-decoration: underline;'>📖</a></span>
'@
        } else {
            @'
<span class='status-indicator status-warning'>NULL/Unset <a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
'@
        }
        
        $storageAccountUrl = "https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$($props.ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($props.StorageAccountName)/configuration"
        
        # Build row using here-string for proper formatting
        $row = @"
<tr>
<td><a href='$storageAccountUrl' target='_blank' style='color: #0078d4; text-decoration: none; font-weight: 600; border-bottom: 1px solid #0078d4;'>$($props.StorageAccountName)</a></td>
<td>$($props.ResourceGroupName)</td>
<td>$($props.Location)</td>
<td>$allowBlobPublicAccessHtml</td>
<td>$allowSharedKeyAccessHtml</td>
<td>$enableHttpsTrafficOnlyHtml</td>
<td>$minimumTlsVersionHtml</td>
<td>$networkRuleDefaultActionHtml</td>
<td>$publicNetworkAccessHtml</td>
</tr>
"@
        $htmlContent += $row
    }
    
    $htmlContent += "</tbody></table>"
    $htmlContent -join "`n" | Out-File -FilePath $HtmlOutput -Encoding utf8
}

function Generate-BlobServiceBestPracticesInternal {
    param (
        [Parameter(Mandatory = $true)]
        [array]$StorageAccounts,
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        [string]$HtmlOutput = "BlobServiceBestPractices.html"
    )

    # Generate table header only (no full HTML document) using here-string
    $tableHeader = @'
<table>
<thead>
<tr>
    <th>STORAGE ACCOUNT NAME</th>
    <th>RESOURCE GROUP</th>
    <th>DELETE RETENTION ENABLED</th>
    <th>DELETE RETENTION DAYS</th>
    <th>CONTAINER DELETE RETENTION ENABLED</th>
    <th>CONTAINER DELETE RETENTION DAYS</th>
    <th>VERSIONING ENABLED</th>
    <th>CHANGE FEED ENABLED</th>
    <th>RESTORE POLICY ENABLED</th>
    <th>LAST ACCESS TIME TRACKING</th>
</tr>
</thead>
<tbody>
'@
    
    # Build all HTML content in memory for better performance (avoid multiple file operations)
    $htmlContent = @()
    $htmlContent += $tableHeader
    
    foreach ($account in $StorageAccounts) {
        try {
            # Get blob service properties for each storage account
            $blobServiceProps = Get-AzStorageBlobServiceProperty -ResourceGroupName $account.ResourceGroupName -StorageAccountName $account.StorageAccountName -ErrorAction Stop
            
            # Extract properties
            $deleteRetentionEnabled = $blobServiceProps.DeleteRetentionPolicy.Enabled
            $deleteRetentionDays = $blobServiceProps.DeleteRetentionPolicy.Days
            $containerDeleteRetentionEnabled = $blobServiceProps.ContainerDeleteRetentionPolicy.Enabled
            $containerDeleteRetentionDays = $blobServiceProps.ContainerDeleteRetentionPolicy.Days
            $versioningEnabled = $blobServiceProps.IsVersioningEnabled
            $changeFeedEnabled = $blobServiceProps.ChangeFeed.Enabled
            $restorePolicyEnabled = $blobServiceProps.RestorePolicy.Enabled
            $lastAccessTimeTracking = $blobServiceProps.LastAccessTimeTrackingPolicy.Enable

            # Generate HTML for each property using here-strings for proper parsing
            $deleteRetentionHtml = if ($deleteRetentionEnabled -eq $true) { 
                @'
<span class='status-indicator status-good'>ENABLED</span>
'@ 
            } else { 
                @'
<span class='status-indicator status-bad'>DISABLED <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview' target='_blank' style='color: white; text-decoration: underline;'>📖</a></span>
'@ 
            }

            $deleteRetentionDaysHtml = if ($deleteRetentionEnabled -eq $true) {
                if ($deleteRetentionDays -ge 7) { 
                    @"
<span class='status-indicator status-good'>$deleteRetentionDays days</span>
"@ 
                }
                elseif ($deleteRetentionDays -gt 0) { 
                    @"
<span class='status-indicator status-warning'>$deleteRetentionDays days <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
"@ 
                }
                else { 
                    @"
<span class='status-indicator status-bad'>$deleteRetentionDays days <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview' target='_blank' style='color: white; text-decoration: underline;'>📖</a></span>
"@ 
                }
            } else { 
                @'
<span class='status-indicator status-warning'>N/A <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
'@ 
            }

            $containerDeleteRetentionHtml = if ($containerDeleteRetentionEnabled -eq $true) { 
                @'
<span class='status-indicator status-good'>ENABLED</span>
'@ 
            } else { 
                @'
<span class='status-indicator status-bad'>DISABLED <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview' target='_blank' style='color: white; text-decoration: underline;'>📖</a></span>
'@ 
            }

            $containerDeleteRetentionDaysHtml = if ($containerDeleteRetentionEnabled -eq $true) {
                if ($containerDeleteRetentionDays -ge 7) { 
                    @"
<span class='status-indicator status-good'>$containerDeleteRetentionDays days</span>
"@ 
                }
                elseif ($containerDeleteRetentionDays -gt 0) { 
                    @"
<span class='status-indicator status-warning'>$containerDeleteRetentionDays days <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
"@ 
                }
                else { 
                    @'
<span class='status-indicator status-warning'>Not Set <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
'@ 
                }
            } else { 
                @'
<span class='status-indicator status-warning'>N/A <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
'@ 
            }

            $versioningHtml = if ($versioningEnabled -eq $true) { 
                @'
<span class='status-indicator status-good'>ENABLED</span>
'@ 
            } else { 
                @'
<span class='status-indicator status-bad'>DISABLED <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/versioning-overview' target='_blank' style='color: white; text-decoration: underline;'>📖</a></span>
'@ 
            }

            $changeFeedHtml = if ($changeFeedEnabled -eq $true) { 
                @'
<span class='status-indicator status-good'>ENABLED</span>
'@ 
            } elseif ($null -eq $changeFeedEnabled) { 
                @'
<span class='status-indicator status-warning'>NOT SET <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-change-feed' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
'@ 
            } else { 
                @'
<span class='status-indicator status-warning'>DISABLED <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-change-feed' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
'@ 
            }

            $restorePolicyHtml = if ($restorePolicyEnabled -eq $true) { 
                @'
<span class='status-indicator status-good'>ENABLED</span>
'@ 
            } elseif ($null -eq $restorePolicyEnabled) { 
                @'
<span class='status-indicator status-warning'>NOT SET <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/point-in-time-restore-overview' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
'@ 
            } else { 
                @'
<span class='status-indicator status-warning'>DISABLED <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/point-in-time-restore-overview' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
'@ 
            }

            $lastAccessTimeTrackingHtml = if ($lastAccessTimeTracking -eq $true) { 
                @'
<span class='status-indicator status-good'>ENABLED</span>
'@ 
            } elseif ($null -eq $lastAccessTimeTracking) { 
                @'
<span class='status-indicator status-warning'>NOT SET <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
'@ 
            } else { 
                @'
<span class='status-indicator status-warning'>DISABLED <a href='https://docs.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview' target='_blank' style='color: #ffffff; text-decoration: underline;'>📖</a></span>
'@ 
            }

            # Create Azure Portal URL for storage account settings
            $storageAccountUrl = "https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$($account.ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($account.StorageAccountName)/configuration"
            
            # Build row using here-string for proper formatting
            $row = @"
<tr>
<td><a href='$storageAccountUrl' target='_blank' style='color: #0078d4; text-decoration: none; font-weight: 600; border-bottom: 1px solid #0078d4;'>$($account.StorageAccountName)</a></td>
<td>$($account.ResourceGroupName)</td>
<td>$deleteRetentionHtml</td>
<td>$deleteRetentionDaysHtml</td>
<td>$containerDeleteRetentionHtml</td>
<td>$containerDeleteRetentionDaysHtml</td>
<td>$versioningHtml</td>
<td>$changeFeedHtml</td>
<td>$restorePolicyHtml</td>
<td>$lastAccessTimeTrackingHtml</td>
</tr>
"@
            $htmlContent += $row

        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Warning "Failed to get blob service properties for storage account: $($account.StorageAccountName). Error: $errorMessage"
            
            # Create Azure Portal URL for storage account settings
            $storageAccountUrl = "https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$($account.ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($account.StorageAccountName)/configuration"
            
            # Extract error message to avoid parsing issues in here-string
            $errorMessage = $_.Exception.Message
            
            # Build error row using here-string
            $errorRow = @"
<tr>
<td><a href='$storageAccountUrl' target='_blank' style='color: #0078d4; text-decoration: none; font-weight: 600; border-bottom: 1px solid #0078d4;'>$($account.StorageAccountName)</a></td>
<td>$($account.ResourceGroupName)</td>
<td colspan='8'><span class='status-indicator status-bad'>ERROR: Unable to retrieve blob service properties - $errorMessage</span></td>
</tr>
"@
            $htmlContent += $errorRow
        }
    }

    # Close table and write all content at once (optimized file I/O)
    $htmlContent += "</tbody></table>"
    $htmlContent -join "`n" | Out-File -FilePath $HtmlOutput -Encoding utf8
}