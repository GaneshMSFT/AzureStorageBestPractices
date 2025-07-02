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
# =============================================================================
# STEP-BY-STEP INSTRUCTIONS FOR AZURE CLOUD SHELL
# =============================================================================
#
# 1. OPEN AZURE CLOUD SHELL
#    - Go to https://portal.azure.com
#    - Click the Cloud Shell icon (>_) in the top navigation bar
#    - Choose PowerShell (not Bash) when prompted
#    - Wait for the shell to initialize
#
# 2. UPLOAD THE SCRIPT TO CLOUD SHELL
#    Option A - Copy/Paste Method (Recommended):
#    - Open this script file on your local machine
#    - Select all content (Ctrl+A) and copy (Ctrl+C)
#    - In Cloud Shell, create a new file: nano StorageBestPractices.ps1
#    - Paste the content (Ctrl+V or right-click)
#    - Save and exit: Ctrl+X, then Y, then Enter
#    
#    Option B - Upload Method:
#    - Click the Upload/Download files icon in Cloud Shell toolbar
#    - Select "Upload" and choose this script file
#    - The file will be uploaded to your Cloud Shell storage
#
# 3. SET EXECUTION POLICY (if needed)
#    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#
# 4. LOAD THE SCRIPT INTO YOUR POWERSHELL SESSION ⚠️ CRITICAL STEP ⚠️
#    . ./StorageBestPractices.ps1
#    
#    ⚠️  IMPORTANT: Notice the DOT (.) followed by a SPACE before the path!
#    This is called "dot sourcing" and is REQUIRED to load functions into your session.
#    
#    ❌ WRONG: ./StorageBestPractices.ps1        (runs script but doesn't load functions)
#    ❌ WRONG: StorageBestPractices.ps1          (won't work)
#    ✅ CORRECT: . ./StorageBestPractices.ps1    (dot + space + path loads functions)
#    
#    Without the dot and space, the functions won't be available in your session!
#
# 5. RUN THE ANALYSIS (One simple command!)
#    Generate-StorageBestPracticesReport -SubscriptionId "your-subscription-id-here"
#
#    This single command will:
#    ✅ Automatically connect to your subscription
#    ✅ Analyze ALL storage accounts in the subscription  
#    ✅ Generate both account-level AND blob-level best practices analysis
#    ✅ Create a comprehensive HTML report with both sections
#
#    NOTE: The script will automatically connect to the specified subscription. 
#    
#
# 6. DOWNLOAD THE REPORT
#    - Click the Upload/Download files icon in Cloud Shell toolbar
#    - Select "Download" 
#    - Type the filename: StorageBestPractices.html
#    - The HTML file will be downloaded to your local machine
#
# 7. VIEW THE REPORT
#    - Open the downloaded HTML file in any web browser
#    - Review the color-coded best practices analysis:
#      * Green = Best Practice/Compliant
#      * Red = Not Following Best Practice/Needs Attention  
#      * Orange = Review Required/Optional
#
# =============================================================================
# EXAMPLE COMMANDS FOR QUICK START
# =============================================================================
#
# # Complete example - Just provide your subscription ID:
# . ./StorageBestPractices.ps1                    ⚠️ DOT + SPACE + PATH (Critical!)
# Generate-StorageBestPracticesReport -SubscriptionId "YOUR-SUBSCRIPTION-ID"
#
# =============================================================================
# TROUBLESHOOTING
# =============================================================================
#
# Issue: "The term 'Generate-CombinedStorageBestPractices' is not recognized" 
# Solution: You forgot the DOT SOURCING! Run: . ./StorageBestPractices.ps1
#          The DOT (.) + SPACE before the path is MANDATORY to load functions.
#          Without it, functions are not loaded into your PowerShell session.
#
# Issue: "Access denied" errors
# Solution: Ensure you have at least Reader role on the subscription and 
#          Storage Account Contributor role for blob service properties
#
# Issue: "Module not found" errors  
# Solution: Azure PowerShell is pre-installed in Cloud Shell, but you can
#          update it with: Install-Module -Name Az -Force -AllowClobber
#
# Issue: Script execution policy errors
# Solution: Run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#
# Issue: No storage accounts found
# Solution: Verify you're connected to the correct subscription with Get-AzContext
#
# =============================================================================
# VERIFICATION COMMANDS - Run these to check if script loaded correctly
# =============================================================================
#
# 1. Check if script file exists in current directory:
#    Get-ChildItem *.ps1
#
# 2. ⚠️ LOAD THE SCRIPT (DOT SOURCING - CRITICAL!) ⚠️
#    . ./StorageBestPractices.ps1
#    
#    The DOT (.) + SPACE is MANDATORY! This loads functions into your session.
#    Without it, you'll get "command not recognized" errors.
#
# 3. Verify functions are loaded:
#    Get-Command Generate-*
#    
#    You should see three functions listed. If not, repeat step 2.
#
# =============================================================================

