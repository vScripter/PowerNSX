<#




#>

function Parse-CentralCliResponse {

    param (
        [Parameter ( Mandatory=$True, Position=1)]
            [String]$response
    )


    #Response is straight text unfortunately, so there is no structure.  Having a crack at writing a very simple parser though the formatting looks.... challenging...

    #Control flags for handling list and table processing.
    $TableHeaderFound = $false
    $MatchedVnicsList = $false
    $MatchedRuleset = $false
    $MatchedAddrSet = $false

    $RuleSetName = ""
    $AddrSetName = ""

    $KeyValHash = @{}
    $KeyValHashUsed = $false

    #Defined this as variable as the swtich statement does not let me concat strings, which makes for a verrrrry long line...
    $RegexDFWRule = "^(?<Internal>#\sinternal\s#\s)?(?<RuleSetMember>rule\s)?(?<RuleId>\d+)\sat\s(?<Position>\d+)\s(?<Direction>in|out|inout)\s" +
            "(?<Type>protocol|ethertype)\s(?<Service>.*?)\sfrom\s(?<Source>.*?)\sto\s(?<Destination>.*?)(?:\sport\s(?<Port>.*))?\s" +
            "(?<Action>accept|reject|drop)(?:\swith\s(?<Log>log))?(?:\stag\s(?<Tag>'.*'))?;"



    foreach ( $line in ($response -split '[\r\n]')) {

        #Init EntryHash hashtable
        $EntryHash= @{}

        switch -regex ($line.trim()) {

            #C CLI appears to emit some error conditions as ^ Error:<digits>
            "^Error \d+:.*$" {

                write-debug "$($MyInvocation.MyCommand.Name) : Matched Error line. $_ "

                Throw "CLI command returned an error: ( $_ )"

            }

            "^\s*$" {
                #Blank line, ignore...
                write-debug "$($MyInvocation.MyCommand.Name) : Ignoring blank line: $_"
                break

            }

            "^# Filter rules$" {
                #Filter line encountered in a ruleset list, ignore...
                if ( $MatchedRuleSet ) {
                    write-debug "$($MyInvocation.MyCommand.Name) : Ignoring meaningless #Filter rules line in ruleset: $_"
                    break
                }
                else {
                    throw "Error parsing Centralised CLI command output response.  Encountered #Filter rules line when not processing a ruleset: $_"
                }

            }
            #Matches a single integer of 1 or more digits at the start of the line followed only by a fullstop.
            #Example is the Index in a VNIC list.  AFAIK, the index should only be 1-9. but just in case we are matching 1 or more digit...
            "^(\d+)\.$" {

                write-debug "$($MyInvocation.MyCommand.Name) : Matched Index line.  Discarding value: $_ "
                If ( $MatchedVnicsList ) {
                    #We are building a VNIC list output and this is the first line.
                    #Init the output object to static kv props, but discard the value (we arent outputing as it appears superfluous.)
                    write-debug "$($MyInvocation.MyCommand.Name) : Processing Vnic List, initialising new Vnic list object"

                    $VnicListHash = @{}
                    $VnicListHash += $KeyValHash
                    $KeyValHashUsed = $true

                }
                break
            }

            #Matches the start of a ruleset list.  show dfw host host-xxx filter xxx rules will output in rulesets like this
            "ruleset\s(\S+) {" {

                #Set a flag to say we matched a ruleset List, and create the output object.
                write-debug "$($MyInvocation.MyCommand.Name) : Matched start of DFW Ruleset output.  Processing following lines as DFW Ruleset: $_"
                $MatchedRuleset = $true
                $RuleSetName = $matches[1].trim()
                break
            }

            #Matches the start of a addrset list.  show dfw host host-xxx filter xxx addrset will output in addrsets like this
            "addrset\s(\S+) {" {

                #Set a flag to say we matched a addrset List, and create the output object.
                write-debug "$($MyInvocation.MyCommand.Name) : Matched start of DFW Addrset output.  Processing following lines as DFW Addrset: $_"
                $MatchedAddrSet = $true
                $AddrSetName = $matches[1].trim()
                break
            }

            #Matches a addrset entry.  show dfw host host-xxx filter xxx addrset will output in addrsets.
            "^(?<Type>ip|mac)\s(?<Address>.*),$" {

                #Make sure we were expecting it...
                if ( -not $MatchedAddrSet ) {
                    Throw "Error parsing Centralised CLI command output response.  Unexpected dfw addrset entry : $_"
                }

                #We are processing a RuleSet, so we need to emit an output object that contains the ruleset name.
                [PSCustomobject]@{
                    "AddrSet" = $AddrSetName;
                    "Type" = $matches.Type;
                    "Address" = $matches.Address
                }

                break
            }

            #Matches a rule, either within a ruleset, or individually listed.  show dfw host host-xxx filter xxx rules will output in rulesets,
            #or show dfw host-xxx filter xxx rule 1234 will output individual rule that should match.
            $RegexDFWRule {

                #Check if the rule is individual or part of ruleset...
                if ( $Matches.ContainsKey("RuleSetMember") -and (-not $MatchedRuleset )) {
                    Throw "Error parsing Centralised CLI command output response.  Unexpected dfw ruleset entry : $_"
                }

                $Type = switch ( $matches.Type ) { "protocol" { "Layer3" } "ethertype" { "Layer2" }}
                $Internal = if ( $matches.ContainsKey("Internal")) { $true } else { $false }
                $Port = if ( $matches.ContainsKey("Port") ) { $matches.port } else { "Any" }
                $Log = if ( $matches.ContainsKey("Log") ) { $true } else { $false }
                $Tag = if ( $matches.ContainsKey("Tag") ) { $matches.Tag } else { "" }

                If ( $MatchedRuleset ) {

                    #We are processing a RuleSet, so we need to emit an output object that contains the ruleset name.
                    [PSCustomobject]@{
                        "RuleSet" = $RuleSetName;
                        "InternalRule" = $Internal;
                        "RuleID" = $matches.RuleId;
                        "Position" = $matches.Position;
                        "Direction" = $matches.Direction;
                        "Type" = $Type;
                        "Service" = $matches.Service;
                        "Source" = $matches.Source;
                        "Destination" = $matches.Destination;
                        "Port" = $Port;
                        "Action" = $matches.Action;
                        "Log" = $Log;
                        "Tag" = $Tag

                    }
                }

                else {
                    #We are not processing a RuleSet; so we need to emit an output object without a ruleset name.
                    [PSCustomobject]@{
                        "InternalRule" = $Internal;
                        "RuleID" = $matches.RuleId;
                        "Position" = $matches.Position;
                        "Direction" = $matches.Direction;
                        "Type" = $Type;
                        "Service" = $matches.Service;
                        "Source" = $matches.Source;
                        "Destination" = $matches.Destination;
                        "Port" = $Port;
                        "Action" = $matches.Action;
                        "Log" = $Log;
                        "Tag" = $Tag
                    }
                }

                break
            }

            #Matches the end of a ruleset and addr lists.  show dfw host host-xxx filter xxx rules will output in lists like this
            "^}$" {

                if ( $MatchedRuleset ) {

                    #Clear the flag to say we matched a ruleset List
                    write-debug "$($MyInvocation.MyCommand.Name) : Matched end of DFW ruleset."
                    $MatchedRuleset = $false
                    $RuleSetName = ""
                    break
                }

                if ( $MatchedAddrSet ) {

                    #Clear the flag to say we matched an addrset List
                    write-debug "$($MyInvocation.MyCommand.Name) : Matched end of DFW addrset."
                    $MatchedAddrSet = $false
                    $AddrSetName = ""
                    break
                }

                throw "Error parsing Centralised CLI command output response.  Encountered unexpected list completion character in line: $_"
            }

            #More Generic matches

            #Matches the generic KV case where we have _only_ two strings separated by more than one space.
            #This will do my head in later when I look at it, so the regex explanation is:
            #    - (?: gives non capturing group, we want to leverage $matches later, so dont want polluting groups.
            #    - (\S|\s(?!\s)) uses negative lookahead assertion to 'Match a non whitespace, or a single whitespace, as long as its not followed by another whitespace.
            #    - The rest should be self explanatory.
            "^((?:\S|\s(?!\s))+\s{2,}){1}((?:\S|\s(?!\s))+)$" {

                write-debug "$($MyInvocation.MyCommand.Name) : Matched Key Value line (multispace separated): $_ )"

                $key = $matches[1].trim()
                $value = $matches[2].trim()
                If ( $MatchedVnicsList ) {
                    #We are building a VNIC list output and this is one of the lines.
                    write-debug "$($MyInvocation.MyCommand.Name) : Processing Vnic List, Adding $key = $value to current VnicListHash"

                    $VnicListHash.Add($key,$value)

                    if ( $key -eq "Filters" ) {

                        #Last line in a VNIC List...
                        write-debug "$($MyInvocation.MyCommand.Name) : VNIC List :  Outputing VNIC List Hash."
                        [PSCustomobject]$VnicListHash
                    }
                }
                else {
                    #Add KV to hash table that we will append to output object
                    $KeyValHash.Add($key,$value)
                }
                break
            }

            #Matches a general case output line containing Key: Value for properties that are consistent accross all entries in a table.
            #This will match a line with multiple colons in it, not sure if thats an issue yet...
            "^((?:\S|\s(?!\s))+):((?:\S|\s(?!\s))+)$" {
                if ( $TableHeaderFound ) { Throw "Error parsing Centralised CLI command output response.  Key Value line found after header: ( $_ )" }
                write-debug "$($MyInvocation.MyCommand.Name) : Matched Key Value line (Colon Separated) : $_"

                #Add KV to hash table that we will append to output object
                $KeyValHash.Add($matches[1].trim(),$matches[2].trim())

                break
            }

            #Matches a Table header line.  This is a special case of the table entry line match, with the first element being ^No\.  Hoping that 'No.' start of the line is consistent :S
            "^No\.\s{2,}(.+\s{2,})+.+$" {
                if ( $TableHeaderFound ) {
                    throw "Error parsing Centralised CLI command output response.  Matched header line more than once: ( $_ )"
                }
                write-debug "$($MyInvocation.MyCommand.Name) : Matched Table Header line: $_"
                $TableHeaderFound = $true
                $Props = $_.trim() -split "\s{2,}"
                break
            }

            #Matches the start of a Virtual Nics List output.  We process the output lines following this as a different output object
            "Virtual Nics List:" {
                #When central cli outputs a NIC 'list' it does so with a vertical list of Key Value rather than a table format,
                #and with multi space as the KV separator, rather than a : like normal KV output.  WTF?
                #So Now I have to go forth and collate my nic object over the next few lines...
                #Example looks like this:

                #Virtual Nics List:
                #1.
                #Vnic Name      test-vm - Network adapter 1
                #Vnic Id        50012d15-198c-066c-af22-554aed610579.000
                #Filters        nic-4822904-eth0-vmware-sfw.2

                #Set a flag to say we matched a VNic List, and create the output object initially with just the KV's matched already.
                write-debug "$($MyInvocation.MyCommand.Name) : Matched VNIC List line.  Processing remaining lines as Vnic List: $_"
                $MatchedVnicsList = $true
                break

            }

            #Matches a table entry line.  At least three properties (that may contain a single space) separated by more than one space.
            "^((?:\S|\s(?!\s))+\s{2,}){2,}((?:\S|\s(?!\s))+)$" {
                if ( -not $TableHeaderFound ) {
                    throw "Error parsing Centralised CLI command output response.  Matched table entry line before header: ( $_ )"
                }
                write-debug "$($MyInvocation.MyCommand.Name) : Matched Table Entry line: $_"
                $Vals = $_.trim() -split "\s{2,}"
                if ($Vals.Count -ne $Props.Count ) {
                    Throw "Error parsing Centralised CLI command output response.  Table entry line contains different value count compared to properties count: ( $_ )"
                }

                #Build the output hashtable with the props returned in the table entry line
                for ( $i= 0; $i -lt $props.count; $i++ ) {

                    #Ordering is hard, and No. entry is kinda superfluous, so removing it from output (for now)
                    if ( -not ( $props[$i] -eq "No." )) {
                        $EntryHash[$props[$i].trim()]=$vals[$i].trim()
                    }
                }

                #Add the KV pairs that were parsed before the table.
                try {

                    #This may fail if we have a key of the same name.  For the moment, Im going to assume that this wont happen...
                    $EntryHash += $KeyValHash
                    $KeyValHashUsed = $true
                }
                catch {
                    throw "Unable to append static Key Values to EntryHash output object.  Possibly due to a conflicting key"
                }

                #Emit the entry line as a PSCustomobject :)
                [PSCustomObject]$EntryHash
                break
            }
            default { throw "Unable to parse Centralised CLI output line : $($_ -replace '\s','_')" }
        }
    }

    if ( (-not $KeyValHashUsed) -and $KeyValHash.count -gt 0 ) {

        #Some output is just key value, so, if it hasnt been appended to output object already, we will just emit it.
        #Not sure how this approach will work long term, but it works for show dfw vnic <>
        write-debug "$($MyInvocation.MyCommand.Name) : KeyValHash has not been used after all line processing, outputing as is: $_"
        [PSCustomObject]$KeyValHash
    }
}