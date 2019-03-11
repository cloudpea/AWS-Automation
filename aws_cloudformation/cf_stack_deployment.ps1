Param (
  [Parameter(Mandatory=$True, HelpMessage="AWS IAM User Access Key")]
  [string]$AccessKey,

  [Parameter(Mandatory=$True, HelpMessage="AWS IAM User Secret Key")]
  [securestring]$SecretKey,

  [Parameter(Mandatory=$True, HelpMessage="Name for the CloudFormation Stack")]
  [string]$StackName,

  [Parameter(Mandatory=$True, HelpMessage="File path to the CloudFormation Template")]
  [string]$TemplateFilePath
)
Write-Output ""
Write-Output "ANS - AWS DevOps Agent Deployment"
Write-Output "Version 1.0.0"
Write-Output ""
Write-Output ""

#Install and Import AWS PowerShell Module
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name AWSPowerShell.NetCore -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name AWSPowerShell.NetCore
    Import-Module -Name AWSPowerShell.NetCore
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module..."
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Host ""

#Login to AWS
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to AWS Account..."
Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey ;
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to AWS Account"
Write-Host ""

#Test CloudFormation Template
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Testing CloudFormation Template..."
$template = [IO.File]::ReadAllText($TemplateFilePath)
Test-CFNTemplate -TemplateBody $template
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Tested CloudFormation Template Successfully"

#Deploy CloudFormation Template
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Deploying CloudFormation Template..."
New-CFNStack -StackName $StackName -TemplateBody $template -EnableTerminationProtection $true -OnFailure ROLLBACK
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Deployed CloudFormation Template Successfully"
Write-Host ""