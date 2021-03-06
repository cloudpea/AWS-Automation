Param (
  [Parameter(Mandatory = $True, HelpMessage = "AWS IAM User Access Key")]
  [string]$AccessKey,

  [Parameter(Mandatory = $True, HelpMessage = "AWS IAM User Secret Key")]
  [string]$SecretKey
)
Write-Output ""
Write-Output "EC2 Unattached EBS Volumes"
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

#Set CSV Headers
"""VolumeId"",""AvailabilityZone"",""CreateTime"",""Size"",""VolumeType""" | Out-File -Encoding ASCII -FilePath ".\aws_unattached_ebs_volumes.csv"

#Get Unattached EBS Volumes
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathering Unattached EBS Volumes..."
foreach ($region in Get-AWSRegion) {
  Write-Host ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing Region - "+$region.Region)
    foreach ($volume in Get-EC2Volume -Region $region.Region -Filter @{ Name = "status"; Values = "available" }) {
        """" + $volume.VolumeId + """,""" + $volume.AvailabilityZone + """,""" + $volume.CreateTime + """,""" + $volume.Size + """,""" + $volume.VolumeType + """" | 
            Out-File -Encoding ASCII -FilePath ".\aws_unattached_ebs_volumes.csv" -Append
    }
    Write-Host ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] "+$region.Region+" Completed.")
}
Write-Host ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] CSV Exported Successfully!")