# Test function to verify script is loaded correctly
function Test-ScriptLoaded {
    Write-Host "✅ Script loaded successfully!" -ForegroundColor Green
    Write-Host "Main function to use:" -ForegroundColor Cyan
    Write-Host "  Generate-StorageBestPracticesReport -SubscriptionId 'your-subscription-id'" -ForegroundColor White
    Write-Host ""
    Write-Host "All available functions:" -ForegroundColor Yellow
    $functions = Get-Command Generate-* -ErrorAction SilentlyContinue
    if ($functions) {
        $functions | Select-Object Name | Format-Table -AutoSize
        Write-Host "🎉 All functions are ready to use!" -ForegroundColor Green
        Write-Host "💡 For most users, just use: Generate-StorageBestPracticesReport" -ForegroundColor Cyan
    } else {
        Write-Host "❌ No functions found! Did you forget dot sourcing?" -ForegroundColor Red
        Write-Host "💡 Run: . ./StorageBestPractices.ps1 (note the DOT + SPACE)" -ForegroundColor Yellow
    }
}

# Helper function to set subscription context and validate access
function Set-SubscriptionContext {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId
    )
    
    Write-Host "Setting subscription context to: $SubscriptionId" -ForegroundColor Cyan
    try {
        Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null
        Write-Host "✅ Successfully connected to subscription: $SubscriptionId" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "❌ Failed to set subscription context: $($_.Exception.Message)"
        return $false
    }
}

# Helper function to get and validate storage accounts
function Get-ValidatedStorageAccounts {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId
    )
    
    Write-Host "Retrieving storage accounts from subscription..." -ForegroundColor Cyan
    $storageAccounts = Get-AzStorageAccount
    
    if ($storageAccounts.Count -eq 0) {
        Write-Warning "No storage accounts found in subscription: $SubscriptionId"
        Write-Host "Please verify:" -ForegroundColor Yellow
        Write-Host "  1. You have access to this subscription" -ForegroundColor Yellow
        Write-Host "  2. There are storage accounts in this subscription" -ForegroundColor Yellow
        Write-Host "  3. You have at least Reader permissions" -ForegroundColor Yellow
        return $null
    }
    
    Write-Host "Found $($storageAccounts.Count) storage account(s) to analyze" -ForegroundColor Green
    return $storageAccounts
}

# Helper function to get color styling variables
function Get-ColorStyles {
    return @{
        Green  = "style='color: #90EE90; font-weight: bold;'"
        Red    = "style='color: #FF4C4C; font-weight: bold;'"
        Orange = "style='color: #FFD700; font-weight: bold;'"
    }
}

# Main function - This is what users should call
function Generate-StorageBestPracticesReport {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        [string]$HtmlOutput = "StorageBestPractices.html"
    )

    # Start timer to measure execution efficiency
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $startTime = Get-Date
    
    Write-Host "🔄 Generating comprehensive Azure Storage Best Practices Report..." -ForegroundColor Cyan
    Write-Host "📋 This report includes both Storage Account and Blob Service best practices analysis" -ForegroundColor Cyan
    Write-Host "⏱️  Started at: $($startTime.ToString('yyyy-MM-dd HH:mm:ss')) (Local Time)" -ForegroundColor Gray
    
    # Use the existing combined function
    Generate-CombinedStorageBestPractices -SubscriptionId $SubscriptionId -HtmlOutput $HtmlOutput
    
    # Stop timer and display results
    $stopwatch.Stop()
    $endTime = Get-Date
    $elapsed = $stopwatch.Elapsed
    
    Write-Host ""
    Write-Host "⏱️  EXECUTION COMPLETED!" -ForegroundColor Green
    Write-Host "📅 Started:  $($startTime.ToString('yyyy-MM-dd HH:mm:ss')) (Local Time)" -ForegroundColor Yellow
    Write-Host "📅 Finished: $($endTime.ToString('yyyy-MM-dd HH:mm:ss')) (Local Time)" -ForegroundColor Yellow
    Write-Host "📊 Total execution time: $($elapsed.Minutes):$($elapsed.Seconds.ToString('00')):$($elapsed.Milliseconds.ToString('000'))" -ForegroundColor Cyan
    Write-Host "⚡ Script efficiency: Analyzed all storage accounts in $($elapsed.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Cyan
    if ($elapsed.TotalMinutes -lt 1) {
        Write-Host "🚀 Excellent performance! Completed in under 1 minute." -ForegroundColor Green
    } elseif ($elapsed.TotalMinutes -lt 3) {
        Write-Host "✅ Good performance! Completed in under 3 minutes." -ForegroundColor Green
    } else {
        Write-Host "📈 Analysis completed. Large subscription scanned efficiently." -ForegroundColor Yellow
    }
}

