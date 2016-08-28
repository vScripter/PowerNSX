<#
.NOTES
    TODO:
        - Start with core functionality
        - Logical Switches
        - Logical Routers
        - Edge Services Gateways
        - Load-Balancing
        - VPN
        - Sub-Feature/Functionality
#>

$moduleManifestName = 'PowerNSX.psd1'
$moduleManifestPath = $PSScriptRoot\..\..\$moduleManifestName

Describe 'Module Manifest Tests' {

    It 'Passes Test-ModuleManifest' {
        $moduleManifestTest = $null
        $moduleManifestTest = Test-ModuleManifest -Path $moduleManifestPath
        $moduleManifestTest | Should Be $true
    } # end It

} # end describe

Import-Module -Name $moduleManifestPath -ErrorAction 'SilentlyContinue'

Describe 'PowerCLI and .NET Assembly Check' {

    It -Test 'PowerCLI Is Available' {
        $assemblyDictionary = $null
        #$assemblyDictionary = Get-Content -Path ..\Private\Inputs\PowerCLI-Assemblies.txt
    }

} # end Describe
