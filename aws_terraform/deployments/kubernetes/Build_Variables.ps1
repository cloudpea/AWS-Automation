Param(
  [Parameter(Position=1)][String]$CsvFile = "./terraform.variables.csv"
)

Remove-Item -Path "./terraform.tfvars" -Force -ErrorAction SilentlyContinue

ForEach ($LINE In (Import-Csv $CsvFile )) {
  # If the name or value of the variable is not blank, process it.
  If ("" -notin ($LINE.VariableValue.replace(' ', ''), $LINE.VariableName.replace(' ', ''))) {
    # Check for the type and format it based on the Type.
    If ($LINE.Type -eq "String") {
      # With Strings, if the value is a true/false value, treat it like a boolean
      If ($LINE.VariableValue -in ("true", "false")) {
        Add-Content -Path "./terraform.tfvars" -Value "$($LINE.VariableName) = $($LINE.VariableValue.ToLower())"
      } Else {
        Add-Content -Path "./terraform.tfvars" -Value "$($LINE.VariableName) = `"$($LINE.VariableValue)`""
      }
    } ElseIf ($LINE.Type -eq "List") {
      Add-Content -Path "./terraform.tfvars" -Value "$($LINE.VariableName) = [`"$($LINE.VariableValue.replace(' ', '').replace(',', '","'))`"]"
    }
  }
}

If (Test-Path "./terraform.tfvars") {
  Write-Host -ForegroundColor Green "Contents of '$($CsvFile)' successfully written to './terraform.tfvars'."
} Else {
  Write-Host -ForegroundColor Red `
@"
No contents were written from '$($CsvFile)' to './terraform.tfvars'.
* Ensure that '$($CsvFile)' exists (If it does not them Import-Csv will provide further information)
* Ensure '$($CsvFile)' format is the same as the 'Terraform Cloudstart.xlsx' tables' format and that it is comma-delimited.
"@
}
