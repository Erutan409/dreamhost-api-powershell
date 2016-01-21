Function Credential-Add {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$key,
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
        [String]$meta,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$path=".\Credentials.txt"
    )

    $credentials = Credential-Get

    $credentials | %{
        
        if ($_.Key -eq $key) {Write-Error -Message "The key '$key' already exists" -ErrorAction Stop}
        if ($_.Meta -eq $meta) {Write-Error -Message "The meta '$meta' already exists" -ErrorAction Stop}

    }

    $row = New-Object System.Object
    $row | Add-Member -MemberType NoteProperty -Name "Key" -Value $key
    $row | Add-Member -MemberType NoteProperty -Name "Meta" -Value $meta
    $credentials += $row

    (ConvertTo-Json -InputObject $credentials) | Out-File -FilePath $path

    Write-Host "Key '$key' successfully added"

}

Function Credential-Get {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$meta,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$path=".\Credentials.txt"
    )

    $credentials = Get-Content -Path $path -Raw -ErrorAction SilentlyContinue

    if ($credentials -eq $null) {
        return ,@() # http://bit.ly/1ZB3Dha
    } else {

        $credentials = ($credentials | ConvertFrom-Json)

        if ($meta) {
            
            $credentials | %{
                
                if ($_.Meta -eq $meta) {
                    return $_.Key
                }

            }

        } else {
            return ,$credentials
        }
    }

}

Function Credential-Delete {

    [CmdletBinding()]
    Param(
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$key,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$meta,
        [parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$path=".\Credentials.txt"
    )

    $credentials = Credential-Get
    $new = @()

    if ($credentials.Length -gt 0) {

        if ($key -or $meta) {

            $credentials | %{

                if ((!$key -or $_.Key -ne $key) -and (!$meta -or $_.Meta -ne $meta)) {
                    $new += $_
                } else {

                    $key = $_.Key
                    $meta = $_.Meta

                }

            }

            if ($credentials.Length -ne $new.Length) {

                Remove-Item -Path $path

                $new | %{Credential-Add -key $_.Key -meta $_.Meta}

                Write-Host "Credential successfully removed: $key`: $meta"

            } else {
                Write-Error -Message "No credential was removed" -ErrorId 0
            }

        } else {
            Write-Error -Message "You must supply either -key or -meta to remove a credential" -ErrorId 0
        }

    } else {
        Write-Error -Message "There are no credentials currently saved in the path: $path"
    }

}