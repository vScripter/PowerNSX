<#




#>

function Check-PowerCliAsemblies {

    #Checks for known assemblies loaded by PowerCLI.
    #PowerNSX uses a variety of types, and full operation requires
    #extensive PowerCLI usage.
    #As of v2, we now _require_ PowerCLI assemblies to be available.
    #This method works for both PowerCLI 5.5 and 6 (snapin vs module),
    #shouldnt be as heavy as loading each required type explicitly to check
    #and should function in a modified PowerShell env, as well as normal
    #PowerCLI.

    $RequiredAsm = (
        "VMware.VimAutomation.ViCore.Cmdlets",
        "VMware.Vim",
        "VMware.VimAutomation.Sdk.Util10Ps",
        "VMware.VimAutomation.Sdk.Util10",
        "VMware.VimAutomation.Sdk.Interop",
        "VMware.VimAutomation.Sdk.Impl",
        "VMware.VimAutomation.Sdk.Types",
        "VMware.VimAutomation.ViCore.Types",
        "VMware.VimAutomation.ViCore.Interop",
        "VMware.VimAutomation.ViCore.Util10",
        "VMware.VimAutomation.ViCore.Util10Ps",
        "VMware.VimAutomation.ViCore.Impl",
        "VMware.VimAutomation.Vds.Commands",
        "VMware.VimAutomation.Vds.Impl",
        "VMware.VimAutomation.Vds.Interop",
        "VMware.VimAutomation.Vds.Types",
        "VMware.VimAutomation.Storage.Commands",
        "VMware.VimAutomation.Storage.Impl",
        "VMware.VimAutomation.Storage.Types",
        "VMware.VimAutomation.Storage.Interop",
        "VMware.DeployAutomation",
        "VMware.ImageBuilder"
    )


    $CurrentAsmName = foreach( $asm in ([AppDomain]::CurrentDomain.GetAssemblies())) { $asm.getName() }
    $CurrentAsmDict = $CurrentAsmName | Group-Object -AsHashTable -Property Name

    foreach( $req in $RequiredAsm ) {

        if ( -not $CurrentAsmDict.Contains($req) ) {
            write-warning "PowerNSX requires PowerCLI."
            throw "Assembly $req not found.  Some required PowerCli types are not available in this PowerShell session.  Please ensure you are running PowerNSX in a PowerCLI session, or have manually loaded the required assemblies."}

    } # end forech

} # end function Check-PowerCliAsemblies
