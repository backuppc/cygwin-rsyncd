#--------- Edit these lines appropriately for your site
$Domain = "yourdomain.com"
$EmailFrom = $env:USERNAME + "@" + $Domain
$EmailTo = "admin@" + $Domain
$Subject = "NEW PC client for BackupPC"
$SMTPServer = "mail." + $Domain
$SMTPServPort = 25
#--------- End edit
#
$OSName = Get-WmiObject -Class Win32_OperatingSystem | ForEach-Object -MemberName Caption
$Body = "Dear admin, `n`n"
$Body += "User '" + $env:USERNAME + "' is logged on '" + $env:COMPUTERNAME + "' a " + $OSName + " computer.`n`n"
$Body += "            BackupPC V3.1.2.0a installer."
#
Send-MailMessage -From $EmailFrom -Subject $Subject -To $EmailTo -Body $Body -SmtpServer $SMTPServer -Port $SMTPServPort
