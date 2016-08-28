<#



#>

function Get-FeatureStatus {

    param (

        [string]$featurestring,
        [system.xml.xmlelement[]]$statusxml
        )

    [system.xml.xmlelement]$feature = $statusxml | ? { $_.featureId -eq $featurestring } | select -first 1
    [string]$statusstring = $feature.status
    $message = $feature.SelectSingleNode('message')
    if ( $message -and ( $message | get-member -membertype Property -Name '#Text')) {
        $statusstring += " ($($message.'#text'))"
    }
    $statusstring
}