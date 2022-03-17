#Requires -Version 7
#Requires -Modules @{ ModuleName="Microsoft.PowerShell.ConsoleGuiTools"; ModuleVersion="0.6.2" }

<#
    Jo
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)] [ValidateRange(0,[int]::MaxValue)] [int] $investmentSum,
    [Parameter()] [ValidateNotNullOrEmpty()] [string] $configFilePath = "configuration.json"
)

begin {
    function Set-Config {
        param (
            [Parameter(Mandatory)] [ValidateNotNull()] [hashtable] $configuration,
            [Parameter(Mandatory)] [ValidateLength(6,6)] [string] $WKN,
            [Parameter()] [ValidateRange(0,100)] [int] $targetPercentage,
            [Parameter()] [ValidateRange(0,[int]::MaxValue)] [int] $pieces,
            [Parameter()] [switch] $delete
        )

        [hashtable] $newAsset = @{
            WKN = $WKN
            pieces = $pieces
            targetPercentage = $targetPercentage
        }

        [string] $assetType = "etfs"
        [System.Collections.ArrayList] $chosenAsset = $configuration.$assetType

        if ($delete) {
            $chosenAsset | ForEach-Object {
                if ($_.ContainsValue($WKN)) {
                    $objectToDelete = $_
                }
            }

            $chosenAsset.Remove($objectToDelete)
        }
        else {
            $chosenAsset.Add($newAsset) > $null
        }

        switch ($assetType) {
            "etfs" {
                [hashtable] $newConfiguration = @{
                    etfs = $chosenAsset
                    stocks = @()
                    bonds = @()
                    certificates = @()
                    funds = @()
                }
            }
        }

        return $newConfiguration
    }

    # If the user didn't give us an absolute path, resolve it from the current directory.
    if (-not [IO.Path]::IsPathRooted($configFilePath)) {
        $configFilePath = Join-Path -Path (Get-Location).Path -ChildPath $configFilePath
    }
    
    $configFilePath = Join-Path -Path $configFilePath -ChildPath '.'
    $configFilePath = [IO.Path]::GetFullPath($configFilePath)

    if (-not (Test-Path -Path $configFilePath)) {

        [hashtable] $defaultConfig = @{
            etfs = @()
            stocks = @()
            bonds = @()
            certificates = @()
            funds = @()
        }

        New-Item -Path $configFilePath -ItemType File -Value ($defaultConfig | ConvertTo-Json) > $null
    }
}

process {
    $allActions = [ordered] @{
        calc = "Doing the calculations"
        add = "Add an item"
        edit = "Edit an item"
        delete = "Remove an item"
        quit = "Quit this dialogue"
    }

    while ($selectedAction.Key -ne "quit") {

        $selectedAction = Out-ConsoleGridView -Title "Whatcha wanna do?" -InputObject $allActions -OutputMode Single

        switch ($selectedAction.Key) {
            "calc" { $selectedAction.Value }
            "add" {
                $configuration = ConvertFrom-Json -InputObject (Get-Content -Path $configFilePath -Raw) -AsHashtable
                $WKN = Read-Host -Prompt "Enter the WKN"
                $targetPercentage = Read-Host -Prompt "Enter the target percentage"
                $pieces = Read-Host -Prompt "Enter the currently owned pieces"

                [hashtable] $updatedConfig = Set-Config -configuration $configuration -WKN $WKN -targetPercentage $targetPercentage -pieces $pieces

                # Write the changed configuration
                Set-Content -Path $configFilePath -Value ($updatedConfig | ConvertTo-Json)
            }
            "edit" { $selectedAction.Value }
            "delete" {
                $configuration = ConvertFrom-Json -InputObject (Get-Content -Path $configFilePath -Raw) -AsHashtable
                $WKN = Read-Host -Prompt "Enter the WKN"

                [hashtable] $updatedConfig = Set-Config -configuration $configuration -WKN $WKN -delete

                # Write the changed configuration
                Set-Content -Path $configFilePath -Value ($updatedConfig | ConvertTo-Json)
            }
            "quit" { $selectedAction.Value }
        }
    }
}

end {

}