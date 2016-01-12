Function API-Execute {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$apiKey,
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$command,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [System.Collections.Hashtable]$args,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [Int]$uniqueId=-1
    )

    $apiURL = "https://api.dreamhost.com/?key=$apiKey&cmd=$command&format=json"
    if ($args) {$apiURL += "&$(($args.GetEnumerator() | %{"$($_.Key)=$([System.Web.HttpUtility]::HtmlEncode($_.Value) -replace " ", "%20")"}) -join "&")"}
    if ($uniqueId -ige 0) {$apiURL += "&unique_id=$uniqueId"}

    return (Invoke-RestMethod $apiURL -Method Get)

}

Function API-GetCommands {
    
    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$apiKey
    )

    $apiCall = API-Execute -apiKey $apiKey -command api-list_accessible_cmds

    if ($apiCall.result -eq "success") {

        $result = @()

        $apiCall.data | %{

                $row = New-Object System.Object
                $row | Add-Member -MemberType NoteProperty -Name "Command" -Value $_.cmd
                $row | Add-Member -MemberType NoteProperty -Name "Order" -Value $_.order
                $row | Add-Member -MemberType NoteProperty -Name "Arguments" -Value $_.args
                $row | Add-Member -MemberType NoteProperty -Name "OptionalArguments" -Value $_.optargs
                $result += $row

        }

        return $result

    } else {
        Write-Error -Message "There was an error fetching available API commands: '$($apiCall.data)'" -ErrorId 0
    }

}

Function API-GetKeys {
    
    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$apiKey
    )

    $apiCall = API-Execute -apiKey $apiKey -command api-list_keys

    if ($apiCall.result -eq "success") {

        $result = @()

        $apiCall.data | %{

                $row = New-Object System.Object
                $row | Add-Member -MemberType NoteProperty -Name "Key" -Value $_.key
                $row | Add-Member -MemberType NoteProperty -Name "Functions" -Value $_.functions
                $row | Add-Member -MemberType NoteProperty -Name "Comment" -Value $_.comment
                $row | Add-Member -MemberType NoteProperty -Name "Created" -Value $_.created
                $result += $row

        }

        return $result

    } else {
        Write-Error -Message "There was an error fetching available API commands: '$($apiCall.data)'" -ErrorId 0
    }

}

Function DnsRecord-Fetch {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$apiKey,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [Bool]$onlyEditable=$false
    )

    $apiCall = API-Execute -apiKey $apiKey -command dns-list_records

    if ($apiCall.result -eq "success") {

        $result = @()
    
        $apiCall.data | %{
            
            if (!$onlyEditable -or ($onlyEditable -and $_.editable -eq 1)) {

                $row = New-Object System.Object
                $row | Add-Member -MemberType NoteProperty -Name "Record" -Value $_.record
                $row | Add-Member -MemberType NoteProperty -Name "Value" -Value $_.value
                $row | Add-Member -MemberType NoteProperty -Name "Type" -Value $_.type
                $row | Add-Member -MemberType NoteProperty -Name "Comment" -Value $_.comment
                $row | Add-Member -MemberType NoteProperty -Name "Editable" -Value @{$true="Yes";$false="No"}[$_.editable -eq 1]
                $result += $row

            }

        }

        return $result

    } else {
        Write-Error -Message "There was an error fetching DNS records: '$($apiCall.data)'" -ErrorId 0
    }

}

Function DnsRecord-Add {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$apiKey,
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$record,
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$type,
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$value,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$comment,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [Bool]$force=$false
    )

    $record = $record.Trim()
    $type = $type.Trim()
    $value = $value.Trim()
    $comment - $comment.Trim()

    if (!($record -match '([A-Za-z0-9-]+(?(?!$)\.)){3,}')) { # http://bit.ly/1JGMUle
        Write-Error -Message "The record: '$record' is not valid" -ErrorId 0
    }

    switch ($type) {

        {
            "A",
            "CNAME",
            "TXT",
            "NS",
            "SRV",
            "AAAA" -contains $_
        }{
            # Do nothing
        }
        default {
            Write-Error "The type: '$type' is not valid"
        }

    }

    if ($force -or (Read-Host "Are you sure want to add the following record: $record | $type | $value") -match "^y(?:es)?$") {

        $args = @{"record" = $record; "type" = $type; "value" = $value}
        if ($comment) {$args.Add("comment", $comment)}

        $apiCall = API-Execute -apiKey $apiKey -command dns-add_record -args $args

        if ($apiCall.result -eq "success") {
            Write-Host "Record successfully added"
        } else {
            Write-Error -Message "There was an error adding the DNS record: '$($apiCall.data)'" -ErrorId 0
        }

    }

}

Function DnsRecord-Remove {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$apiKey,
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$record,
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$type,
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$value,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [Bool]$force=$false
    )

    $record = $record.Trim()
    $type = $type.Trim()
    $value = $value.Trim()

    if (!($record -match '([A-Za-z0-9-]+(?(?!$)\.)){3,}')) { # http://bit.ly/1JGMUle
        Write-Error -Message "The record: '$record' is not valid" -ErrorId 0
    }

    switch ($type) {

        {
            "A",
            "CNAME",
            "TXT",
            "NS",
            "SRV",
            "AAAA" -contains $_
        }{
            # Do nothing
        }
        default {
            Write-Error "The type: '$type' is not valid"
        }

    }

    if ($force -or (Read-Host "Are you sure want to remove the following record: $record | $type | $value") -match "^y(?:es)?$") {

        $apiCall = API-Execute -apiKey $apiKey -command dns-remove_record -args @{"record" = $record; "type" = $type; "value" = $value}

        if ($apiCall.result -eq "success") {
            Write-Host "Record successfully removed"
        } else {
            Write-Error -Message "There was an error removing the DNS record: '$($apiCall.data)'" -ErrorId 0
        }

    }

}

Function PublicIP-Fetch {
    return (Invoke-RestMethod "curlmyip.com").Trim()
}