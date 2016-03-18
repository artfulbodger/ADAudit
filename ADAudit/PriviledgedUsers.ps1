 
##################   Function to Expand Group Membership ################ 
function getMemberExpanded 
{
    param ($dn) 
               
    $adobject = [adsi]"LDAP://$dn" 
    $colMembers = $adobject.properties.item("member") 
    
    Foreach ($objMember in $colMembers) 
    { 
        $objMembermod = $objMember.replace("/","\/") 
        $objAD = [adsi]"LDAP://$objmembermod" 
        $attObjClass = $objAD.properties.item("objectClass") 
        
        if ($attObjClass -eq "group") 
        { 
            getmemberexpanded $objMember            
        }    
        else 
        { 
            $colOfMembersExpanded += ,$objMember 
        } 
    }     
$colOfMembersExpanded  
}     
 
########################### Function to Calculate Password Age ############## 
Function getUserAccountAttribs 
{ 
    param($objADUser,$parentGroup) 
    
    $objADUser = $objADUser.replace("/","\/") 
    $adsientry=new-object directoryservices.directoryentry("LDAP://$objADUser") 
    $adsisearcher=new-object directoryservices.directorysearcher($adsientry) 
    $adsisearcher.pagesize=1000
    $adsisearcher.searchscope="base" 
    $colUsers=$adsisearcher.findall() 
    
    foreach($objuser in $colUsers) 
    { 
        $dn=$objuser.properties.item("distinguishedname") 
        $sam=$objuser.properties.item("samaccountname") 
        $attObjClass = $objuser.properties.item("objectClass") 
        
        If ($attObjClass -eq "user") 
        { 
            $description=$objuser.properties.item("description") 
            $lastlogontimestamp=$objuser.properties.item("lastlogontimestamp") 
            $accountexpiration=$objuser.properties.item("accountexpires") 
            $pwdLastSet=$objuser.properties.item("pwdLastSet")
            $displayName=$objuser.properties.item("displayName")
            
            if ($pwdLastSet -gt 0) 
            { 
                $pwdLastSet=[datetime]::fromfiletime([int64]::parse($pwdLastSet)) 
                $PasswordAge=((get-date) - $pwdLastSet).days 
            } 
            Else
            {
                $PasswordAge = "<Not Set>"
            }                                                                         
            
            $uac=$objuser.properties.item("useraccountcontrol") 
            $uac=$uac.item(0) 
            
            if (($uac -bor 0x0002) -eq $uac)
            {
                $disabled="TRUE"
            } 
            else
            {
                $disabled = "FALSE"
            } 
            
            if (($uac -bor 0x10000) -eq $uac)
            {
                $passwordneverexpires="TRUE"
            } 
            else
            {
                $passwordNeverExpires = "FALSE"
            }

            If (($uac -bor 0x100000) -eq $uac)
            {
                $sensitive = "TRUE"
            }
            else
            {
                $sensitive = "FALSE"
            }
            
            If ($lastlogontimestamp -gt 0)
            {
                $lastlogontimestamp=[datetime]::fromfiletime([int64]::parse($lastlogontimestamp))
            }
            else
            {
                $lastlogontimestamp = "<Not Set>"
            }
        }
                                                                                 
        #Build the return object
        $record = "" | select-object SAM,DN,MemberOf,pwdAge,disabled,pWDneverExpires,displayName,lastlogon,sensitive
        $record.SAM = [string]$sam 
        $record.DN = [string]$dn 
        $record.memberOf = [string]$parentGroup 
        $record.pwdAge = $PasswordAge 
        $record.disabled= $disabled 
        $record.pWDneverExpires = $passwordNeverExpires
        $record.displayName = [string]$displayName
        $record.lastlogon = $lastlogontimestamp
        $record.sensitive = $sensitive                  
    }  
$record 
} 

