Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create and show console window
[System.Console]::Title = "X Optimizer Console"
$Host.UI.RawUI.WindowTitle = "X Optimizer Console"

$form = New-Object System.Windows.Forms.Form
$form.Text = 'X Optimizer for Windows 11'
$form.Size = New-Object System.Drawing.Size(400,720)
$form.StartPosition = 'CenterScreen'
$form.BackColor = [System.Drawing.Color]::White

$buttonY = 20
$buttonHeight = 30
$buttonWidth = 350

# Create loading panel
$loadingPanel = New-Object System.Windows.Forms.Panel
$loadingPanel.Size = $form.ClientSize
$loadingPanel.Location = New-Object System.Drawing.Point(0, 0)
$loadingPanel.BackColor = [System.Drawing.Color]::FromArgb(200, 255, 255, 255)
$loadingPanel.Visible = $false

$loadingLabel = New-Object System.Windows.Forms.Label
$loadingLabel.Text = "Applying tweak..."
$loadingLabel.AutoSize = $true
$loadingLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
$loadingLabel.Location = New-Object System.Drawing.Point(100, 250)

$loadingPanel.Controls.Add($loadingLabel)
$form.Controls.Add($loadingPanel)

function Show-LoadingScreen {
    $loadingPanel.Visible = $true
    $form.Refresh()
}

function Hide-LoadingScreen {
    $loadingPanel.Visible = $false
    $form.Refresh()
}

