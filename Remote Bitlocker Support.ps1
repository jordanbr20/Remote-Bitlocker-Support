$Cred = Get-Credential $env:USERNAME
$Computername = $txt_ComputerName.Text
$hostcomputer = $env:COMPUTERNAME

#------------------------------------------Scripts to run bitlocker--------------------------------------- 

function TPMONOROFF {
$Computername = $txt_ComputerName.Text
If ((Invoke-Command -ComputerName $ComputerName -ScriptBlock {(get-TPM).TpmPresent} -Credential $Cred) -eq "True") {
    $Information.Text += "`nTPM is on"
    } Else {
    $Information.Text += "`n`nPhase 1"
    $Information.Text += "`nTPM is Disabled"
    $Information.Text += "`nMoving CCTK.exe to remote computer"
    Copy-Item "\\$hostcomputer\c$\temp\CCTK" -Destination "\\$ComputerName\c$\temp\CCTK" -Recurse -Force;
    $Information.Text += "`nSuspending Bitlocker with 2 reboots allowed..."
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {Suspend-BitLocker -MountPoint "C:" -RebootCount 2} -Credential $Cred
    $Information.Text += "`nSetting TEMP TPM password"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {cmd /c powershell.exe C:\temp\CCTK\cctk.exe --setuppwd=abc123} -Credential $Cred
    $Information.Text += "`nTurning TPM on"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {cmd /c powershell.exe C:\temp\CCTK\cctk.exe --tpm=on --ValSetupPwd=abc123} -Credential $Cred
    $Information.Text += "`nDeleteing TEMP TPM password"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {cmd /c powershell.exe C:\temp\CCTK\cctk.exe --setuppwd= --valsetuppwd=abc123} -Credential $Cred
    $Information.Text += "`nComputer Restarting please wait 180 Seconds"
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {Restart-Computer -Force} -Credential $Cred
        Start-Sleep 180
    $Information.Text += "`n`nPhase 2"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {powershell.exe {(Get-WMIObject -Namespace root/cimv2/Security/MicrosoftTPM -class Win32_TPM).SetPhysicalPresenceRequest(5)}} -Credential $Cred
    $Information.Text += "`nClearing TPM"
    $Information.Text += "`Remote Computer will need to press F12 on Boot"
    $Information.Text += "`nComputer Restarting please wait 180 Seconds"
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {Restart-Computer -Force} -Credential $Cred
        Start-Sleep 180
        TPMACTIVATEORNOT
    }
TPMACTIVATEORNOT
}

function TPMACTIVATEORNOT {
$Computername = $txt_ComputerName.Text
If ((Invoke-Command -ComputerName $ComputerName -ScriptBlock {(Get-WmiObject win32_tpm -Namespace root\cimv2\Security\MicrosoftTPM).isenabled() | Select-Object -ExpandProperty IsEnabled} -Credential $Cred) -eq "True") {
$Information.Text += "`nTPM is Activated"
} Else {
$Information.Text += "`n`n Phase 1"
$Information.Text += "`nTPM is Deactivated"
$Information.Text += "`nSuspending Bitlocker with 1 reboot allowed..."
Invoke-Command -ComputerName $ComputerName -ScriptBlock {Suspend-BitLocker -MountPoint "C:" -RebootCount 1} -Credential $Cred
$Information.Text += "`nEnabling - Activating - Clearing - Enabling - Activating"
Invoke-Command -ComputerName $ComputerName -ScriptBlock {powershell.exe {(Get-WMIObject -Namespace root/cimv2/Security/MicrosoftTPM -class Win32_TPM).SetPhysicalPresenceRequest(22)}} -Credential $Cred
$Information.Text += "`nComputer Restarting please wait 180 Seconds"
Invoke-Command -ComputerName $ComputerName -ScriptBlock {Restart-Computer -Force} -Credential $Cred
Start-Sleep 180
CDRIVEENCRYPTED
}
CDRIVEENCRYPTED}

function CDRIVEENCRYPTED {
$Computername = $txt_ComputerName.Text
If ((Invoke-Command -Computername $Computername -ScriptBlock {(Get-WmiObject -namespace "Root\cimv2\security\MicrosoftVolumeEncryption" -ClassName "Win32_Encryptablevolume" -filter "DriveLetter = 'C:'").ProtectionStatus} -Credential $Cred) -eq "1") {
$Information.Text += "`nC Drive is encrypted"
} Else{
$Information.Text += "`nC Drive is not encrypted"
$Information.Text += "`nSetting up Encryption"
Invoke-Command -ComputerName $Computername -ScriptBlock {(Get-WmiObject -Namespace root\cimv2\security\microsoftvolumeencryption -Class Win32_encryptablevolume -Filter "DriveLetter = 'C:'").ProtectKeyWithNumericalPassword()} -Credential $Cred
$Information.Text += "`nStarting Encryption."
Invoke-Command -ComputerName $Computername -ScriptBlock {(Get-WmiObject -Namespace root\cimv2\security\microsoftvolumeencryption -Class Win32_encryptablevolume -Filter "DriveLetter = 'C:'").Encrypt()} -Credential $Cred
CDIVEISENCRYPTING
}
TPMREADYFORUSE}

