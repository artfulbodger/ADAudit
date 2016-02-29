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