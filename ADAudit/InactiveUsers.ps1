$now = get-date

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

$InactiveAccountList = $null
$InactiveAccountList = Search-ADAccount -AccountInactive -timespan 90 -UsersOnly

$inactiveaudit = $null
$inactiveaudit = @()
foreach ($user in $InactiveAccountList) {

    $currentuser = $null
    $LineManager = $null
    $usercheck = $null
    $days = $null
 

    $currentuser = Get-ADUser -Identity $user.samAccountName -Properties employeeType, manager, mail, l, lastLogonTimestamp, whenCreated
    If (($currentuser.employeeTypea -ne "Generic Account") -and ($currentuser.employeeType -ne "Resource - Room") -and ($currentuser.employeeType -ne "Resource - Shared Mailbox") -and ($currentuser.employeeType -ne "Resource - Equipment") -and ($currentuser.employeeType -ne "Resource - Shared Calendar")   -and ($currentuser.employeeType -ne "Service") -and ($currentuser.employeeType -ne "Service Account") -and ($currentuser.employeeType -ne "iPad WiFi User") -and ($currentuser.employeeType) -and ($currentuser.employeeType -ne "CUCM User")) {
        $days = $now - [DateTime]::FromFileTimeutc($currentuser.lastLogonTimestamp)
        If ($currentuser.manager) {
            $LineManager = Get-LineManager -user $currentuser.manager
            $usercheck = [pscustomobject]@{"DisplayName" = $currentuser.Name; "Employee Type" = $currentuser.employeeType; "Line Manager" = $linemanager.name; "Email" = $currentuser.mail; "Location" = $currentuser.l; "Created" = $currentuser.whenCreated;  "Last Logon" = [DateTime]::FromFileTimeutc($currentuser.lastLogonTimestamp); "Days since Logon" = $days.days}
        } else {
            $usercheck = [pscustomobject]@{"Dis$now = get-date
$complianceDays = 90

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

$InactiveAccountList = $null
$InactiveAccountList = Search-ADAccount -AccountInactive -timespan $complianceDays -UsersOnly

$inactiveaudit = $null
$inactiveaudit = @()
foreach ($user in $InactiveAccountList) {

    $currentuser = $null
    $LineManager = $null
    $usercheck = $null
    $days = $null
    $createdDays = $null

    $currentuser = Get-ADUser -Identity $user.samAccountName -Properties employeeType, manager, mail, l, lastLogonTimestamp, whenCreated
    If (($currentuser.employeeType -ne "Generic Account") -and ($currentuser.employeeType -ne "Resource - Room") -and ($currentuser.employeeType -ne "Resource - Shared Mailbox") -and ($currentuser.employeeType -ne "Resource - Equipment") -and ($currentuser.employeeType -ne "Resource - Shared Calendar")   -and ($currentuser.employeeType -ne "Service") -and ($currentuser.employeeType -ne "Service Account") -and ($currentuser.employeeType -ne "iPad WiFi User") -and ($currentuser.employeeType) -and ($currentuser.employeeType -ne "CUCM User")) {
        $days = $now - [DateTime]::FromFileTimeutc($currentuser.lastLogonTimestamp)
        $createdDays = $now - $currentuser.whenCreated
        Write-Host $createdDays.days
        If ($createdDays.days -ge $complianceDays) {
            If ($days.Days -ge $complianceDays) {
                If ($currentuser.lastLogonTimestamp -eq $null) {
                    $dayssincelogon = "Never"
                } else {
                    $dayssincelogon = $days.Days
                }
                If ($currentuser.manager) {
                    $LineManager = Get-LineManager -user $currentuser.manager
                    $usercheck = [pscustomobject]@{"DisplayName" = $currentuser.Name; "Employee Type" = $currentuser.employeeType; "Line Manager" = $linemanager.name; "Email" = $currentuser.mail; "Location" = $currentuser.l; "Created" = $currentuser.whenCreated;  "Last Logon" = [DateTime]::FromFileTimeutc($currentuser.lastLogonTimestamp); "Days since Logon" = $dayssincelogon}
                } else {
                    $usercheck = [pscustomobject]@{"DisplayName" = $currentuser.Name; "Employee Type" = $currentuser.employeeType; "Line Manager" = ""; "Email" = $currentuser.mail; "Location" = $currentuser.l; "Created" = $currentuser.whenCreated; "Last Logon" = [DateTime]::FromFileTimeutc($currentuser.lastLogonTimestamp); "Days since Logon" = $dayssincelogon}
                }
                $inactiveaudit += $usercheck
            }
        }
        
    }
}

$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #2f84c6; padding: 5px; color: #fff }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"

$bodydata = $inactiveaudit | sort "Days since Logon" -Descending | ConvertTo-Html -Head $style

$body = "<p>The following accounts currently appear to be inactive with no longon detected in 90 dyas.</p> $bodydata"

Send-MailMessage -SmtpServer "smtpinternal.thisisglobal.com" -From "adaudit@thisisglobal.com" -to "richard.carpenter@thisisglobal.com" -Subject "Audit - Inactive Accounts" -BodyAsHtml "$body"
playName" = $currentuser.Name; "Employee Type" = $currentuser.employeeType; "Line Manager" = ""; "Email" = $currentuser.mail; "Location" = $currentuser.l; "Created" = $currentuser.whenCreated; "Last Logon" = [DateTime]::FromFileTimeutc($currentuser.lastLogonTimestamp); "Days since Logon" = $days.days}
        }
        $usercheck
        $inactiveaudit += $usercheck
    }
}

$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #2f84c6; padding: 5px; color: #fff }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"

$bodydata = $inactiveaudit | sort "Days since Logon" -Descending | ConvertTo-Html -Head $style

$body = "<p>The following accounts currently appear to be inactive with no longon detected in 90 dyas.</p> $bodydata"
#$body = $body $failedaudit | ConvertTo-Html -Head $style

Send-MailMessage -SmtpServer "smtpinternal.thisisglobal.com" -From "adaudit@thisisglobal.com" -to "richard.carpenter@thisisglobal.com" -Subject "Audit - Inactive Accounts" -BodyAsHtml "$body"
