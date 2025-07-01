# Azure Storage Best Practices Analysis Script

This PowerShell script analyzes Azure Storage Accounts and Blob Services for best practices and generates comprehensive HTML reports with color-coded analysis.

## Features

- **Storage Account Analysis**: Reviews account-level configuration against best practices
- **Blob Service Analysis**: Examines blob service configurations and data protection features
- **Combined Reporting**: Generates unified reports with both analyses
- **Color-coded Results**: 
  - 🟢 Green = Best Practice/Compliant
  - 🔴 Red = Not Following Best Practice/Needs Attention
  - 🟡 Orange = Review Required/Optional

## Requirements

- Azure PowerShell module (pre-installed in Azure Cloud Shell)
- **Reader** access to Azure subscription and storage accounts
- **Storage Account Contributor** role (for blob service properties access)

## Quick Start Guide for Azure Cloud Shell

### Step 1: Open Azure Cloud Shell
1. Go to [Azure Portal](https://portal.azure.com)
2. Click the Cloud Shell icon (>_) in the top navigation bar
3. Choose **PowerShell** (not Bash) when prompted
4. Wait for the shell to initialize

### Step 2: Upload the Script
**Option A - Copy/Paste Method (Recommended):**
1. Copy the entire script content from `StorageBestPractices.ps1`
2. In Cloud Shell, create a new file:
   ```powershell
   nano StorageBestPractices.ps1
   ```
3. Paste the content (Ctrl+V or right-click)
4. Save and exit: `Ctrl+X`, then `Y`, then `Enter`

**Option B - Upload Method:**
1. Click the Upload/Download files icon in Cloud Shell toolbar
2. Select "Upload" and choose the script file
3. File will be uploaded to your Cloud Shell storage

### Step 3: Set Execution Policy (if needed)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 4: Load the Script INTO YOUR SESSION ⚠️ CRITICAL STEP ⚠️
```powershell
. ./StorageBestPractices.ps1
```

**🚨 CRITICAL: Notice the DOT (.) followed by a SPACE before the path!**

This is called **"dot sourcing"** and is **ABSOLUTELY REQUIRED** to load the functions into your PowerShell session.

- ❌ **WRONG**: `./StorageBestPractices.ps1` (runs script but doesn't load functions)
- ❌ **WRONG**: `StorageBestPractices.ps1` (won't work at all)
- ✅ **CORRECT**: `. ./StorageBestPractices.ps1` (dot + space + path loads functions)

**Without the dot and space, you'll get the error:** `"The term 'Generate-CombinedStorageBestPractices' is not recognized"`

### Step 5: Run the Analysis (One Simple Command!)
```powershell
Generate-StorageBestPracticesReport -SubscriptionId "your-subscription-id-here"
```

**🎯 That's it! This single command will:**
- ✅ Automatically connect to your subscription
- ✅ Analyze ALL storage accounts in the subscription  
- ✅ Generate both account-level AND blob-level best practices analysis
- ✅ Create a comprehensive HTML report with both sections
- ✅ Save the report as `StorageBestPractices.html`

**📝 Note:** You no longer need to choose between different functions or manually set subscription context!

### Step 6: Download the Report
1. Click the Upload/Download files icon in Cloud Shell toolbar
2. Select "Download"
3. Type the filename: `StorageBestPractices.html`
4. The HTML file will be downloaded to your local machine

### Step 7: View the Report
1. Open the downloaded HTML file in any web browser
2. Review the best practices analysis and take appropriate actions

## Complete Example

```powershell
# Set your subscription ID (replace with your actual subscription ID)
$subscriptionId = "12345678-1234-1234-1234-123456789012"

# Load the script (DOT + SPACE + PATH - Critical!)
. ./StorageBestPractices.ps1

# Generate comprehensive best practices report (subscription context is set automatically)
Generate-StorageBestPracticesReport -SubscriptionId $subscriptionId

# Download the report file when complete
```

## What the Script Analyzes

### Storage Account Level
- Allow Blob Public Access
- Allow Shared Key Access  
- HTTPS Traffic Only
- Minimum TLS Version
- Network Rule Set Configuration
- Public Network Access

### Blob Service Level
- Delete Retention Policy
- Container Delete Retention Policy
- Blob Versioning
- Change Feed
- Point-in-Time Restore Policy
- Last Access Time Tracking

## Troubleshooting

### Common Issues and Solutions

**❌ "The term 'Generate-CombinedStorageBestPractices' is not recognized"**
- **Root Cause**: You forgot the dot sourcing step!
- **Solution**: Run `. ./StorageBestPractices.ps1` (note the DOT + SPACE before the path)
- **Explanation**: Without dot sourcing, functions are not loaded into your PowerShell session

**❌ "Access denied" errors**
- Ensure you have at least **Reader** role on the subscription
- For blob service properties, you need **Storage Account Contributor** role

**❌ "Module not found" errors**
- Azure PowerShell is pre-installed in Cloud Shell
- If needed, update with: `Install-Module -Name Az -Force -AllowClobber`

**❌ Script execution policy errors**
- Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**❌ No storage accounts found**
- Verify you're connected to the correct subscription: `Get-AzContext`
- Check if you have the correct permissions

**❌ Blob service properties not accessible**
- Some storage accounts may not support all blob service features
- The script will show error messages for accounts where properties cannot be retrieved

## Best Practices Analysis

The script evaluates configurations against these best practices:

### Storage Account Level
- ✅ Disable blob public access
- ✅ Disable shared key access (use Azure AD)
- ✅ Require HTTPS traffic only
- ✅ Use TLS 1.2 or higher
- ✅ Set network default action to "Deny"
- ✅ Disable public network access when possible

### Blob Service Level
- ✅ Enable delete retention (7+ days recommended)
- ✅ Enable container delete retention (7+ days recommended)
- ✅ Enable blob versioning for data protection
- ✅ Enable change feed for audit trails
- ✅ Consider point-in-time restore for critical data
- ✅ Consider last access time tracking for lifecycle management

## Support

For issues or questions about this script:
1. Check the troubleshooting section above
2. Verify your Azure permissions
3. Ensure you're using PowerShell (not Bash) in Cloud Shell
4. Review the Azure PowerShell documentation for storage cmdlets

## License

This script is provided as-is for educational and assessment purposes. Test in non-production environments first.
