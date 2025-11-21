# Azure Storage Custom Policy: Audit and Enable Blob Soft Delete

**Author:** Ganesh Maddipudi

This custom Azure Policy ensures that all Azure Storage Accounts have blob soft delete enabled with a configurable retention period. The policy uses a `deployIfNotExists` effect to automatically remediate non-compliant storage accounts.

## Overview

**Policy Name:** Audit and enable Blob soft delete on Storage Accounts

**Policy Type:** Custom

**Effect:** DeployIfNotExists

**Category:** Storage

## What This Policy Does

- **Audits** all Storage Accounts in scope to check if blob soft delete is enabled
- **Automatically remediates** non-compliant storage accounts by enabling soft delete
- **Configurable retention period** (default: 7 days)
- **Protects against accidental blob deletion** by retaining deleted blobs for the specified period

## Why Enable Blob Soft Delete?

Blob soft delete is a critical data protection feature that:
- ✅ Protects against accidental blob deletion
- ✅ Allows recovery of deleted blobs within the retention period
- ✅ Helps meet compliance and data governance requirements
- ✅ Provides an additional layer of data protection

## Prerequisites

- Azure subscription with appropriate permissions
- One of the following Azure RBAC roles:
  - **Owner**
  - **Resource Policy Contributor**
  - **User Access Administrator** (for policy assignment)
- Azure PowerShell module or Azure CLI installed (for deployment via script)
- OR access to Azure Portal

## Deployment Options

### Option 1: Deploy via Azure Portal (Recommended for Beginners)

#### Step 1: Create the Policy Definition

