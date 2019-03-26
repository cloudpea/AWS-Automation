Param (
  [Parameter(Mandatory=$True, HelpMessage="AWS IAM User Access Key")]
  [string]$AccessKey,

  [Parameter(Mandatory=$True, HelpMessage="API Secret Key for AWS Account")]
  [string]$SecretKey
)
Write-Output ""
Write-Output "EC2 Power Management"
Write-Output "Version - 1.0.0"
Write-Output "Author - Ryan Froggatt (CloudPea)"
Write-Output ""

#Install and Import AWS PowerShell Module
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name AWSPowerShell.NetCore -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name AWSPowerShell.NetCore
    Import-Module -Name AWSPowerShell.NetCore
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module"
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Host ""

#Login to AWS
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to AWS Account..."
Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey ;
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to AWS Account"
Write-Host ""

# Get Current Hour
$Hour = (Get-Date).Hour

#Stop EC2 Instances
foreach($region in Get-AWSRegion) {
  foreach($instance in Get-EC2Instance -Region $region.Region -Filter @{ "Name" = "tag" ; "Value" = "AutoOff=$Hour"}) {
    Write-Host ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Stopping Instance - "+$instance.InstanceId)
    Stop-EC2Instance -InstanceId $instance.InstanceId -Region $region.Region
    Write-Host ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] "+$instance.InstanceId+" Stopped Succesfully")
  }
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Instances Stopped"


#Start EC2 Instances
foreach($region in Get-AWSRegion) {
  foreach($instance in Get-EC2Instance -Region $region.Region -Filter @{ "Name" = "tag" ; "Value" = "AutoOn=$Hour"}) {
    Write-Host ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Starting Instance - "+$instance.InstanceId)
    Start-EC2Instance -InstanceId $instance.InstanceId -Region $region.Region
    Write-Host ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] "+$instance.InstanceId+" Started Succesfully")
  }
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Instances Started"
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Script Complete"