####### Function to find all Privileged Groups in the Forest ########## 
Function getForestPrivGroups 
{ 
    $colOfDNs = @() 
    $Forest = [System.DirectoryServices.ActiveDirectory.forest]::getcurrentforest() 
    $RootDomain = [string]($forest.rootdomain.name) 
    $forestDomains = $forest.domains 
    $colDomainNames = @() 
    
    ForEach ($domain in $forestDomains) 
    { 
        $domainname = [string]($domain.name) 
        $colDomainNames += $domainname 
    } 
    
    $ForestRootDN = FQDN2DN $RootDomain 
    $colDomainDNs = @() 
    
    ForEach ($domainname in $colDomainNames) 
    { 
        $domainDN = FQDN2DN $domainname 
        $colDomainDNs += $domainDN     
    } 
 
    $GC = $forest.FindGlobalCatalog() 
    $adobject = [adsi]"GC://$ForestRootDN" 
    $RootDomainSid = New-Object System.Security.Principal.SecurityIdentifier($AdObject.objectSid[0], 0) 
    $RootDomainSid = $RootDomainSid.toString() 
    $colDASids = @() 
    
    ForEach ($domainDN in $colDomainDNs)
    { 
        $adobject = [adsi]"GC://$domainDN"
        $DomainSid = New-Object System.Security.Principal.SecurityIdentifier($AdObject.objectSid[0], 0)
        $DomainSid = $DomainSid.toString()
        $daSid = "$DomainSID-512"
        $colDASids += $daSid
    } 

    $colPrivGroups = @("S-1-5-32-544";"S-1-5-32-548";"S-1-5-32-549";"S-1-5-32-551";"$rootDomainSid-519";"$rootDomainSid-518") 
    $colPrivGroups += $colDASids
    $searcher = $gc.GetDirectorySearcher() 
    
    ForEach($privGroup in $colPrivGroups) 
    { 
        $searcher.filter = "(objectSID=$privGroup)" 
        $Results = $Searcher.FindAll() 
        
        ForEach ($result in $Results) 
        { 
            $dn = $result.properties.distinguishedname 
            $colOfDNs += $dn
        }
    } 
$colofDNs 
} 
 
########################## Function to Generate Domain DN from FQDN ######## 
Function FQDN2DN 
{ 
    Param ($domainFQDN) 
    $colSplit = $domainFQDN.Split(".") 
    $FQDNdepth = $colSplit.length 
    $DomainDN = "" 
    
    For ($i=0;$i -lt ($FQDNdepth);$i++) 
    { 
        
        If ($i -eq ($FQDNdepth - 1))
        {
            $Separator=""
        } 
        else
        {
            $Separator=","
        } 
        
        [string]$DomainDN += "DC=" + $colSplit[$i] + $Separator 
    } 
    
    $DomainDN 
} 
 
########################## MAIN ########################### 

$forestPrivGroups = GetForestPrivGroups 
$colAllPrivUsers = @()
$messagebody = $null

$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #2f84c6; padding: 5px; color: #fff }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"
 
$rootdse=new-object directoryservices.directoryentry("LDAP://rootdse") 
 
Foreach ($privGroup in $forestPrivGroups) 
{ 
    $auditusers = $null
    $privGroupName = $null
    $auditusers = @()
    $uniqueMembers = @() 
    $colOfMembersExpanded = @() 
    $colofUniqueMembers = @() 
    $members = getmemberexpanded $privGroup
    $privGroupName = $privGroup.Split(",")[0].substring(3) 
                
    If ($members) 
    { 
        $uniqueMembers = $members | sort-object -unique 

        Foreach ($uniqueMember in $uniqueMembers) 
        { 
            $objAttribs = getUserAccountAttribs $uniqueMember $privGroup 
            $colOfuniqueMembers += $objAttribs       
        } 

        $colAllPrivUsers += $colOfUniqueMembers 

        ForEach($user in $colOfuniquemembers) 
        { 
            $currentUser = $null
            $currentUser = [pscustomobject]@{"DisplayName" = $user.displayName; "Logon Name" = $user.SAM; "Password Age" = $user.pwdAge; "Last Logon" = $user.lastlogon; "Disabled" = $user.disabled; "Password Never Expires" = $user.pWDneverExpires; "Delegation Protected" = $user.sensitive}
            $auditusers += $currentUser
        } 

        $messagebody += "<p><strong>$privGroupName</strong></p>"
        $messagebody += "<p>"
        $messagebody += $auditusers | ConvertTo-Html -head $style
        $messagebody += "</p>"

    } 
    else
    {
        $messagebody += "<p><strong>$privGroupName</strong></p>"
        $messagebody += "<p>This Priviledge currently has no members</p>"
    }
} 

Send-MailMessage -SmtpServer "smtpinternal2.thisisglobal.com" -From "adaudit@thisisglobal.com" -to "richard.carpenter@thisisglobal.com" -Subject "Audit - Priviledged Users" -BodyAsHtml "$messagebody"