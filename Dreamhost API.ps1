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

Function PublicIP-Fetch {
    return (Invoke-RestMethod "curlmyip.com").Trim()
}

<#
 # API Metacommands
 #>

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
        Write-Error -Message "There was an error fetching available API commands: '$($apiCall.data)'" -ErrorId 1
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
        Write-Error -Message "There was an error fetching available API commands: '$($apiCall.data)'" -ErrorId 1
    }

}

<#
 # DNS Commands
 #>

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
        Write-Error -Message "There was an error fetching DNS records: '$($apiCall.data)'" -ErrorId 1
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
        [String]$comment="",
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [Bool]$force=$false
    )

    $record = $record.Trim()
    $type = $type.Trim()
    $value = $value.Trim()
    $comment = $comment.Trim()

    # TODO: Fix regex
    if (!($record -match '([A-Za-z0-9-]+(?(?!$)\.)){3,}')) { # http://bit.ly/1JGMUle
        Write-Error -Message "The record: '$record' is not valid" -ErrorId 1
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

    if ($force -or (BinaryQuestion "Are you sure want to add the following record: $record | $type | $value")) {

        $args = @{"record" = $record; "type" = $type; "value" = $value}
        if ($comment) {$args.Add("comment", $comment)}

        $apiCall = API-Execute -apiKey $apiKey -command dns-add_record -args $args

        if ($apiCall.result -eq "success") {
            Write-Host "Record successfully added"
        } else {
            Write-Error -Message "There was an error adding the DNS record: '$($apiCall.data)'" -ErrorId 1
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
        Write-Error -Message "The record: '$record' is not valid" -ErrorId 1
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

    if ($force -or (BinaryQuestion "Are you sure want to remove the following record: $record | $type | $value")) {

        $apiCall = API-Execute -apiKey $apiKey -command dns-remove_record -args @{"record" = $record; "type" = $type; "value" = $value}

        if ($apiCall.result -eq "success") {
            Write-Host "Record successfully removed"
        } else {
            Write-Error -Message "There was an error removing the DNS record: '$($apiCall.data)'" -ErrorId 1
        }

    }

}

<#
 # Account Commands
 #>

Function Account-DomainUsage {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$apiKey
    )

    $apiCall = API-Execute -apiKey $apiKey -command account-domain_usage

    if ($apiCall.result -eq "success") {

        $result = @()
    
        $apiCall.data | %{

            $row = New-Object System.Object
            $row | Add-Member -MemberType NoteProperty -Name "Domain" -Value $_.domain
            $row | Add-Member -MemberType NoteProperty -Name "Type" -Value $_.type
            $row | Add-Member -MemberType NoteProperty -Name "Bandwidth" -Value $_.bw
            $result += $row

        }

        return $result

    } else {
        Write-Error -Message "There was an error fetching domain usage: '$($apiCall.data)'" -ErrorId 1
    }

}

Function Account-ListKeys {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$apiKey
    )

    $apiCall = API-Execute -apiKey $apiKey -command account-list_keys

    if ($apiCall.result -eq "success") {

        $result = @()
    
        $apiCall.data | %{

            $row = New-Object System.Object
            $row | Add-Member -MemberType NoteProperty -Name "Name" -Value $_.key_name
            $row | Add-Member -MemberType NoteProperty -Name "Value" -Value $_.key_val
            $result += $row

        }

        if ($result.Count -eq 0) {
            Write-Host "No keys were found"
        } else {
            return $result
        }

    } else {
        Write-Error -Message "There was an error fetching account keys: '$($apiCall.data)'" -ErrorId 1
    }

}

Function Account-Status {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$apiKey
    )

    $apiCall = API-Execute -apiKey $apiKey -command account-status

    if ($apiCall.result -eq "success") {

        $result = @()
    
        $apiCall.data | %{

            $row = New-Object System.Object
            $row | Add-Member -MemberType NoteProperty -Name "Meta" -Value $_.key
            $row | Add-Member -MemberType NoteProperty -Name "Value" -Value $_.value
            $result += $row

        }

        return $result

    } else {
        Write-Error -Message "There was an error fetching account status: '$($apiCall.data)'" -ErrorId 1
    }

}