function TPMREADYFORUSE {
$Computername = $txt_ComputerName.Text
If (Invoke-Command -ComputerName $ComputerName -ScriptBlock {(get-TPM).TpmReady} -Credential $Cred) {
$Information.Text += "`nTPM is Ready for use...."
TPMCompleted
} Else {
$Information.Text += "`nTPM is Not Ready for use...."
$Information.Text += "`n Getting TPM Ready for use...."
Invoke-Command -ComputerName $ComputerName -ScriptBlock {powershell.exe {(Get-WMIObject -Namespace root/cimv2/Security/MicrosoftTPM -class Win32_TPM).SetPhysicalPresenceRequest(22)}} -Credential $Cred
$Information.Text += "`nComputer Restarting please wait 180 Seconds"
Invoke-Command -ComputerName $ComputerName -ScriptBlock {Restart-Computer -Force} -Credential $Cred
TPMCompleted
}}

function CDIVEISENCRYPTING {
$Information.Text += "`nC Drive has started encrpytion process"
$Information.Text += "`nPlease wait a day and check again."
}

function TPMCompleted {
$Computername = $txt_ComputerName.Text
$Information.Text += "`nScript completed please wait 180 seconds to make sure that everything worked."
Invoke-Command -ComputerName $ComputerName -ScriptBlock {Restart-Computer -Force} -Credential $Cred
Start-Sleep 180
RecheckBitlocker
}

function RecheckBitlocker{
$Computername = $txt_ComputerName.Text
If ((Invoke-Command -ComputerName $ComputerName -ScriptBlock {(get-TPM).TpmPresent} -Credential $Cred) -eq "True") {
    $Information.Text += "`nTPM is ON"
    } Else {
    $Information.Text += "`nTPM is OFF"
}
If ((Invoke-Command -ComputerName $ComputerName -ScriptBlock {(Get-WmiObject win32_tpm -Namespace root\cimv2\Security\MicrosoftTPM).isenabled() | Select-Object -ExpandProperty IsEnabled} -Credential $Cred) -eq "True") {
    $Information.Text += "`nTPM is Activated"
    } Else {
    $information.Text += "`nTPM is Deactivated"
}
If ((Invoke-Command -Computername $Computername -ScriptBlock {(Get-WmiObject -namespace "Root\cimv2\security\MicrosoftVolumeEncryption" -ClassName "Win32_Encryptablevolume" -filter "DriveLetter = 'C:'").ProtectionStatus} -Credential $Cred) -eq "1") {
    $Information.Text += "`nC Drive is Encrypted"
    } Else{
    $Information.Text += "`nC Drive is Decrypted"
}
If (Invoke-Command -ComputerName $ComputerName -ScriptBlock {(get-TPM).TpmReady} -Credential $Cred) {
    $Information.Text += "`nTPM is Ready for use...."
    } Else {
    $Information.Text += "`nTPM is not ready for use...."
}
}

#------------------------------------------------Create GUI------------------------------------------------

Add-Type -AssemblyName System.Windows.Forms

$Font = New-Object System.Drawing.Font("Consolas",10,[System.Drawing.FontStyle]::Regular)

$MainForm = New-Object system.Windows.Forms.Form
$MainForm.Text = "Remote BitLocker Support"
$MainForm.Size = New-Object System.Drawing.Size(550,550)
$MainForm.AutoScroll = $True
$MainForm.MinimizeBox = $True
$MainForm.MaximizeBox = $True
$MainForm.WindowState = "Normal"
$MainForm.SizeGripStyle = "Hide"
$MainForm.ShowInTaskbar = $True
$MainForm.Opacity = 1
$MainForm.StartPosition = "CenterScreen"
$MainForm.ShowInTaskbar = $True
$MainForm.Font = $Font

$lbl_ComputerName = New-Object System.Windows.Forms.Label
$lbl_ComputerName.Location = New-Object System.Drawing.Point(20,9)
$lbl_ComputerName.AutoSize = $true
$lbl_ComputerName.Font = $Font
$lbl_ComputerName.Text = "Computer Name:"
$MainForm.Controls.Add($lbl_ComputerName)

$txt_ComputerName = New-Object System.Windows.Forms.TextBox
$txt_ComputerName.Location = New-Object System.Drawing.Point(150,5)
$txt_ComputerName.Size = New-Object System.Drawing.Size(200,20)
$txt_ComputerName.Font = $Font
$MainForm.Controls.Add($txt_ComputerName)

$btn_Scan = New-Object System.Windows.Forms.Button
$btn_Scan.Location = New-Object System.Drawing.Point(375,5)
$btn_Scan.Size = New-Object System.Drawing.Size(145,25)
$btn_Scan.Font = $Font
$btn_Scan.Text = "Scan / Fix"
$btn_Scan.Add_Click({TPMONOROFF})
$MainForm.Controls.Add($btn_Scan)

$Information = New-Object System.Windows.Forms.Label
$Information.Text = "Please type computer name and click Scan / Fix!"
$Information.Location = New-Object System.Drawing.Size(20,50)#75
$Information.AutoSize = $true
$Information.Font = $Font
$MainForm.Controls.Add($Information)

$MainForm.ShowDialog()

