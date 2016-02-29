Import-Module ActiveDirectory  
 
$schema = Get-ADObject -Filter * -SearchBase ((Get-ADRootDSE).schemaNamingContext) -SearchScope OneLevel -Property objectClass, name, whenChanged, whenCreated, attributeID | Select-Object objectClass, attributeID, name, whenCreated, whenChanged, @{name="event";expression={($_.whenCreated).Date.ToString("yyyy-MM-dd")}} | Sort-Object event, objectClass, name 
"`nDetails of schema objects created by date:" 
$schema | Format-Table objectClass, attributeID, name, whenCreated, whenChanged -GroupBy event -AutoSize 
 
"`nCount of schema objects created by date:" 
$schema | Group-Object event | Format-Table Count, Name, Group -AutoSize 
 
$schema | Export-CSV .\schema.csv -NoTypeInformation 
"`nSchema CSV output here: .\schema.csv" 
 
#------------------------------------------------------------------------------ 
 
"`nForest domain creation dates:"
Get-ADObject -SearchBase (Get-ADForest).PartitionsContainer -LDAPFilter "(&(objectClass=crossRef)(systemFlags=3))" -Property dnsRoot, nETBIOSName, whenCreated | Sort-Object whenCreated | Format-Table dnsRoot, nETBIOSName, whenCreated -AutoSize
 
#------------------------------------------------------------------------------ 
 
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
 
$SchemaPartition = (Get-ADRootDSE).NamingContexts | Where-Object {$_ -like "*Schema*"} 
$SchemaVersionAD = (Get-ADObject $SchemaPartition -Property objectVersion).objectVersion 
$SchemaVersions += 1 | Select-Object @{name="Product";expression={"AD"}}, @{name="Schema";expression={$SchemaVersionAD}}, @{name="Version";expression={$SchemaHashAD.Item($SchemaVersionAD)}} 
 
#------------------------------------------------------------------------------ 
 
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
    15137="Exchange 2013 RTM" 
    } 
 
$SchemaPathExchange = "CN=ms-Exch-Schema-Version-Pt,$SchemaPartition" 
If (Test-Path "AD:$SchemaPathExchange") { 
    $SchemaVersionExchange = (Get-ADObject $SchemaPathExchange -Property rangeUpper).rangeUpper 
} Else { 
    $SchemaVersionExchange = 0 
} 
 
$SchemaVersions += 1 | Select-Object @{name="Product";expression={"Exchange"}}, @{name="Schema";expression={$SchemaVersionExchange}}, @{name="Version";expression={$SchemaHashExchange.Item($SchemaVersionExchange)}} 
 
#------------------------------------------------------------------------------ 
 
$SchemaHashLync = @{ 
    1006="LCS 2005"; 
    1007="OCS 2007 R1"; 
    1008="OCS 2007 R2"; 
    1100="Lync Server 2010"; 
    1150="Lync Server 2013" 
    } 
 
$SchemaPathLync = "CN=ms-RTC-SIP-SchemaVersion,$SchemaPartition" 
If (Test-Path "AD:$SchemaPathLync") { 
    $SchemaVersionLync = (Get-ADObject $SchemaPathLync -Property rangeUpper).rangeUpper 
} Else { 
    $SchemaVersionLync = 0 
} 
 
$SchemaVersions += 1 | Select-Object @{name="Product";expression={"Lync"}}, @{name="Schema";expression={$SchemaVersionLync}}, @{name="Version";expression={$SchemaHashLync.Item($SchemaVersionLync)}} 
 
#------------------------------------------------------------------------------ 
 
"`nKnown current schema version of products:" 
$SchemaVersions | Format-Table * -AutoSize 
 
#---------------------------------------------------------------------------sdg 
 