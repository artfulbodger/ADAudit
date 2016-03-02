
#>
function Get-privilegedUserReport
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Param1,

        # Param2 help description
        [int]
        $Param2
    )

    Begin
    {
    }

    Process
    {
    }
    End
    {
    }
}

<#
.Synopsis
   Compiles a list of AD Accounts which have not logged on during the inactive days value
.EXAMPLE
   Get-StaleADAccounts -dc "dc1.contoso.com"
.EXAMPLE
   Get-StaleADAccounts -dc "dc1.contoso.com" -inactivedays 90
#>

function Get-StaleADAccounts
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Domain Controller to use
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $dc,
        
        # Number of inactive days
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        $inactivedays = 180
    )

    Begin
    {
        $staleusers = $null
        $staleusers = @()
        $now = Get-Date
        $inactivedate = $now.AddDays($inactivedays *-1)

        Get-ADSession -domainController $dc

    }
    Process
    {
        $inactiveaccountlist = Search-RMADAccount -AccountInactive -DateTime $inactivedate -usersonly
        ForEach ($inactiveaccount in $inactiveaccountlist) {
            $linemanager = $null
            $startdate = $null
            $lastlogon = $null
            $currentuser = $null
            $currentuser = Get-RMaduser -Identity $inactiveaccount.SamAccountName -Properties employeeType, employeeID, manager, LastLogonTimestamp, displayName, title, l, department, manager, globalradioStartDate, department
            If ($currentuser.employeeID -ne $null -And [DateTime]::FromFileTime($currentuser.globalradioStartDate) -lt $inactivedate) {
                If($currentuser.globalradioStartDate -ne $Null){
                    $startdate = [DateTime]::FromFileTime($currentuser.globalradioStartDate).ToString("dd/MM/yyyy")
                } else {
                    $startdate = "No Start Date Found"
                }
                If($currentuser.LastLogonTimestamp -ne $Null){
                    $lastlogon = [DateTime]::FromFileTime($currentuser.LastLogonTimestamp)
                } else {
                    $lastlogon = "Never Logged On"
                }
                $linemanager = Get-LineManager -user $inactiveaccount.SamAccountName -dc $dc
                $staleusers += [pscustomobject]@{"Name" = $currentuser.displayName; "Job Title" = $currentuser.title; "Staff Number" = $currentuser.employeeID;"Line Manager" = $linemanager.name; "Location" = $currentuser.l; "Department" = $currentuser.Department; "Start Date" = $startdate; "Last Logon" = $lastlogon}
            }
        }
        
        Try
        {
            Send-ReportEmail -bodydata $staleusers -bodytext "The following staff have not used their account in the past $inactivedays days" -SmtpServer "smtpinternal2.thisisglobal.com" -FromEmailAddress "soc@thisisglobal.com" -ToEmailAddress "richard.carpenter@thisisglobal.com" -EmailSubject "AD Audit - Stale Users"
        }
        Catch [Microsoft.PowerShell.Commands.SendMailMessage]
        {

        }

    }
    End
    {
        Remove-ADSession -domainController $dc
    }
}

<#
.Synopsis
   Compiles a list of AD Accounts with Password set to Never Expire
.DESCRIPTION
   Long description
.EXAMPLE
   Get-PasswordNeverExpires -dc "dc1.contoso.com"
