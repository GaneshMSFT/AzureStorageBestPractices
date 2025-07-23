# Azure Storage Best Practices Analysis Script

**Author:** Ganesh Maddipudi

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

### For Azure Cloud Shell (Recommended)
- Azure PowerShell module (pre-installed in Azure Cloud Shell)
- **Reader** access to Azure subscription and storage accounts
- **Storage Account Contributor** role (for blob service properties access)

### For Local Execution
- **PowerShell 5.1** or **PowerShell 7+** (Windows, macOS, or Linux)
- **Azure PowerShell Module** (Az module)
- **Azure Account** with appropriate permissions:
  - **Reader** access to Azure subscription and storage accounts
  - **Storage Account Contributor** role (for blob service properties access)

## Installation and Setup

### Option 1: Azure Cloud Shell (Easiest - No Setup Required)

#### Step 1: Open Azure Cloud Shell
1. Go to [Azure Portal](https://portal.azure.com)
2. Click the Cloud Shell icon (>_) in the top navigation bar
3. Choose **PowerShell** (not Bash) when prompted
4. Wait for the shell to initialize

#### Step 2: Upload the Script
**Option A - Copy/Paste Method (Recommended):**
1. Copy the entire script content from `GenerateStorageBestPractices.ps1`
2. In Cloud Shell, create a new file:
   ```powershell
   nano GenerateStorageBestPractices.ps1
   ```
3. Paste the content (Ctrl+V or right-click)
4. Save and exit: `Ctrl+X`, then `Y`, then `Enter`

**Option B - Upload Method:**
1. Click the Upload/Download files icon in Cloud Shell toolbar
2. Select "Upload" and choose the script file
3. File will be uploaded to your Cloud Shell storage

#### Step 3: Set Execution Policy (if needed)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Step 4: Load the Script INTO YOUR SESSION ⚠️ CRITICAL STEP ⚠️
```powershell
. ./GenerateStorageBestPractices.ps1
```

**🚨 CRITICAL: Notice the DOT (.) followed by a SPACE before the path!**

This is called **"dot sourcing"** and is **ABSOLUTELY REQUIRED** to load the functions into your PowerShell session.

- ❌ **WRONG**: `./GenerateStorageBestPractices.ps1` (runs script but doesn't load functions)
- ❌ **WRONG**: `GenerateStorageBestPractices.ps1` (won't work at all)
- ✅ **CORRECT**: `. ./GenerateStorageBestPractices.ps1` (dot + space + path loads functions)

**Without the dot and space, you'll get the error:** `"The term 'Generate-StorageBestPracticesReport' is not recognized"`

#### Step 5: Run the Analysis (One Simple Command!)
```powershell
Generate-StorageBestPracticesReport -SubscriptionId "your-subscription-id-here"
```

**🎯 That's it! This single command will:**
- ✅ Automatically connect to your subscription
- ✅ Analyze ALL storage accounts in the subscription  
- ✅ Generate both account-level AND blob-level best practices analysis
- ✅ Create a comprehensive HTML report with both sections
- ✅ Save the report as `StorageBestPractices.html`

**📝 Note:** The script automatically handles subscription context and provides comprehensive analysis in a single command!

### Optional Parameters
You can also use optional parameters for more control:

```powershell
# Generate report with detailed execution information
Generate-StorageBestPracticesReport -SubscriptionId "your-subscription-id" -ShowDetails

# Specify custom output file name
Generate-StorageBestPracticesReport -SubscriptionId "your-subscription-id" -HtmlOutput "MyCustomReport.html"
```

#### Step 6: Download the Report
1. Click the Upload/Download files icon in Cloud Shell toolbar
2. Select "Download"
3. Type the filename: `StorageBestPractices.html`
4. The HTML file will be downloaded to your local machine

#### Step 7: View the Report
1. Open the downloaded HTML file in any web browser
2. Review the best practices analysis and take appropriate actions

### Option 2: Local Execution (Windows/macOS/Linux)

#### Prerequisites Setup

**Step 1: Install PowerShell (if not already installed)**

**Windows:**
- PowerShell 5.1 comes pre-installed with Windows 10/11
- For PowerShell 7+: Download from [PowerShell GitHub releases](https://github.com/PowerShell/PowerShell/releases)

**macOS:**
```bash
# Using Homebrew
brew install powershell

# Or download from GitHub releases
```

**Linux (Ubuntu/Debian):**
```bash
# Update package list
sudo apt update

# Install PowerShell
sudo apt install -y powershell

# Or use snap
sudo snap install powershell --classic
```

**Step 2: Install Azure PowerShell Module**

Open PowerShell as Administrator (Windows) or with sudo (Linux/macOS):

```powershell
# Install the Azure PowerShell module
Install-Module -Name Az -Repository PSGallery -Force -AllowClobber

# Verify installation
Get-Module -Name Az -ListAvailable
```

**Step 3: Connect to Azure**

```powershell
# Sign in to Azure (this will open a browser window for authentication)
Connect-AzAccount

# Verify connection
Get-AzContext

# If you have multiple subscriptions, set the correct one
Set-AzContext -SubscriptionId "your-subscription-id"
```

#### Running the Script Locally

**Step 1: Download the Script**
- Download `GenerateStorageBestPractices.ps1` to your local machine
- Place it in a folder where you want to run the analysis

**Step 2: Set Execution Policy (Windows only, if needed)**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Step 3: Navigate to Script Directory**
```powershell
# Navigate to the directory containing the script
cd "C:\path\to\your\script\directory"
```

**Step 4: Load the Script ⚠️ CRITICAL STEP ⚠️**
```powershell
. .\GenerateStorageBestPractices.ps1
```

**🚨 IMPORTANT: Notice the DOT (.) followed by a SPACE before the path!**

**Step 5: Run the Analysis**
```powershell
# Basic usage
Generate-StorageBestPracticesReport -SubscriptionId "your-subscription-id-here"

# With custom output file
Generate-StorageBestPracticesReport -SubscriptionId "your-subscription-id" -HtmlOutput "MyReport.html"

# With detailed execution information
Generate-StorageBestPracticesReport -SubscriptionId "your-subscription-id" -ShowDetails
```

**Step 6: View the Report**
- The HTML report will be created in the same directory as the script
- Open the HTML file in any web browser to view the analysis

#### Local Execution Troubleshooting

**❌ "Connect-AzAccount" command not found**
- **Solution**: Install the Azure PowerShell module: `Install-Module -Name Az -Force`

**❌ "Execution policy" errors on Windows**
- **Solution**: Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**❌ "Access denied" during module installation**
- **Solution**: Run PowerShell as Administrator (Windows) or use sudo (Linux/macOS)

**❌ Browser doesn't open for Azure login**
- **Solution**: Use device code authentication: `Connect-AzAccount -UseDeviceAuthentication`

**❌ Module version conflicts**
- **Solution**: Uninstall old modules and reinstall:
  ```powershell
  Uninstall-Module -Name AzureRM -Force
  Install-Module -Name Az -Force -AllowClobber
  ```

## Complete Examples

### Azure Cloud Shell Example
```powershell
# Set your subscription ID (replace with your actual subscription ID)
$subscriptionId = "12345678-1234-1234-1234-123456789012"

# Load the script (DOT + SPACE + PATH - Critical!)
. ./GenerateStorageBestPractices.ps1

# Generate comprehensive best practices report
Generate-StorageBestPracticesReport -SubscriptionId $subscriptionId

# Download the report file when complete
```

### Local PowerShell Example
```powershell
# Connect to Azure (if not already connected)
Connect-AzAccount

# Set your subscription ID (replace with your actual subscription ID)
$subscriptionId = "12345678-1234-1234-1234-123456789012"

# Navigate to script directory
cd "C:\path\to\script\directory"

# Load the script (DOT + SPACE + PATH - Critical!)
. .\GenerateStorageBestPractices.ps1

# Generate comprehensive best practices report
Generate-StorageBestPracticesReport -SubscriptionId $subscriptionId -ShowDetails

# The HTML report will be created in the current directory
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

### Common Issues and Solutions (All Platforms)

**❌ "The term 'Generate-StorageBestPracticesReport' is not recognized"**
- **Root Cause**: You forgot the dot sourcing step!
- **Solution**: Run `. ./GenerateStorageBestPractices.ps1` (Cloud Shell) or `. .\GenerateStorageBestPractices.ps1` (Local)
- **Explanation**: Without dot sourcing, functions are not loaded into your PowerShell session

**❌ "Access denied" errors**
- Ensure you have at least **Reader** role on the subscription
- For blob service properties, you need **Storage Account Contributor** role

**❌ No storage accounts found**
- Verify you're connected to the correct subscription: `Get-AzContext`
- Check if you have the correct permissions

**❌ Blob service properties not accessible**
- Some storage accounts may not support all blob service features
- The script will show error messages for accounts where properties cannot be retrieved

### Azure Cloud Shell Specific Issues

**❌ "Module not found" errors**
- Azure PowerShell is pre-installed in Cloud Shell
- If needed, update with: `Install-Module -Name Az -Force -AllowClobber`

**❌ Script execution policy errors**
- Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Local Execution Specific Issues

**❌ "Connect-AzAccount" command not found**
- **Root Cause**: Azure PowerShell module not installed
- **Solution**: Install the module: `Install-Module -Name Az -Repository PSGallery -Force`

**❌ PowerShell execution policy errors (Windows)**
- **Solution**: Set execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **Alternative**: Run PowerShell as Administrator and set policy globally

**❌ "Access denied" during module installation**
- **Windows**: Run PowerShell as Administrator
- **Linux/macOS**: Use `sudo pwsh` and then install modules

**❌ Azure authentication issues**
- **Browser doesn't open**: Use `Connect-AzAccount -UseDeviceAuthentication`
- **Multiple accounts**: Use `Connect-AzAccount -TenantId "your-tenant-id"`
- **Service principal**: Use `Connect-AzAccount -ServicePrincipal -Credential $credential -TenantId "tenant-id"`

**❌ Module version conflicts**
- **Solution**: Remove old AzureRM modules:
  ```powershell
  Uninstall-Module -Name AzureRM -AllVersions -Force
  Install-Module -Name Az -Force -AllowClobber
  ```

**❌ PowerShell version compatibility**
- **Minimum required**: PowerShell 5.1 or PowerShell 7+
- **Check version**: `$PSVersionTable.PSVersion`
- **Upgrade if needed**: Download from [PowerShell GitHub](https://github.com/PowerShell/PowerShell/releases)

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