Function Account-UserUsage {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$apiKey
    )

    $apiCall = API-Execute -apiKey $apiKey -command account-user_usage

    if ($apiCall.result -eq "success") {

        $result = @()
    
        $apiCall.data | %{

            $row = New-Object System.Object
            $row | Add-Member -MemberType NoteProperty -Name "User" -Value $_.user
            $row | Add-Member -MemberType NoteProperty -Name "Disk" -Value $_.disk
            $row | Add-Member -MemberType NoteProperty -Name "LastChecked" -Value $_.disk_as_of
            $row | Add-Member -MemberType NoteProperty -Name "Bandwidth" -Value $_.bw
            $result += $row

        }

        return $result

    } else {
        Write-Error -Message "There was an error fetching user usage: '$($apiCall.data)'" -ErrorId 1
    }

}

<#
 # MySQL Commands
 #>

Function MySQL-ListDatabases {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$apiKey
    )

    $apiCall = API-Execute -apiKey $apiKey -command mysql-list_dbs

    if ($apiCall.result -eq "success") {

        $result = @()
    
        $apiCall.data | %{

            $row = New-Object System.Object
            $row | Add-Member -MemberType NoteProperty -Name "AccountID" -Value $_.account_id
            $row | Add-Member -MemberType NoteProperty -Name "Database" -Value $_.db
            $row | Add-Member -MemberType NoteProperty -Name "Description" -Value $_.description
            $row | Add-Member -MemberType NoteProperty -Name "DiskUsageMB" -Value $_.disk_usage_mb
            $result += $row

        }

        return $result

    } else {
        Write-Error -Message "There was an error fetching database list: '$($apiCall.data)'" -ErrorId 1
    }

}

Function MySQL-ListHostnames {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$apiKey
    )

    $apiCall = API-Execute -apiKey $apiKey -command mysql-list_hostnames

    if ($apiCall.result -eq "success") {

        $result = @()
    
        $apiCall.data | %{

            $row = New-Object System.Object
            $row | Add-Member -MemberType NoteProperty -Name "AccountID" -Value $_.account_id
            $row | Add-Member -MemberType NoteProperty -Name "Domain" -Value $_.domain
            $row | Add-Member -MemberType NoteProperty -Name "Home" -Value $_.home
            $result += $row

        }

        return $result

    } else {
        Write-Error -Message "There was an error fetching database hostnames: '$($apiCall.data)'" -ErrorId 1
    }

}

Function MySQL-ListUsers {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$apiKey
    )

    $apiCall = API-Execute -apiKey $apiKey -command mysql-list_users

    if ($apiCall.result -eq "success") {

        $result = @()
    
        $apiCall.data | %{

            $row = New-Object System.Object
            $row | Add-Member -MemberType NoteProperty -Name "AccountID" -Value $_.account_id
            $row | Add-Member -MemberType NoteProperty -Name "Database" -Value $_.db
            $row | Add-Member -MemberType NoteProperty -Name "Home" -Value $_.home
            $row | Add-Member -MemberType NoteProperty -Name "Username" -Value $_.username
            $row | Add-Member -MemberType NoteProperty -Name "Host" -Value $_.host
            $row | Add-Member -MemberType NoteProperty -Name "Select" -Value $_.select_priv
            $row | Add-Member -MemberType NoteProperty -Name "Insert" -Value $_.insert_priv
            $row | Add-Member -MemberType NoteProperty -Name "Update" -Value $_.update_priv
            $row | Add-Member -MemberType NoteProperty -Name "Delete" -Value $_.delete_priv
            $row | Add-Member -MemberType NoteProperty -Name "Create" -Value $_.create_priv
            $row | Add-Member -MemberType NoteProperty -Name "Drop" -Value $_.drop_priv
            $row | Add-Member -MemberType NoteProperty -Name "Index" -Value $_.index_priv
            $row | Add-Member -MemberType NoteProperty -Name "Alter" -Value $_.alter_priv
            $result += $row

        }

        return $result

    } else {
        Write-Error -Message "There was an error fetching database usernames: '$($apiCall.data)'" -ErrorId 1
    }

}

