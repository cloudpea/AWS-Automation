#Create Temp Directory 
New-Item -ItemType directory -Path C:\\Temp

#Install Google Chrome 
Invoke-WebRequest -Uri http://dl.google.com/chrome/install/375.126/chrome_installer.exe -OutFile C:\\Temp\\Chrome.Installer.x64.exe
C:\\Temp\\Chrome.Installer.x64.exe /silent /install
SLEEP 30

#Install Notepad++                   
Invoke-WebRequest -Uri https://notepad-plus-plus.org/repository/7.x/7.2/npp.7.2.Installer.x64.exe -OutFile 'C:\\Temp\\Notepad++.exe'
start C:\\Temp\\Notepad++.exe /S
SLEEP 30

#Download Putty
Invoke-WebRequest -Uri https://the.earth.li/~sgtatham/putty/latest/w64/putty.exe -OutFile 'C:\\Temp\\Putty.Installer.x64.exe'

#Create Putty Desktop Shortcut
$TargetFile = 'C:\\Temp\\Putty.Installer.x64.exe'
$ShortcutFile = 'C:\\Users\\Public\\Desktop\\Putty.lnk'
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()