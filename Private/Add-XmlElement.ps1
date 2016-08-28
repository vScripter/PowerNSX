<#


#>

function Add-XmlElement {

    #Internal function used to simplify the exercise of adding XML text Nodes.
    param (

        [System.XML.XMLElement]$xmlRoot,
        [String]$xmlElementName,
        [String]$xmlElementText
    )

    #Create an Element and append it to the root
    [System.XML.XMLElement]$xmlNode = $xmlRoot.OwnerDocument.CreateElement($xmlElementName)
    [System.XML.XMLNode]$xmlText = $xmlRoot.OwnerDocument.CreateTextNode($xmlElementText)
    $xmlNode.AppendChild($xmlText) | out-null
    $xmlRoot.AppendChild($xmlNode) | out-null
}