#>
function Get-PasswordNeverExpires
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
       # Domain Controller to use
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $dc
    )

    Begin
    {
        Get-ADSession -domainController $dc
        $failedaudit = @()
    }
    Process
    {
        $PasswordAccountList = Search-RMADAccount -PasswordNeverExpires -UsersOnly
        $usercount = $PasswordAccountList.count
        
        Write-Verbose "Discovered $usercount AD Accounts with password set to Never Expire"
                
        foreach ($user in $PasswordAccountList) {
            $currentuser = Get-RMADUser -Identity $user.samAccountName -Properties employeeType, manager, mail, l, pwdLastSet
            If (($currentuser.employeeType -ne "Generic Account") -and ($currentuser.employeeType -ne "Resource - Room") -and ($currentuser.employeeType -ne "Resource - Shared Mailbox") -and ($currentuser.employeeType -ne "Resource - Equipment") -and ($currentuser.employeeType -ne "Resource - Shared Calendar")   -and ($currentuser.employeeType -ne "Service") -and ($currentuser.employeeType -ne "Service Account") -and ($currentuser.employeeType -ne "iPad WiFi User") -and ($currentuser.employeeType) -and ($currentuser.employeeType -ne "CUCM User")) {
                If ($currentuser.manager) {
                    $LineManager = Get-LineManager -user $currentuser.manager -dc $dc
                    $usercheck = [pscustomobject]@{"DisplayName" = $currentuser.Name; "Employee Type" = $currentuser.employeeType; "Line Manager" = $linemanager.name; "Email" = $currentuser.mail; "Location" = $currentuser.l; "Password Last Changed" = [DateTime]::FromFileTimeutc($currentuser.pwdLastSet)}
                } else {
                    $usercheck = [pscustomobject]@{"DisplayName" = $currentuser.Name; "Employee Type" = $currentuser.employeeType; "Line Manager" = ""; "Email" = $currentuser.mail; "Location" = $currentuser.l; "Password Last Changed" = [DateTime]::FromFileTimeutc($currentuser.pwdLastSet)}
                }
                $failedaudit += $usercheck
            }
        }

        Try
        {
            Send-ReportEmail -bodydata $failedaudit -bodytext "The following accounts currently are set with 'Passwords that never expire'." -SmtpServer "smtpinternal2.thisisglobal.com" -FromEmailAddress "soc@thisisglobal.com" -ToEmailAddress "richard.carpenter@thisisglobal.com" -EmailSubject "AD Audit - Passwords never Expire"
        }
        Catch
        {

        }

    }
    End
    {
        Remove-ADSession -domainController $dc
    }
}

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
function Get-ADSchemaVersions
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Domain Controller to use
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $dc
    )

    Begin
    {
        Get-ADSession -domainController $dc
        $SchemaVersions = @()
        $SchemaHashAD = @{ 
            13="Windows 2000 Server"; 
            30="Windows Server 2003 RTM"; 
            31="Windows Server 2003 R2"; 
            44="Windows Server 2008 RTM"; 
            47="Windows Server 2008 R2"; 
            56="Windows Server 2012 RTM"; 
            69="Windows Server 2012 R2" 
        }
        $SchemaHashExchange = @{ 
            4397="Exchange Server 2000 RTM"; 
            4406="Exchange Server 2000 SP3"; 
            6870="Exchange Server 2003 RTM"; 
            6936="Exchange Server 2003 SP3"; 
            10628="Exchange Server 2007 RTM"; 
            10637="Exchange Server 2007 RTM"; 
            11116="Exchange 2007 SP1"; 
            14622="Exchange 2007 SP2 or Exchange 2010 RTM"; 
            14625="Exchange 2007 SP3"; 
            14726="Exchange 2010 SP1"; 
            14732="Exchange 2010 SP2"; 
            14734="Exchange 2010 SP3"; 
            15137="Exchange 2013 RTM";
            15292="Exchange 2013 SP1"
        }
        $SchemaHashLync = @{ 
            1006="LCS 2005"; 
            1007="OCS 2007 R1"; 
            1008="OCS 2007 R2"; 
            1100="Lync Server 2010"; 
            1150="Lync Server 2013" 
        }
    }
    Process
    {
        $SchemaPartition = (Get-RMADRootDSE).NamingContexts | Where-Object {$_ -like "*Schema*"} 
        $SchemaVersionAD = (Get-RMADObject $SchemaPartition -Property objectVersion).objectVersion
        $SchemaVersionADDate = (Get-RMADObject $SchemaPartition -Property whenCreated).whenCreated
        $SchemaVersions += 1 | Select-Object @{name="Product";expression={"Active Directory"}}, @{name="Schema";expression={$SchemaVersionAD}}, @{name="Version";expression={$SchemaHashAD.Item($SchemaVersionAD)}}, @{name="Date";expression={$SchemaVersionADDate}}
        
        $SchemaPathExchange = "CN=ms-Exch-Schema-Version-Pt,$SchemaPartition" 
        If (Get-RMADObject $SchemaPathExchange) {
            $SchemaVersionExchange = (Get-RMADObject $SchemaPathExchange -Property rangeUpper).rangeUpper
            $SchemaVersionExchangeDate = (Get-RMADObject $SchemaPathExchange -Property whenChanged).whenChanged
        } Else { 
            $SchemaVersionExchange = 0 
        } 
        $SchemaVersions += 1 | Select-Object @{name="Product";expression={"Exchange"}}, @{name="Schema";expression={$SchemaVersionExchange}}, @{name="Version";expression={$SchemaHashExchange.Item($SchemaVersionExchange)}}, @{name="Date";expression={$SchemaVersionExchangeDate}}
        
        $SchemaPathLync = "CN=ms-RTC-SIP-SchemaVersion,$SchemaPartition" 
        If (Get-RMADobject $SchemaPathLync) { 
            $SchemaVersionLync = (Get-RMADObject $SchemaPathLync -Property rangeUpper).rangeUpper
            $schemaVersionLyncDate = (Get-RMADObject $SchemaPathLync -Property whenChanged).whenChanged
        } Else { 
            $SchemaVersionLync = 0 
        }
        $SchemaVersions += 1 | Select-Object @{name="Product";expression={"Lync"}}, @{name="Schema";expression={$SchemaVersionLync}}, @{name="Version";expression={$SchemaHashLync.Item($SchemaVersionLync)}}, @{name="Date";expression={$schemaVersionLyncDate}}
    }
    End
    {
        If ($schemaversions.count -ge 1) {
            #We have Schema data to send
            Send-ReportEmail -bodydata $schemaversions -bodytext "Please find detailed below the Schema summary for your domain" -SmtpServer "smtpinternal2.thisisglobal.com" -FromEmailAddress "soc@thisisglobal.com" -ToEmailAddress "richard.carpenter@thisisglobal.com" -EmailSubject "Active Directory Schema Summary Report"
        } else {
            # We dont have any Schema Data
            Send-ReportEmail -bodytext "We were unable to discover any Schema Data this time" -SmtpServer "smtpinternal2.thisisglobal.com" -FromEmailAddress "soc@thisisglobal.com" -ToEmailAddress "richard.carpenter@thisisglobal.com" -EmailSubject "Active Directory Schema Summary Report"
        }
        Remove-ADSession -domainController $dc
    }
}

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
        $user,

        # Domain Controller to use
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        $dc
    )

    Begin
    {
        Get-ADSession -domainController $dc
    }
    Process
    {
        $tempuser = Get-RMADUser -Identity $user -Properties manager
        If($tempuser.manager -ne $null){
            $lm = Get-RMADUser -Identity $tempuser.manager
            Return $lm
        } else {
            Return $null
        }
    }
    End
    {
    }
}

