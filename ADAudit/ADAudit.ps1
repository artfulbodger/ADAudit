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
   Gets Active Direction Users which are not in use.
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-StaleUserReport
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
        Get-ADSession -domainController 'dsdc2.thisisglobal.com'
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
        

        $bodydatahtml = $bodydata | ConvertTo-Html -Head $style

        $body = "<p>$bodytext</p><p>$bodydatahtml</p>"
        #$body += $bodydatahtml

        Send-MailMessage -SmtpServer $SmtpServer -From $FromEmailAddress -to $ToEmailAddress -Subject $EmailSubject -BodyAsHtml -Body "$body"
    }
    End
    {
        
    }
}