# Internal helper functions (users don't need to call these directly)
function Generate-StorageAccountBestPractices {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        [string]$HtmlOutput = "StorageAccountBestPractices.html"
    )

    # Set subscription context and validate
    if (-not (Set-SubscriptionContext -SubscriptionId $SubscriptionId)) { return }
    
    # Get and validate storage accounts
    $storageAccounts = Get-ValidatedStorageAccounts -SubscriptionId $SubscriptionId
    if (-not $storageAccounts) { return }

    # Table header
    $header = @"
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
"@
    $header | Out-File -FilePath $HtmlOutput -Encoding utf8

    foreach ($account in $storageAccounts) {
        # Get detailed storage account information
        $detailedAccount = Get-AzStorageAccount -ResourceGroupName $account.ResourceGroupName -Name $account.StorageAccountName
        $props = $detailedAccount

        # Extract properties - try different property paths
        $allowBlobPublicAccess   = $props.AllowBlobPublicAccess
        $allowSharedKeyAccess    = $props.AllowSharedKeyAccess
        $enableHttpsTrafficOnly  = $props.EnableHttpsTrafficOnly
        $minimumTlsVersion       = $props.MinimumTlsVersion
        $networkRuleDefaultAction= $props.NetworkRuleSet.DefaultAction
        $publicNetworkAccess     = $props.PublicNetworkAccess

        # allowBlobPublicAccess: false is best practice
        $allowBlobPublicAccessHtml = if ($allowBlobPublicAccess -eq $false) {
            "<span class='status-indicator status-good'>FALSE (Best Practice)</span>"
        } else {
            "<span class='status-indicator status-bad'>TRUE (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-prevent' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
        }

        # allowSharedKeyAccess: false is best practice
        $allowSharedKeyAccessHtml = if ($allowSharedKeyAccess -eq $false) {
            "<span class='status-indicator status-good'>FALSE (Best Practice)</span>"
        } elseif ($allowSharedKeyAccess -eq $true) {
            "<span class='status-indicator status-bad'>TRUE (<a href='https://docs.microsoft.com/en-us/azure/storage/common/shared-key-authorization-prevent' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
        } else {
            "<span class='status-indicator status-warning'>NULL/Unset (<a href='https://docs.microsoft.com/en-us/azure/storage/common/shared-key-authorization-prevent' target='_blank' style='color: #8b4513; text-decoration: underline;'>Configuration Guide</a>)</span>"
        }

        # enableHttpsTrafficOnly: true is best practice
        $enableHttpsTrafficOnlyHtml = if ($enableHttpsTrafficOnly -eq $true) {
            "<span class='status-indicator status-good'>TRUE (Best Practice)</span>"
        } else {
            "<span class='status-indicator status-bad'>FALSE (<a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-require-secure-transfer' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
        }

        # minimumTlsVersion: TLS1_2 or higher is best practice
        $minimumTlsVersionHtml = if ($null -eq $minimumTlsVersion) {
            "<span class='status-indicator status-warning'>NULL/Unset (<a href='https://docs.microsoft.com/en-us/azure/storage/common/transport-layer-security-configure-minimum-version' target='_blank' style='color: #8b4513; text-decoration: underline;'>Configuration Guide</a>)</span>"
        } elseif ($minimumTlsVersion -eq "TLS1_2" -or $minimumTlsVersion -eq "TLS1_3") {
            "<span class='status-indicator status-good'>$minimumTlsVersion (Best Practice)</span>"
        } else {
            "<span class='status-indicator status-bad'>$minimumTlsVersion (<a href='https://docs.microsoft.com/en-us/azure/storage/common/transport-layer-security-configure-minimum-version' target='_blank' style='color: white; text-decoration: underline;'>Upgrade Guide</a>)</span>"
        }

        # networkRuleSet.defaultAction: Deny is best practice
        $networkRuleDefaultActionHtml = if ($null -eq $networkRuleDefaultAction) {
            "<span class='status-indicator status-warning'>NULL/Unset (<a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security' target='_blank' style='color: #8b4513; text-decoration: underline;'>Configuration Guide</a>)</span>"
        } elseif ($networkRuleDefaultAction -eq "Deny") {
            "<span class='status-indicator status-good'>Deny (Best Practice)</span>"
        } else {
            "<span class='status-indicator status-bad'>$networkRuleDefaultAction (<a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
        }

        # publicNetworkAccess: Disabled is best practice
        $publicNetworkAccessHtml = if ($publicNetworkAccess -eq "Disabled") {
            "<span class='status-indicator status-good'>Disabled (Best Practice)</span>"
        } elseif ($publicNetworkAccess -eq "Enabled") {
            "<span class='status-indicator status-bad'>Enabled (<a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
        } else {
            "<span class='status-indicator status-warning'>NULL/Unset (<a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security' target='_blank' style='color: #8b4513; text-decoration: underline;'>Configuration Guide</a>)</span>"
        }

        # Create Azure Portal URL for storage account settings
        $storageAccountUrl = "https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$($account.ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($account.StorageAccountName)/configuration"
        
        # Output table row
        $row = "<tr>
<td><a href='$storageAccountUrl' target='_blank' style='color: #0078d4; text-decoration: none; font-weight: 600; border-bottom: 1px solid #0078d4;'>$($account.StorageAccountName)</a></td>
<td>$($account.ResourceGroupName)</td>
<td>$($account.Location)</td>
<td>$allowBlobPublicAccessHtml</td>
<td>$allowSharedKeyAccessHtml</td>
<td>$enableHttpsTrafficOnlyHtml</td>
<td>$minimumTlsVersionHtml</td>
<td>$networkRuleDefaultActionHtml</td>
<td>$publicNetworkAccessHtml</td>
</tr>"
        $row | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
    }

    # Close table
    "</tbody></table>" | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
    Write-Host "Storage account best practices analysis written to $HtmlOutput"
}

