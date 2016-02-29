<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-LineManager
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # User samAccountName
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $user
    )

    Begin
    {
    }
    Process
    {
        Get-ADUser -Identity $user -Properties manager
    }
    End
    {
        Return $user.manager
    }
}

$PasswordAccountList = Search-ADAccount -PasswordNeverExpires -UsersOnly

$failedaudit = @()
foreach ($user in $PasswordAccountList) {

    $currentuser = Get-ADUser -Identity $user.samAccountName -Properties employeeType, manager, mail, l, pwdLastSet
    If (($currentuser.employeeType -ne "Generic Account") -and ($currentuser.employeeType -ne "Resource - Room") -and ($currentuser.employeeType -ne "Resource - Shared Mailbox") -and ($currentuser.employeeType -ne "Resource - Equipment") -and ($currentuser.employeeType -ne "Resource - Shared Calendar")   -and ($currentuser.employeeType -ne "Service") -and ($currentuser.employeeType -ne "Service Account") -and ($currentuser.employeeType -ne "iPad WiFi User") -and ($currentuser.employeeType) -and ($currentuser.employeeType -ne "CUCM User")) {
        If ($currentuser.manager) {
            $LineManager = Get-LineManager -user $currentuser.manager
            $usercheck = [pscustomobject]@{"DisplayName" = $currentuser.Name; "Employee Type" = $currentuser.employeeType; "Line Manager" = $linemanager.name; "Email" = $currentuser.mail; "Location" = $currentuser.l; "Password Last Changed" = [DateTime]::FromFileTimeutc($currentuser.pwdLastSet)}
        } else {
            $usercheck = [pscustomobject]@{"DisplayName" = $currentuser.Name; "Employee Type" = $currentuser.employeeType; "Line Manager" = ""; "Email" = $currentuser.mail; "Location" = $currentuser.l; "Password Last Changed" = [DateTime]::FromFileTimeutc($currentuser.pwdLastSet)}
        }
        $failedaudit += $usercheck
    }
}

$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #2f84c6; padding: 5px; color: #fff }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"

$bodydata = $failedaudit | ConvertTo-Html -Head $style
$body = "<p>The following accounts currently are set with 'Passwords that never expire'.</p> $bodydata"

Send-MailMessage -SmtpServer "smtpinternal.thisisglobal.com" -From "adaudit@thisisglobal.com" -to "richard.carpenter@thisisglobal.com" -Subject "Audit - Passwords never Expire" -BodyAsHtml "$body"