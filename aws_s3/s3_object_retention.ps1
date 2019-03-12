Param (
  [Parameter(Mandatory = $True, HelpMessage = "AWS IAM User Access Key")]
  [string]$AccessKey,

  [Parameter(Mandatory = $True, HelpMessage = "AWS IAM User Secret Key")]
  [string]$SecretKey,

  [Parameter(Mandatory = $True, HelpMessage = "S3 Objects not modified within the Number of Days will be exported")]
  [int]$LastModifiedInDays
)

Write-Output ""
Write-Output "S3 objects Out of Retention"
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
"""objectETag"",""BucketName"",""LastModified"",""Size"",""StorageClass""" | Out-File -Encoding ASCII -FilePath ".\aws_s3_objects.csv"

#Get object Retention
$TimeStamp = (Get-Date).AddDays($LastModifiedInDays)
foreach ($bucket in Get-S3Bucket) {
    foreach ($object in Get-S3object -BucketName $bucket.BucketName | Where-Object {$_.LastModified -lt $TimeStamp}) {
        """" + $object.ETag + """,""" + $object.BucketName + """,""" + $object.LastModified + """,""" + $object.Size + """,""" + $object.StorageClass + """" | 
            Out-File -Encoding ASCII -FilePath ".\aws_s3_objects.csv" -Append
    }
}