1. **Navigate to Azure Policy**
   - Open [Azure Portal](https://portal.azure.com)
   - Search for "Policy" in the top search bar
   - Click **Policy** service

2. **Create Policy Definition**
   - In the left menu, click **Definitions**
   - Click **+ Policy definition** at the top
   - Fill in the form:
     - **Definition location**: Choose your subscription or management group
     - **Name**: `audit-enable-blob-soft-delete`
     - **Description**: Copy from the policy JSON
     - **Category**: Select **Storage** (or create new)
     - **Policy rule**: Copy and paste the entire content from `AuditBlobSoftDelete.json`
   - Click **Save**

#### Step 2: Assign the Policy

1. **Create Assignment**
   - Go back to **Policy** > **Definitions**
   - Find your newly created policy `audit-enable-blob-soft-delete`
   - Click on it, then click **Assign**

2. **Configure Assignment**
   - **Basics Tab:**
     - **Scope**: Select subscription or resource group to apply the policy
     - **Exclusions**: (Optional) Exclude specific resource groups if needed
     - **Policy enforcement**: Set to **Enabled**
   
   - **Parameters Tab:**
     - **Retention days for soft delete**: Enter desired retention period (default: 7 days)
       - Recommended: 7-30 days
       - Minimum: 1 day
       - Maximum: 365 days
   
   - **Remediation Tab:**
     - ✅ Check **Create a remediation task**
     - ✅ Check **Create a Managed Identity**
     - **Managed Identity Location**: Select a region (same as your resources recommended)
   
   - **Non-compliance messages Tab:**
     - Add a custom message (optional): "Blob soft delete must be enabled with minimum retention period."
   
   - **Review + Create Tab:**
     - Review your settings
     - Click **Create**

#### Step 3: Remediate Existing Resources

1. **Navigate to Remediation**
   - Go to **Policy** > **Remediation**
   - You should see a remediation task for your policy
   - Click on the task to monitor progress

2. **Manual Remediation (if needed)**
   - Go to **Policy** > **Compliance**
   - Find your policy assignment
   - Click on it to see non-compliant resources
   - Click **Create Remediation Task** to remediate all non-compliant resources

### Option 2: Deploy via Azure PowerShell

#### Step 1: Connect to Azure

```powershell
# Connect to your Azure account
Connect-AzAccount

# Set the subscription context
Set-AzContext -SubscriptionId "<your-subscription-id>"
```

#### Step 2: Create the Policy Definition

```powershell
# Define variables
$policyName = "audit-enable-blob-soft-delete"
$policyDisplayName = "Audit and enable Blob soft delete on Storage Accounts"
$policyDescription = "Audits Storage Accounts to ensure Blob soft delete is enabled. If not, enables soft delete with a customizable retention period."
$policyFilePath = ".\AuditBlobSoftDelete.json"

# Create the policy definition
$policyDefinition = New-AzPolicyDefinition `
    -Name $policyName `
    -DisplayName $policyDisplayName `
    -Description $policyDescription `
    -Policy $policyFilePath `
    -Mode Indexed

Write-Host "Policy definition created successfully!" -ForegroundColor Green
Write-Host "Policy Definition ID: $($policyDefinition.PolicyDefinitionId)"
```

#### Step 3: Assign the Policy

```powershell
# Define assignment variables
$assignmentName = "assign-blob-soft-delete-policy"
$assignmentDisplayName = "Enforce Blob Soft Delete on Storage Accounts"
$scope = "/subscriptions/<your-subscription-id>"  # Or resource group scope
$retentionDays = 7  # Customize as needed

# Create policy assignment with managed identity
$assignment = New-AzPolicyAssignment `
    -Name $assignmentName `
    -DisplayName $assignmentDisplayName `
    -Scope $scope `
    -PolicyDefinition $policyDefinition `
    -PolicyParameterObject @{ retentionDays = $retentionDays } `
    -IdentityType "SystemAssigned" `
    -Location "eastus"  # Change to your preferred region

Write-Host "Policy assigned successfully!" -ForegroundColor Green
Write-Host "Assignment ID: $($assignment.PolicyAssignmentId)"

# Get the managed identity principal ID
$principalId = $assignment.Identity.PrincipalId
Write-Host "Managed Identity Principal ID: $principalId"
```

#### Step 4: Grant Permissions to Managed Identity

```powershell
# Wait for managed identity to propagate
Start-Sleep -Seconds 30

# Assign Storage Account Contributor role to the managed identity
New-AzRoleAssignment `
    -ObjectId $principalId `
    -RoleDefinitionName "Storage Account Contributor" `
    -Scope $scope

Write-Host "Role assignment completed!" -ForegroundColor Green
```

#### Step 5: Create Remediation Task

```powershell
# Create remediation task for existing non-compliant resources
$remediationName = "remediate-blob-soft-delete-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Start-AzPolicyRemediation `
    -Name $remediationName `
    -PolicyAssignmentId $assignment.PolicyAssignmentId `
    -Scope $scope

Write-Host "Remediation task started!" -ForegroundColor Green
Write-Host "It may take several minutes to complete."
```

### Option 3: Deploy via Azure CLI

#### Step 1: Login and Set Context

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "<your-subscription-id>"
```

#### Step 2: Create Policy Definition

```bash
# Create the policy definition
az policy definition create \
    --name "audit-enable-blob-soft-delete" \
    --display-name "Audit and enable Blob soft delete on Storage Accounts" \
    --description "Audits Storage Accounts to ensure Blob soft delete is enabled." \
    --rules AuditBlobSoftDelete.json \
    --mode Indexed

echo "Policy definition created successfully!"
```

#### Step 3: Assign the Policy

```bash
# Set variables
SUBSCRIPTION_ID="<your-subscription-id>"
SCOPE="/subscriptions/$SUBSCRIPTION_ID"
RETENTION_DAYS=7

# Create policy assignment with managed identity
az policy assignment create \
    --name "assign-blob-soft-delete-policy" \
    --display-name "Enforce Blob Soft Delete on Storage Accounts" \
    --scope "$SCOPE" \
    --policy "audit-enable-blob-soft-delete" \
    --params "{\"retentionDays\":{\"value\":$RETENTION_DAYS}}" \
    --assign-identity \
    --identity-scope "$SCOPE" \
    --location "eastus"

echo "Policy assigned successfully!"
```

#### Step 4: Get Managed Identity and Assign Role

```bash
# Get the managed identity principal ID
PRINCIPAL_ID=$(az policy assignment show \
    --name "assign-blob-soft-delete-policy" \
    --scope "$SCOPE" \
    --query "identity.principalId" -o tsv)

echo "Managed Identity Principal ID: $PRINCIPAL_ID"

# Wait for identity propagation
sleep 30

# Assign role to managed identity
az role assignment create \
    --assignee-object-id "$PRINCIPAL_ID" \
    --assignee-principal-type "ServicePrincipal" \
    --role "Storage Account Contributor" \
    --scope "$SCOPE"

echo "Role assignment completed!"
```

#### Step 5: Create Remediation Task

```bash
# Create remediation task
az policy remediation create \
    --name "remediate-blob-soft-delete-$(date +%Y%m%d-%H%M%S)" \
    --policy-assignment "assign-blob-soft-delete-policy" \
    --scope "$SCOPE"

echo "Remediation task started!"
```

## Verifying Policy Compliance

### Via Azure Portal

1. Navigate to **Policy** > **Compliance**
2. Find your policy assignment
3. Check the compliance state:
   - **Compliant**: Storage accounts have soft delete enabled
   - **Non-compliant**: Storage accounts need remediation
4. Click on the policy to see detailed compliance data

### Via PowerShell

```powershell
# Check policy compliance state
$policyStates = Get-AzPolicyState -PolicyAssignmentName "assign-blob-soft-delete-policy"

# Display compliance summary
$policyStates | Group-Object ComplianceState | Select-Object Name, Count

# List non-compliant resources
$policyStates | Where-Object { $_.ComplianceState -eq "NonCompliant" } | 
    Select-Object ResourceId, ComplianceState
```

### Via Azure CLI

```bash
# Check policy compliance
az policy state list \
    --policy-assignment "assign-blob-soft-delete-policy" \
    --query "[].{Resource:resourceId, State:complianceState}" \
    --output table
```

## Monitoring and Maintenance

### Check Remediation Status

**PowerShell:**
```powershell
Get-AzPolicyRemediation -Name $remediationName -Scope $scope
```

**Azure CLI:**
```bash
az policy remediation show \
    --name "remediate-blob-soft-delete" \
    --scope "$SCOPE"
```

### View Policy Compliance Over Time

1. Go to **Policy** > **Compliance**
2. Select your policy assignment
3. View the compliance trend chart
4. Export compliance data for reporting

## Customization Options

### Adjust Retention Period

You can modify the retention period when assigning the policy or update an existing assignment:

**PowerShell:**
```powershell
Set-AzPolicyAssignment `
    -Name "assign-blob-soft-delete-policy" `
    -Scope $scope `
    -PolicyParameterObject @{ retentionDays = 30 }  # Change to desired days
```

**Azure CLI:**
```bash
az policy assignment update \
    --name "assign-blob-soft-delete-policy" \
    --params "{\"retentionDays\":{\"value\":30}}"
```

### Apply to Specific Resource Groups

To scope the policy to specific resource groups:

```powershell
$rgScope = "/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>"

New-AzPolicyAssignment `
    -Name "assign-blob-soft-delete-policy-rg" `
    -Scope $rgScope `
    -PolicyDefinition $policyDefinition `
    -PolicyParameterObject @{ retentionDays = 7 } `
    -IdentityType "SystemAssigned" `
    -Location "eastus"
```

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Policy Assignment Failed
**Symptom:** Error when creating policy assignment

**Solution:**
- Verify you have **Resource Policy Contributor** role
- Check that the policy definition was created successfully
- Ensure the scope path is correct

#### Issue 2: Remediation Not Working
**Symptom:** Non-compliant resources remain after remediation task

**Solution:**
- Verify the managed identity has **Storage Account Contributor** role
- Check that policy enforcement is **Enabled**
- Allow 15-30 minutes for policy evaluation and remediation
- Manually trigger remediation from Azure Portal

#### Issue 3: Managed Identity Permission Issues
**Symptom:** "Authorization failed" errors during remediation

**Solution:**
```powershell
# Re-assign the role to managed identity
$assignment = Get-AzPolicyAssignment -Name "assign-blob-soft-delete-policy" -Scope $scope
$principalId = $assignment.Identity.PrincipalId

New-AzRoleAssignment `
    -ObjectId $principalId `
    -RoleDefinitionName "Storage Account Contributor" `
    -Scope $scope
```

#### Issue 4: Policy Not Evaluating
**Symptom:** Compliance state shows "Not started" or no data

**Solution:**
- Wait 15-30 minutes for initial policy evaluation
- Manually trigger a compliance scan:
  ```powershell
  Start-AzPolicyComplianceScan -ResourceGroupName "<resource-group-name>"
  ```

### Check Policy Events and Logs

**PowerShell:**
```powershell
# Get policy events for troubleshooting
Get-AzPolicyEvent -PolicyAssignmentName "assign-blob-soft-delete-policy" | 
    Select-Object Timestamp, ResourceId, ComplianceState, PolicyDefinitionAction |
    Format-Table
```

**Azure CLI:**
```bash
az policy event list \
    --policy-assignment "assign-blob-soft-delete-policy" \
    --output table
```

## Cleanup (Removing the Policy)

### Remove Policy Assignment

**PowerShell:**
```powershell
Remove-AzPolicyAssignment -Name "assign-blob-soft-delete-policy" -Scope $scope
```

**Azure CLI:**
```bash
az policy assignment delete \
    --name "assign-blob-soft-delete-policy" \
    --scope "$SCOPE"
```

### Remove Policy Definition

**PowerShell:**
```powershell
Remove-AzPolicyDefinition -Name "audit-enable-blob-soft-delete"
```

**Azure CLI:**
```bash
az policy definition delete --name "audit-enable-blob-soft-delete"
```

## Best Practices

1. **Start with Audit Mode**: Test the policy in audit-only mode first before enabling automatic remediation
2. **Choose Appropriate Retention**: Balance between data protection and storage costs (7-30 days recommended)
3. **Monitor Compliance**: Regularly check policy compliance in Azure Policy dashboard
4. **Document Exceptions**: If excluding certain resource groups, document the business justification
5. **Use Management Groups**: For enterprise deployments, apply policy at management group level
6. **Test in Non-Production First**: Validate the policy in dev/test environments before production

## Additional Resources

- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Azure Blob Soft Delete Overview](https://docs.microsoft.com/azure/storage/blobs/soft-delete-blob-overview)
- [DeployIfNotExists Policy Effect](https://docs.microsoft.com/azure/governance/policy/concepts/effects#deployifnotexists)
- [Azure Policy Samples](https://github.com/Azure/azure-policy)

## Support and Contribution

For issues, questions, or contributions:
- Open an issue in the GitHub repository
- Submit a pull request with improvements
- Contact: Ganesh Maddipudi

---

**Version:** 1.0  
**Last Updated:** November 2025  
**Tested With:** Azure Policy API Version 2022-09-01