<#
.Synopsis
   Creates a new PSSession to A Domain Controller
.DESCRIPTION
   Long description
.EXAMPLE
   Get-ADSession -domainController 'dc1.contoso.com'
#>
function Get-ADSession
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Domain Controller to use
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $domainController
    )

    Begin
    {
    }
    Process
    {
        $adsession = $false
        $remoteSessionList = Get-PSSession -ComputerName $domainController
        Foreach($remoteSession in $remoteSessionList) {
            If($remoteSession.Name -eq 'ActiveDirectory'){
                $adsession = $true
                break
            }
        }

        If($adsession -eq $false){
            $Session = New-PSsession -Computername $dc -Name ActiveDirectory
            # Use the newly created remote Powershell session to send a #command to that session
            Invoke-Command -Command {Import-Module ActiveDirectory} -Session $Session
            # Use that session with the modules to add the available # commandlets to your existing Powershell command shell with a #new command name prefix.
            Import-PSSession -Session $Session -Module ActiveDirectory -Prefix RM -AllowClobber
        }

    }
    End
    {
    }
}

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
function Remove-ADSession
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Domain Controller to use
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $domainController
    )

    Begin
    {
    }
    Process
    {
        $remoteSessionList = Get-PSSession -ComputerName $domainController
        Foreach($remoteSession in $remoteSessionList) {
            If($remoteSession.Name -eq 'ActiveDirectory'){
                Remove-PSSession -Name ActiveDirectory
                break
            }
        }
    }
    End
    {
    }
}

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
function Send-ReportEmail
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Data table to be rendered in report
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $bodydata,

        # Report text that appears before data table
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        $bodytext,

        # SMTP server for sending Mail
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        $SmtpServer,

        # From Email Address
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        $FromEmailAddress,

        # To Email Address
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=4)]
        $ToEmailAddress,

        # Subject
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=5)]
        $EmailSubject
    )

    Begin
    {
        $style = $null
        $style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
        $style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
        $style = $style + "TH{border: 1px solid black; background: #2f84c6; padding: 5px; color: #fff }"
        $style = $style + "TD{border: 1px solid black; padding: 5px; } .red { background-color: #f00;}"
        $style = $style + "</style>"
    }
    Process
    {
        $body = $bodydata | ConvertTo-Html -Head $style -PreContent "<p>$bodytext</p>"
        Send-MailMessage -SmtpServer $SmtpServer -From $FromEmailAddress -to $ToEmailAddress -Subject $EmailSubject -BodyAsHtml -Body "$body"
    }
    End
    {
        
    }
}