Param (
  [Parameter(Mandatory=$True, HelpMessage="File Path to AWS VM Modernisation Table")]
  [string]$csvPath,

  [Parameter(Mandatory=$True, HelpMessage="API Access Key for AWS Account")]
  [string]$accessKey,

  [Parameter(Mandatory=$True, HelpMessage="API Secret Key for AWS Account")]
  [securestring]$secretKey,
)
Write-Output ""
Write-Output "Unmodernised Instance Recommendations"
Write-Output "Version - 1.0.0"
Write-Output "Author - Ryan Froggatt (CloudPea)"
Write-Output ""

#Install and Import AWS PowerShell Module
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name AWSPowerShell.NetCore -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name AWSPowerShell.NetCore
    Import-Module -Name AWSPowerShell.NetCore
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module..."
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Output ""

#Set CSV Path and Import CSV
$CSV = Import-Csv $csvPath

#Set Log Output Header
"[$(get-date -Format "dd/mm/yy hh:mm:ss")] Log Output from Instance Modernisation Checks..." | Out-File -FilePath "$CSVPath\Modernisation Log.txt"

#Set CSV Headers
"""InstanceName"",""InstanceId"",""InstanceSize"",""Region"",""OSType"",""NewSize""" | Out-File -Encoding ASCII -FilePath "$CSVPath\aws_ec2_modernisation_recommendations.csv"


#Create Hash Table of Key Pairs from CSV to determine correct moderinisation approach
$CSVTable=@{}

#Get Number of Columns in CSV
$CSVCount=(get-member -InputObject $CSV[0] -MemberType NoteProperty).count

#NOTE - Assumes Column Headers are named VersionX
foreach($TableEntry in $CSV) {
    #All but last column
    for($First=1;$First -lt $CSVCount;$First++)  {
        #Get version to upgrade from
        $FirstStr=$TableEntry.pSobject.Properties.item("Version"+$First.ToString()).Value
            
        if($FirstStr -ne "N/A") {
            #All remaining columns
            for($Second=$First+1;$Second -le $CSVCount;$Second++) {
                #Get version to upgrade to
                $SecondStr=$TableEntry.pSobject.Properties.item("Version"+$Second.ToString()).Value
        
                if($SecondStr -ne "N/A") {
                    #If from and to are valid write hash table entry
                    $CSVTable[$FirstStr]=$SecondStr
                }
            }
        }
    }
}


#Login to AWS
Write-Output ""
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to AWS Account..."
Set-AWSCredentials -AccessKey $accessKey -SecretKey $secretKey ;
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to AWS Account"
Write-Output ""


#Get All EC2 Instances
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathering all EC2 Instances in account..."
foreach ($reg in Get-AWSRegion) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" "Processing Region $reg"
    #Process Each Instance based on Hash Table Key Value Pairs
    foreach ($Instance in (Get-EC2Instance -Region $reg).instances) {

        #If Hash Table contains the Instance Size Output Recommendation
        if ($CSVTable[$Instance.InstanceType.Value]) {
        
            #Set Instance Name and Region Variables
            $InstanceName = $Instance.Tags | Where-Object {$_.Key -eq "Name"} | select -ExpandProperty Value

            #Append Recommendation to CSV
            """"+$InstanceName+""","""+$Instance.InstanceId+""","""+$Instance.InstanceType.Value+""","""+$reg+""","""+$Instance.Platform.Value+""","""+$CSVTable[$Instance.InstanceType.Value]+"""" | 
            Out-File -Encoding ASCII -FilePath "$CSVPath\aws_ec2_modernisation_recommendations.csv" -Append

            #Write output to Log File
            #If Instance has name tag use name tag
            if ($InstanceName -eq $null) {
                "[$(get-date -Format "dd/mm/yy hh:mm:ss")] " + $Instance.InstanceId + "can be modernised to " + $CSVTable[$Instance.InstanceType.Value] |
                Out-File -FilePath "$CSVPath\Modernisation Log.txt" -Append

                Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $Instance.InstanceId " can be modernised to" $CSVTable[$Instance.InstanceType.Value]
            }
            #If Instance does not have name tag use ID
            else {
                "[$(get-date -Format "dd/mm/yy hh:mm:ss")] " + $InstanceName + "can be modernised to " + $CSVTable[$Instance.InstanceType.Value] |
                Out-File -FilePath "$CSVPath\Modernisation Log.txt" -Append

                Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $InstanceName " can be modernised to" $CSVTable[$Instance.InstanceType.Value]
            }
        } 

        #If HashTable does not contain the instance size
        else {
            #Write output to Log File
            $InstanceName = $Instance.Tags | Where-Object {$_.Key -eq "Name"} | select -ExpandProperty Value

            #If Instance has name tag use name tag
            if ($InstanceName -eq $null) {
                "[$(get-date -Format 'dd/mm/yy hh:mm:ss')] " + $Instance.InstanceId + " cannot be modernised" |
                Out-File -FilePath "$CSVPath\Modernisation Log.txt" -Append
                Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $Instance.InstanceId "cannot be modernised" 
            }
            #If Instance does not have name tag use ID
            else {
                "[$(get-date -Format 'dd/mm/yy hh:mm:ss')] " + $InstanceName + " cannot be modernised" |
                Out-File -FilePath "$CSVPath\Modernisation Log.txt" -Append
                Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $InstanceName "cannot be modernised" 
            }
        }
    }
}