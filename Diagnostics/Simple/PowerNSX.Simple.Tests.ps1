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
Import-Module -Name $PSScriptRoot\..\$moduleManifestName

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        $moduleManifestTest = $null
        $moduleManifestTest = Test-ModuleManifest -Path $PSScriptRoot\..\$moduleManifestName
        $moduleManifestTest | Should Be $true
    } # end It
} # end describe 'Module Manifest Tests'