Function MySQL-AddUser {

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
        [String]$database,
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$user,
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$password,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$hostnames="%.dreamhost.com",
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$select,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$insert,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$update,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$delete,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$create,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$drop,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$index,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$alter,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [Bool]$force=$false
    )

    $hostnamesArray = @()
    $hostnames.Split(",") | %{
        
        $hostname = $_
        $hostname = $hostname -replace "\*", "%"

        if ((
            $hostname -match '^(?:(?:2(?:5[0-5]|[0-4]\d)|1\d{2}|[1-9]\d|\d)(?:\.(?=\d))?){4}$(?#http://bit.ly/1n3IDyy)'
        ) -or (
            $hostname -match '^(?>(?(R)[A-Za-z\d][A-Za-z\d-]*|(?:\%(?=\.)|[A-Za-z\d][A-Za-z\d-]*))(?:\.(?=[A-Za-z\d]))?){3,}$(?#http://bit.ly/1n3N2S8)'
        )) {
            $hostnamesArray += $hostname
        } else {
            Write-Error -Message "The hostname '$hostname' is invalid" -ErrorId 1
        }

    }

    if ($hostnamesArray.Length -gt 0) {
        $hostnames = $hostnamesArray -join "`n"
    } else {

        Write-Error -Message "No valid hostname was provided.`nAborting..." -ErrorId 1
        return

    }

    $privileges = @(
        "select",
        "insert",
        "update",
        "delete",
        "create",
        "drop",
        "index",
        "alter"
    )

    $yes = $false; # Tracks the select of at least one 'y' choice

    $MyInvocation.MyCommand.Parameters.GetEnumerator() | %{

        $key = $_.Key
        
        if ($privileges -contains $key) {

            $value = (Get-Variable -Name $key).Value
            Set-Variable -Name $key -Value $value.Trim()
            $value = (Get-Variable -Name $key).Value.ToUpper()
            
            if ($value -ne "y" -and $value -ne "n") {

                Set-Variable -Name $key -Value @{$true="Y";$false="N"}[(
                    $Host.UI.PromptForChoice(
                        "MySQL Privilege",
                        "Do you want to grant '$key' privilege for user $($user)?",
                        [System.Management.Automation.Host.ChoiceDescription[]](
                            (New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Grant $key privilege"),
                            (New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do NOT grant $key privilege")
                        ),
                        0
                    )
                ) -eq "0"]
                
                if ((Get-Variable -Name $key).Value -eq "y") {$yes = $true}

            }

        }

    }

    if ($yes -or ($force -or (BinaryQuestion "You have not selected at least one 'Y' privilege. Do you still want to add this user?"))) {

        $message = "Are you sure you want to add the MySQL user '$user':`n"+
        "  Database: $database`n"+
        "  Hostnames:`n    "+ ($hostnamesArray -join "`n    ")+ "`n"+
        "  Select: $select`n"+
        "  Insert: $insert`n"+
        "  Update: $update`n"+
        "  Delete: $delete`n"+
        "  Create: $create`n"+
        "  Drop: $drop`n"+
        "  Index: $index`n"+
        "  Alter: $alter"

        if (BinaryQuestion $message) {
        
            $apiCall = API-Execute -apiKey $apiKey -command mysql-add_user -args @{
                "db"=$database;
                "user"=$user;
                "password"=$password;
                "select"=$select;
                "insert"=$insert;
                "update"=$update;
                "delete"=$delete;
                "create"=$create;
                "drop"=$drop;
                "index"=$index;
                "alter"=$alter;
                "hostnames"=$hostnames
            }

            if ($apiCall.result -eq "success") {
                Write-Host "MySQL user successfully added"
            } else {
                Write-Error -Message "There was an error adding the MySQL user: '$($apiCall.data)'" -ErrorId 1
            }

        }

    } else {
        Write-Host "MySQL user has not been added"
    }

}