function Generate-BlobServiceBestPractices {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        [string]$HtmlOutput = "BlobServiceBestPractices.html"
    )

    # Set subscription context and validate
    if (-not (Set-SubscriptionContext -SubscriptionId $SubscriptionId)) { return }
    
    # Get and validate storage accounts
    $storageAccounts = Get-ValidatedStorageAccounts -SubscriptionId $SubscriptionId
    if (-not $storageAccounts) { return }

    # HTML document start and styles
    $htmlStart = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Blob Service Best Practices Analysis</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
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
        
        .stats-overview {
            display: flex;
            justify-content: space-around;
            margin-bottom: 30px;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 12px;
            text-align: center;
            min-width: 150px;
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 24px rgba(0, 0, 0, 0.2);
        }
        
        .stat-number {
            font-size: 2em;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 0.9em;
            opacity: 0.9;
        }
        
        .table-container {
            overflow-x: auto;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            margin-top: 30px;
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
        
        /* Status indicators with enhanced styling */
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
            background: linear-gradient(135deg, #56ab2f 0%, #a8e6cf 100%);
            color: #2d5016;
            box-shadow: 0 4px 8px rgba(86, 171, 47, 0.3);
        }
        
        .status-bad {
            background: linear-gradient(135deg, #ff416c 0%, #ff4b2b 100%);
            color: white;
            box-shadow: 0 4px 8px rgba(255, 65, 108, 0.3);
        }
        
        .status-warning {
            background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%);
            color: #8b4513;
            box-shadow: 0 4px 8px rgba(255, 193, 7, 0.3);
        }
        
        /* Legend */
        .legend {
            display: flex;
            justify-content: center;
            gap: 30px;
            margin-bottom: 30px;
            flex-wrap: wrap;
        }
        
        .legend-item {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .legend-color {
            width: 20px;
            height: 20px;
            border-radius: 50%;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
        }
        
        .legend-good { background: linear-gradient(135deg, #56ab2f 0%, #a8e6cf 100%); }
        .legend-bad { background: linear-gradient(135deg, #ff416c 0%, #ff4b2b 100%); }
        .legend-warning { background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%); }
        
        /* Responsive design */
        @media (max-width: 768px) {
            .container { padding: 20px; }
            h1 { font-size: 2em; }
            th, td { padding: 12px 8px; font-size: 0.8em; }
            .stats-overview { flex-direction: column; align-items: center; }
            .legend { flex-direction: column; align-items: center; }
        }
        
        /* Storage Account Link Styling */
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
        
        /* Documentation Link Styling */
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
            color: #8b4513 !important;
        }
        
        /* Print styles */
        @media print {
            body { background: white; }
            .container { box-shadow: none; }
            .stat-card { break-inside: avoid; }
            table { break-inside: avoid; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Azure Blob Service Best Practices Analysis</h1>
        
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
        
        <div class="table-container">
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
"@
    $htmlStart | Out-File -FilePath $HtmlOutput -Encoding utf8

    foreach ($account in $storageAccounts) {
        try {
            # Get blob service properties for each storage account
            $blobServiceProps = Get-AzStorageBlobServiceProperty -ResourceGroupName $account.ResourceGroupName -StorageAccountName $account.StorageAccountName
            
            # Extract properties
            $deleteRetentionEnabled = $blobServiceProps.DeleteRetentionPolicy.Enabled
            $deleteRetentionDays = $blobServiceProps.DeleteRetentionPolicy.Days
            $containerDeleteRetentionEnabled = $blobServiceProps.ContainerDeleteRetentionPolicy.Enabled
            $containerDeleteRetentionDays = $blobServiceProps.ContainerDeleteRetentionPolicy.Days
            $versioningEnabled = $blobServiceProps.IsVersioningEnabled
            $changeFeedEnabled = $blobServiceProps.ChangeFeed.Enabled
            $restorePolicyEnabled = $blobServiceProps.RestorePolicy.Enabled
            $lastAccessTimeTracking = $blobServiceProps.LastAccessTimeTrackingPolicy.Enable

            # Delete Retention Policy: enabled is best practice
            $deleteRetentionHtml = if ($deleteRetentionEnabled -eq $true) {
                "<span class='status-indicator status-good'>ENABLED (Best Practice)</span>"
            } else {
                "<span class='status-indicator status-bad'>DISABLED (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
            }

            # Delete Retention Days: 7+ days is recommended
            $deleteRetentionDaysHtml = if ($deleteRetentionEnabled -eq $true) {
                if ($deleteRetentionDays -ge 7) {
                    "<span class='status-indicator status-good'>$deleteRetentionDays days (Best Practice)</span>"
                } elseif ($deleteRetentionDays -gt 0) {
                    "<span class='status-indicator status-warning'>$deleteRetentionDays days (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Consider 7+ days</a>)</span>"
                } else {
                    "<span class='status-indicator status-bad'>$deleteRetentionDays days (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview' target='_blank' style='color: white; text-decoration: underline;'>Too Low - Fix Guide</a>)</span>"
                }
            } else {
                "<span class='status-indicator status-warning'>N/A (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Retention Disabled - Enable Guide</a>)</span>"
            }

            # Container Delete Retention: enabled is best practice
            $containerDeleteRetentionHtml = if ($containerDeleteRetentionEnabled -eq $true) {
                "<span class='status-indicator status-good'>ENABLED (Best Practice)</span>"
            } else {
                "<span class='status-indicator status-bad'>DISABLED (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
            }

            # Container Delete Retention Days
            $containerDeleteRetentionDaysHtml = if ($containerDeleteRetentionEnabled -eq $true) {
                if ($containerDeleteRetentionDays -ge 7) {
                    "<span class='status-indicator status-good'>$containerDeleteRetentionDays days (Best Practice)</span>"
                } elseif ($containerDeleteRetentionDays -gt 0) {
                    "<span class='status-indicator status-warning'>$containerDeleteRetentionDays days (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Consider 7+ days</a>)</span>"
                } else {
                    "<span class='status-indicator status-warning'>Not Set (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Configuration Guide</a>)</span>"
                }
            } else {
                "<span class='status-indicator status-warning'>N/A (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Retention Disabled - Enable Guide</a>)</span>"
            }

            # Versioning: enabled is best practice
            $versioningHtml = if ($versioningEnabled -eq $true) {
                "<span class='status-indicator status-good'>ENABLED (Best Practice)</span>"
            } else {
                "<span class='status-indicator status-bad'>DISABLED (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/versioning-overview' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
            }

            # Change Feed: enabled is recommended for audit trails
            $changeFeedHtml = if ($changeFeedEnabled -eq $true) {
                "<span class='status-indicator status-good'>ENABLED (Best Practice)</span>"
            } elseif ($null -eq $changeFeedEnabled) {
                "<span class='status-indicator status-warning'>NOT SET (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-change-feed' target='_blank' style='color: #8b4513; text-decoration: underline;'>Consider Enabling - Guide</a>)</span>"
            } else {
                "<span class='status-indicator status-warning'>DISABLED (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-change-feed' target='_blank' style='color: #8b4513; text-decoration: underline;'>Consider Enabling - Guide</a>)</span>"
            }

            # Restore Policy: enabled is recommended for critical data
            $restorePolicyHtml = if ($restorePolicyEnabled -eq $true) {
                "<span class='status-indicator status-good'>ENABLED (Best Practice)</span>"
            } elseif ($null -eq $restorePolicyEnabled) {
                "<span class='status-indicator status-warning'>NOT SET (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/point-in-time-restore-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Consider for Critical Data - Guide</a>)</span>"
            } else {
                "<span class='status-indicator status-warning'>DISABLED (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/point-in-time-restore-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Consider for Critical Data - Guide</a>)</span>"
            }

            # Last Access Time Tracking: optional but useful for lifecycle management
            $lastAccessTimeTrackingHtml = if ($lastAccessTimeTracking -eq $true) {
                "<span class='status-indicator status-good'>ENABLED (Good for Lifecycle Management)</span>"
            } elseif ($null -eq $lastAccessTimeTracking) {
                "<span class='status-indicator status-warning'>NOT SET (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Optional - Lifecycle Guide</a>)</span>"
            } else {
                "<span class='status-indicator status-warning'>DISABLED (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Optional - Lifecycle Guide</a>)</span>"
            }

            # Create Azure Portal URL for storage account settings
            $storageAccountUrl = "https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$($account.ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($account.StorageAccountName)/configuration"
            
            # Output table row
            $row = "<tr>
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
</tr>"
            $row | Out-File -FilePath $HtmlOutput -Append -Encoding utf8

        } catch {
            Write-Warning "Failed to get blob service properties for storage account: $($account.StorageAccountName). Error: $($_.Exception.Message)"
            
            # Create Azure Portal URL for storage account settings
            $storageAccountUrl = "https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$($account.ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($account.StorageAccountName)/configuration"
            
            # Output error row
            $errorRow = "<tr>
<td><a href='$storageAccountUrl' target='_blank' style='color: #0078d4; text-decoration: none; font-weight: 600; border-bottom: 1px solid #0078d4;'>$($account.StorageAccountName)</a></td>
<td>$($account.ResourceGroupName)</td>
<td colspan='8'><span class='status-indicator status-bad'>ERROR: Unable to retrieve blob service properties - $($_.Exception.Message)</span></td>
</tr>"
            $errorRow | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
        }
    }

    # Close HTML
    $htmlEnd = @"
            </tbody>
            </table>
        </div>
    </div>
</body>
</html>
"@
    $htmlEnd | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
    Write-Host "Blob service best practices analysis written to $HtmlOutput"
}

function Generate-CombinedStorageBestPractices {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        [string]$HtmlOutput = "CombinedStorageBestPractices.html"
    )

    Write-Host "🔄 Generating combined storage best practices analysis..." -ForegroundColor Cyan

    # Set subscription context and validate ONCE for the entire operation
    if (-not (Set-SubscriptionContext -SubscriptionId $SubscriptionId)) { return }
    
    # Get and validate storage accounts ONCE for the entire operation
    $storageAccounts = Get-ValidatedStorageAccounts -SubscriptionId $SubscriptionId
    if (-not $storageAccounts) { return }

    # HTML document start and styles
    $htmlStart = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Storage Best Practices Analysis</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
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
        
        .legend-good { background: linear-gradient(135deg, #56ab2f 0%, #a8e6cf 100%); }
        .legend-bad { background: linear-gradient(135deg, #ff416c 0%, #ff4b2b 100%); }
        .legend-warning { background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%); }
        
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
        
        /* Status indicators with enhanced styling */
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
            background: linear-gradient(135deg, #56ab2f 0%, #a8e6cf 100%);
            color: #2d5016;
            box-shadow: 0 4px 8px rgba(86, 171, 47, 0.3);
        }
        
        .status-bad {
            background: linear-gradient(135deg, #ff416c 0%, #ff4b2b 100%);
            color: white;
            box-shadow: 0 4px 8px rgba(255, 65, 108, 0.3);
        }
        
        .status-warning {
            background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%);
            color: #8b4513;
            box-shadow: 0 4px 8px rgba(255, 193, 7, 0.3);
        }
        
        /* Responsive design */
        @media (max-width: 768px) {
            .container { padding: 20px; }
            h1 { font-size: 2em; }
            h2 { font-size: 1.5em; }
            th, td { padding: 12px 8px; font-size: 0.8em; }
            .legend { flex-direction: column; align-items: center; }
        }
        
        /* Storage Account Link Styling */
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
        
        /* Documentation Link Styling */
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
            color: #8b4513 !important;
        }
        
        /* Print styles */
        @media print {
            body { background: white; }
            .container { box-shadow: none; }
            .section { break-inside: avoid; }
            table { break-inside: avoid; }
        }
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
    $tempAccountFile = "temp_account_bestpractices.html"
    Generate-StorageAccountBestPracticesInternal -StorageAccounts $storageAccounts -SubscriptionId $SubscriptionId -HtmlOutput $tempAccountFile
    
    # Read and append the table content
    $accountContent = Get-Content $tempAccountFile -Raw
    $tableMatch = [regex]::Match($accountContent, '<table>.*?</table>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($tableMatch.Success) {
        $tableMatch.Value | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
    }
    Remove-Item $tempAccountFile -ErrorAction SilentlyContinue
    
    "</div></div>" | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
    
    # Add Blob Service section
    "<div class='section'><h2>Blob Service Level Best Practices</h2><div class='table-container'>" | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
    
    # Generate blob service recommendations using pre-retrieved accounts (no redundant calls)
    $tempBlobFile = "temp_blob_bestpractices.html"
    Generate-BlobServiceBestPracticesInternal -StorageAccounts $storageAccounts -SubscriptionId $SubscriptionId -HtmlOutput $tempBlobFile
    
    # Read and append the table content
    $blobContent = Get-Content $tempBlobFile -Raw
    $blobTableMatch = [regex]::Match($blobContent, '<table>.*?</table>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($blobTableMatch.Success) {
        $blobTableMatch.Value | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
    }
    Remove-Item $tempBlobFile -ErrorAction SilentlyContinue
    
    # Close HTML
    "</div></div></div></body></html>" | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
    
    Write-Host "🎉 Combined storage best practices analysis written to $HtmlOutput" -ForegroundColor Green
    Write-Host "📁 File location: $(Get-Location)\$HtmlOutput" -ForegroundColor Yellow
}

# Internal helper functions that work with pre-retrieved storage accounts (no redundant calls)
function Generate-StorageAccountBestPracticesInternal {
    param (
        [Parameter(Mandatory=$true)]
        [array]$StorageAccounts,
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        [string]$HtmlOutput = "StorageAccountBestPractices.html"
    )

    # Table header
    $header = @"
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
"@
    $header | Out-File -FilePath $HtmlOutput -Encoding utf8

    foreach ($account in $StorageAccounts) {
        # Get detailed storage account information
        $detailedAccount = Get-AzStorageAccount -ResourceGroupName $account.ResourceGroupName -Name $account.StorageAccountName
        $props = $detailedAccount

        # Extract properties - try different property paths
        $allowBlobPublicAccess   = $props.AllowBlobPublicAccess
        $allowSharedKeyAccess    = $props.AllowSharedKeyAccess
        $enableHttpsTrafficOnly  = $props.EnableHttpsTrafficOnly
        $minimumTlsVersion       = $props.MinimumTlsVersion
        $networkRuleDefaultAction= $props.NetworkRuleSet.DefaultAction
        $publicNetworkAccess     = $props.PublicNetworkAccess

        # allowBlobPublicAccess: false is best practice
        $allowBlobPublicAccessHtml = if ($allowBlobPublicAccess -eq $false) {
            "<span class='status-indicator status-good'>FALSE (Best Practice)</span>"
        } else {
            "<span class='status-indicator status-bad'>TRUE (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-prevent' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
        }

        # allowSharedKeyAccess: false is best practice
        $allowSharedKeyAccessHtml = if ($allowSharedKeyAccess -eq $false) {
            "<span class='status-indicator status-good'>FALSE (Best Practice)</span>"
        } elseif ($allowSharedKeyAccess -eq $true) {
            "<span class='status-indicator status-bad'>TRUE (<a href='https://docs.microsoft.com/en-us/azure/storage/common/shared-key-authorization-prevent' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
        } else {
            "<span class='status-indicator status-warning'>NULL/Unset (<a href='https://docs.microsoft.com/en-us/azure/storage/common/shared-key-authorization-prevent' target='_blank' style='color: #8b4513; text-decoration: underline;'>Configuration Guide</a>)</span>"
        }

        # enableHttpsTrafficOnly: true is best practice
        $enableHttpsTrafficOnlyHtml = if ($enableHttpsTrafficOnly -eq $true) {
            "<span class='status-indicator status-good'>TRUE (Best Practice)</span>"
        } else {
            "<span class='status-indicator status-bad'>FALSE (<a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-require-secure-transfer' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
        }

        # minimumTlsVersion: TLS1_2 or higher is best practice
        $minimumTlsVersionHtml = if ($null -eq $minimumTlsVersion) {
            "<span class='status-indicator status-warning'>NULL/Unset (<a href='https://docs.microsoft.com/en-us/azure/storage/common/transport-layer-security-configure-minimum-version' target='_blank' style='color: #8b4513; text-decoration: underline;'>Configuration Guide</a>)</span>"
        } elseif ($minimumTlsVersion -eq "TLS1_2" -or $minimumTlsVersion -eq "TLS1_3") {
            "<span class='status-indicator status-good'>$minimumTlsVersion (Best Practice)</span>"
        } else {
            "<span class='status-indicator status-bad'>$minimumTlsVersion (<a href='https://docs.microsoft.com/en-us/azure/storage/common/transport-layer-security-configure-minimum-version' target='_blank' style='color: white; text-decoration: underline;'>Upgrade Guide</a>)</span>"
        }

        # networkRuleSet.defaultAction: Deny is best practice
        $networkRuleDefaultActionHtml = if ($null -eq $networkRuleDefaultAction) {
            "<span class='status-indicator status-warning'>NULL/Unset (<a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security' target='_blank' style='color: #8b4513; text-decoration: underline;'>Configuration Guide</a>)</span>"
        } elseif ($networkRuleDefaultAction -eq "Deny") {
            "<span class='status-indicator status-good'>Deny (Best Practice)</span>"
        } else {
            "<span class='status-indicator status-bad'>$networkRuleDefaultAction (<a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
        }

        # publicNetworkAccess: Disabled is best practice
        $publicNetworkAccessHtml = if ($publicNetworkAccess -eq "Disabled") {
            "<span class='status-indicator status-good'>Disabled (Best Practice)</span>"
        } elseif ($publicNetworkAccess -eq "Enabled") {
            "<span class='status-indicator status-bad'>Enabled (<a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
        } else {
            "<span class='status-indicator status-warning'>NULL/Unset (<a href='https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security' target='_blank' style='color: #8b4513; text-decoration: underline;'>Configuration Guide</a>)</span>"
        }

        # Create Azure Portal URL for storage account settings
        $storageAccountUrl = "https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$($account.ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($account.StorageAccountName)/configuration"
        
        # Output table row
        $row = "<tr>
<td><a href='$storageAccountUrl' target='_blank' style='color: #0078d4; text-decoration: none; font-weight: 600; border-bottom: 1px solid #0078d4;'>$($account.StorageAccountName)</a></td>
<td>$($account.ResourceGroupName)</td>
<td>$($account.Location)</td>
<td>$allowBlobPublicAccessHtml</td>
<td>$allowSharedKeyAccessHtml</td>
<td>$enableHttpsTrafficOnlyHtml</td>
<td>$minimumTlsVersionHtml</td>
<td>$networkRuleDefaultActionHtml</td>
<td>$publicNetworkAccessHtml</td>
</tr>"
        $row | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
    }

    # Close table
    "</tbody></table>" | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
}

function Generate-BlobServiceBestPracticesInternal {
    param (
        [Parameter(Mandatory=$true)]
        [array]$StorageAccounts,
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        [string]$HtmlOutput = "BlobServiceBestPractices.html"
    )

    # Generate table header only (no full HTML document)
    $tableHeader = @"
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
"@
    $tableHeader | Out-File -FilePath $HtmlOutput -Encoding utf8

    foreach ($account in $StorageAccounts) {
        try {
            # Get blob service properties for each storage account
            $blobServiceProps = Get-AzStorageBlobServiceProperty -ResourceGroupName $account.ResourceGroupName -StorageAccountName $account.StorageAccountName
            
            # Extract properties
            $deleteRetentionEnabled = $blobServiceProps.DeleteRetentionPolicy.Enabled
            $deleteRetentionDays = $blobServiceProps.DeleteRetentionPolicy.Days
            $containerDeleteRetentionEnabled = $blobServiceProps.ContainerDeleteRetentionPolicy.Enabled
            $containerDeleteRetentionDays = $blobServiceProps.ContainerDeleteRetentionPolicy.Days
            $versioningEnabled = $blobServiceProps.IsVersioningEnabled
            $changeFeedEnabled = $blobServiceProps.ChangeFeed.Enabled
            $restorePolicyEnabled = $blobServiceProps.RestorePolicy.Enabled
            $lastAccessTimeTracking = $blobServiceProps.LastAccessTimeTrackingPolicy.Enable

            # Delete Retention Policy: enabled is best practice
            $deleteRetentionHtml = if ($deleteRetentionEnabled -eq $true) {
                "<span class='status-indicator status-good'>ENABLED (Best Practice)</span>"
            } else {
                "<span class='status-indicator status-bad'>DISABLED (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
            }

            # Delete Retention Days: 7+ days is recommended
            $deleteRetentionDaysHtml = if ($deleteRetentionEnabled -eq $true) {
                if ($deleteRetentionDays -ge 7) {
                    "<span class='status-indicator status-good'>$deleteRetentionDays days (Best Practice)</span>"
                } elseif ($deleteRetentionDays -gt 0) {
                    "<span class='status-indicator status-warning'>$deleteRetentionDays days (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Consider 7+ days</a>)</span>"
                } else {
                    "<span class='status-indicator status-bad'>$deleteRetentionDays days (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview' target='_blank' style='color: white; text-decoration: underline;'>Too Low - Fix Guide</a>)</span>"
                }
            } else {
                "<span class='status-indicator status-warning'>N/A (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Retention Disabled - Enable Guide</a>)</span>"
            }

            # Container Delete Retention: enabled is best practice
            $containerDeleteRetentionHtml = if ($containerDeleteRetentionEnabled -eq $true) {
                "<span class='status-indicator status-good'>ENABLED (Best Practice)</span>"
            } else {
                "<span class='status-indicator status-bad'>DISABLED (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
            }

            # Container Delete Retention Days
            $containerDeleteRetentionDaysHtml = if ($containerDeleteRetentionEnabled -eq $true) {
                if ($containerDeleteRetentionDays -ge 7) {
                    "<span class='status-indicator status-good'>$containerDeleteRetentionDays days (Best Practice)</span>"
                } elseif ($containerDeleteRetentionDays -gt 0) {
                    "<span class='status-indicator status-warning'>$containerDeleteRetentionDays days (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Consider 7+ days</a>)</span>"
                } else {
                    "<span class='status-indicator status-warning'>Not Set (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Configuration Guide</a>)</span>"
                }
            } else {
                "<span class='status-indicator status-warning'>N/A (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Retention Disabled - Enable Guide</a>)</span>"
            }

            # Versioning: enabled is best practice
            $versioningHtml = if ($versioningEnabled -eq $true) {
                "<span class='status-indicator status-good'>ENABLED (Best Practice)</span>"
            } else {
                "<span class='status-indicator status-bad'>DISABLED (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/versioning-overview' target='_blank' style='color: white; text-decoration: underline;'>Not Following Best Practice - Fix Guide</a>)</span>"
            }

            # Change Feed: enabled is recommended for audit trails
            $changeFeedHtml = if ($changeFeedEnabled -eq $true) {
                "<span class='status-indicator status-good'>ENABLED (Best Practice)</span>"
            } elseif ($null -eq $changeFeedEnabled) {
                "<span class='status-indicator status-warning'>NOT SET (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-change-feed' target='_blank' style='color: #8b4513; text-decoration: underline;'>Consider Enabling - Guide</a>)</span>"
            } else {
                "<span class='status-indicator status-warning'>DISABLED (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-change-feed' target='_blank' style='color: #8b4513; text-decoration: underline;'>Consider Enabling - Guide</a>)</span>"
            }

            # Restore Policy: enabled is recommended for critical data
            $restorePolicyHtml = if ($restorePolicyEnabled -eq $true) {
                "<span class='status-indicator status-good'>ENABLED (Best Practice)</span>"
            } elseif ($null -eq $restorePolicyEnabled) {
                "<span class='status-indicator status-warning'>NOT SET (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/point-in-time-restore-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Consider for Critical Data - Guide</a>)</span>"
            } else {
                "<span class='status-indicator status-warning'>DISABLED (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/point-in-time-restore-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Consider for Critical Data - Guide</a>)</span>"
            }

            # Last Access Time Tracking: optional but useful for lifecycle management
            $lastAccessTimeTrackingHtml = if ($lastAccessTimeTracking -eq $true) {
                "<span class='status-indicator status-good'>ENABLED (Good for Lifecycle Management)</span>"
            } elseif ($null -eq $lastAccessTimeTracking) {
                "<span class='status-indicator status-warning'>NOT SET (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Optional - Lifecycle Guide</a>)</span>"
            } else {
                "<span class='status-indicator status-warning'>DISABLED (<a href='https://docs.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview' target='_blank' style='color: #8b4513; text-decoration: underline;'>Optional - Lifecycle Guide</a>)</span>"
            }

            # Create Azure Portal URL for storage account settings
            $storageAccountUrl = "https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$($account.ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($account.StorageAccountName)/configuration"
            
            # Output table row
            $row = "<tr>
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
</tr>"
            $row | Out-File -FilePath $HtmlOutput -Append -Encoding utf8

        } catch {
            Write-Warning "Failed to get blob service properties for storage account: $($account.StorageAccountName). Error: $($_.Exception.Message)"
            
            # Create Azure Portal URL for storage account settings
            $storageAccountUrl = "https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$($account.ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($account.StorageAccountName)/configuration"
            
            # Output error row
            $errorRow = "<tr>
<td><a href='$storageAccountUrl' target='_blank' style='color: #0078d4; text-decoration: none; font-weight: 600; border-bottom: 1px solid #0078d4;'>$($account.StorageAccountName)</a></td>
<td>$($account.ResourceGroupName)</td>
<td colspan='8'><span class='status-indicator status-bad'>ERROR: Unable to retrieve blob service properties - $($_.Exception.Message)</span></td>
</tr>"
            $errorRow | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
        }
    }

    # Close table
    "</tbody></table>" | Out-File -FilePath $HtmlOutput -Append -Encoding utf8
}