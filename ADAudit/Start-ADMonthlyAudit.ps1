$accounts = Search-ADAccount -PasswordNeverExpires -UsersOnly -SearchBase "dc=thisisglobal,dc=com" -SearchScope Subtree | gm -force


ForEach ($account in $accounts) {
    $user = Get-ADUser -Identity $account.SamAccountName -Properties employeeType
    #If ($user.emploeeType


}
 
Search-ADAccount -PasswordNeverExpires -UsersOnly -SearchBase "OU=admin,dc=thisisglobal,dc=com" -SearchScope OneLevel | FT Name, psobject.Properties.employeeType