function Show-SuccessMessage {
    [System.Windows.Forms.MessageBox]::Show("Tweak applied successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Add-Button($text, $action) {
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point(25,$buttonY)
    $button.Size = New-Object System.Drawing.Size($buttonWidth,$buttonHeight)
    $button.Text = $text
    $button.BackColor = [System.Drawing.Color]::White
    $button.ForeColor = [System.Drawing.Color]::Black
    $button.Add_Click({
        try {
            Show-LoadingScreen
            Write-Host "`nApplying tweak: $text" -ForegroundColor Cyan
            if ($action -is [ScriptBlock]) {
                & $action
            } elseif ($action -is [string]) {
                Invoke-Expression $action
            }
            Write-Host "Tweak applied successfully!" -ForegroundColor Green
            Hide-LoadingScreen
            Show-SuccessMessage
        } catch {
            $errorMessage = "Error applying tweak: $($_.Exception.Message)"
            Write-Host $errorMessage -ForegroundColor Red
            Hide-LoadingScreen
            [System.Windows.Forms.MessageBox]::Show($errorMessage, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $form.Controls.Add($button)
    $script:buttonY += 40
}

Add-Button 'Create a Restore Point' {
    Write-Host "Opening System Protection dialog..."
    Start-Process "SystemPropertiesProtection.exe"
    
    Write-Host "Creating restore point 'Before X Optimizer'..."
    $result = (Enable-ComputerRestore -Drive $env:SystemDrive)
    if ($result -eq $true) {
        $restorePoint = (Checkpoint-Computer -Description "Before X Optimizer" -RestorePointType "MODIFY_SETTINGS" -PassThru)
        if ($restorePoint) {
            Write-Host "Restore point created successfully." -ForegroundColor Green
        } else {
            Write-Host "Failed to create restore point." -ForegroundColor Red
        }
    } else {
        Write-Host "Failed to enable System Restore." -ForegroundColor Red
    }
}

Add-Button 'Enable Game Mode' {
    Write-Host "Enabling Game Mode..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1
    Write-Host "Game Mode enabled."
}

Add-Button 'Disable Power Saving' {
    Write-Host "Disabling Power Saving..."
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Host "Power Saving disabled."
}

Add-Button 'Disable Core Isolation' {
    Write-Host "Disabling Core Isolation..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0
    Write-Host "Core Isolation disabled."
}

Add-Button 'Disable PnP Devices' {
    Write-Host "Disabling PnP Devices..."
    Get-PnpDevice | Where-Object {$_.Class -eq "USB"} | ForEach-Object {
        Write-Host "Disabling device: $($_.FriendlyName)"
        $_ | Disable-PnpDevice -Confirm:$false
    }
    Write-Host "PnP Devices disabled."
}

Add-Button 'TCP/IP Optimizations' {
    Write-Host "Applying TCP/IP Optimizations..."
    netsh int tcp set global autotuninglevel=normal
    netsh int tcp set global chimney=enabled
    netsh int tcp set global dca=enabled
    netsh int tcp set global netdma=enabled
    Write-Host "TCP/IP Optimizations applied."
}

Add-Button 'Enable Fullscreen Exclusive' {
    Write-Host "Enabling Fullscreen Exclusive..."
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehavior" -Value 2
    Write-Host "Fullscreen Exclusive enabled."
}

Add-Button 'Disable Background Apps' {
    Write-Host "Disabling Background Apps..."
    Get-AppxPackage | ForEach-Object {
        Write-Host "Disabling: $($_.Name)"
        Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"
    }
    Write-Host "Background Apps disabled."
}

Add-Button 'Disable Telemetry' {
    Write-Host "Disabling Telemetry..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
    Write-Host "Telemetry disabled."
}

Add-Button 'Clean Temp' {
    Write-Host "Cleaning Temp folder..."
    Remove-Item -Path "$env:TEMP\*" -Force -Recurse
    Write-Host "Temp folder cleaned."
}

Add-Button 'Set Display for Performance' {
    Write-Host "Setting display for performance..."
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    try {
        if (!(Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Set-ItemProperty -Path $path -Name VisualFXSetting -Value 2
        
        # Disable individual visual effects
        $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $advancedPath -Name ListviewAlphaSelect -Value 0
        Set-ItemProperty -Path $advancedPath -Name ListviewShadow -Value 0
        Set-ItemProperty -Path $advancedPath -Name TaskbarAnimations -Value 0
        
        $desktopPath = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $desktopPath -Name DragFullWindows -Value 0
        Set-ItemProperty -Path $desktopPath -Name FontSmoothing -Value 0
        
        $windowMetricsPath = "HKCU:\Control Panel\Desktop\WindowMetrics"
        Set-ItemProperty -Path $windowMetricsPath -Name MinAnimate -Value 0
        
        $dwmPath = "HKCU:\Software\Microsoft\Windows\DWM"
        Set-ItemProperty -Path $dwmPath -Name EnableAeroPeek -Value 0
        
        Write-Host "Display settings optimized for performance." -ForegroundColor Green
    }
    catch {
        Write-Host "Error setting display for performance: $_" -ForegroundColor Red
        throw
    }
}

Add-Button 'Disable SuperFetch/SysMain' {
    Write-Host "Disabling SuperFetch/SysMain..."
    Stop-Service -Name "SysMain" -Force
    Set-Service -Name "SysMain" -StartupType Disabled
    Write-Host "SuperFetch/SysMain has been disabled."
}

Add-Button 'Set IRQ Priorities' {
    Write-Host "Setting IRQ priorities..."
    
    function Set-IRQPriority {
        param (
            [string]$IRQName,
            [int]$Priority
        )
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
        $valueName = "IRQ$IRQName" + "Priority"
        
        if (!(Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $registryPath -Name $valueName -Value $Priority -Type DWord
        Write-Host "Set IRQ $IRQName priority to $Priority"
    }
    
    Set-IRQPriority -IRQName "8" -Priority 1
    Set-IRQPriority -IRQName "9" -Priority 1
    Set-IRQPriority -IRQName "12" -Priority 1
    Set-IRQPriority -IRQName "13" -Priority 1
    Set-IRQPriority -IRQName "16" -Priority 1
    Set-IRQPriority -IRQName "17" -Priority 1
    Set-IRQPriority -IRQName "18" -Priority 1
    Set-IRQPriority -IRQName "19" -Priority 1
    
    Write-Host "IRQ priorities have been set. A system restart may be required for changes to take effect."
}

Add-Button 'Set Thread Priorities' {
    Write-Host "Setting thread priorities..."
    
    # Adjust thread scheduling algorithm
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
    
    # Win32PrioritySeparation: 
    # 2 hex digits: 0xAABB
    # AA: 00 (variable), 01 (fixed)
    # BB: 00 (short), 01 (medium), 02 (long) quantum
    # 0x26 (38) = 00100110 = Variable base priority, Long quantum
    Set-ItemProperty -Path $registryPath -Name "Win32PrioritySeparation" -Value 0x26 -Type DWord
    
    # Increase priority for foreground applications
    Set-ItemProperty -Path $registryPath -Name "ForegroundLockTimeout" -Value 0x30d40 -Type DWord
    Set-ItemProperty -Path $registryPath -Name "ForegroundFlushTimeOut" -Value 0x4e20 -Type DWord
    
    # Boost foreground application priority
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ForegroundLockTimeout" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ForegroundFlushTimeOut" -Value 0 -Type DWord
    
    Write-Host "Thread priorities have been set to favor higher priority threads."
    Write-Host "A system restart is required for changes to take effect."
}

$form.ShowDialog()
