<#
.SYNOPSIS
    Returns the assemblies that are expected to be loaded by PowerCLI

.DESCRIPTION
    Returns the assemblies that are expected to be loaded by PowerCLI.

    Currently, these Assemblies are based off of PowerCLI 6.3 R1
.NOTES
    Version: 1.0
    Updated: 8/28/16
    Updated By: Kevin Kirkpatrick (GitHub.com/vScripter)
    Update Notes:
    - Created
#>

function Get-PowerCLIAssemblies {

    [CmdletBinding()]
    param()

    BEGIN {

        $currentAssemblyDict = $null
        $currentAsmName = $null
        $currentAsmDict = $null

    } # end BEGIN block

    PROCESS {

        try {

            $currentAssemblyDict = [AppDomain]::CurrentDomain.GetAssemblies()
            $currentAsmName = foreach ($asm in $currentAssemblyDict) { $asm.getName() }
            $currentAsmDict = $CurrentAsmName | Group-Object -AsHashTable -Property Name
            $currentAsmDict

        } catch {

            throw "[$($MyInvocation.MyCommand.Name)][ERROR] Could not enumerate currently loaded Assemblies. $_"

        } # end try/catch

    } # end PROCESS block

} # end function Get-PowerCLIAssemblies