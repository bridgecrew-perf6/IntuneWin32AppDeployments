$VerbosePreference = "Continue"
$DebugPreference = "Continue"

$appID = $args[0]

$logPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\CustomLogging\Uninstall"
$logSettingsPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\CustomLogging"

$logFile = "$($(Get-Date -Format "yyyy-MM-dd hh.mm.ssK").Replace(":",".")) - $appID.log"
$settingsFile = "settings.json"

$errorVar = $null

$debug = $false

IF (Test-Path -Path $logSettingsPath\$settingsFile) {
	$intuneSettings = Get-Content -Raw -Path $logSettingsPath\$settingsFile | ConvertFrom-Json
	$debug = [bool]$intuneSettings.Settings.UninstallDebug
}
ELSE {
	$BaseSettings = '{
		"Settings":
		{
			"DetectionDebug": 0,
			"InstallDebug": 0,
			"UninstallDebug": 0
		}
	}'
	New-Item -Path $logSettingsPath\$settingsFile -Force
	Set-Content -Path $logSettingsPath\$settingsFile -Value $BaseSettings
}

IF ($debug) {
	IF (!(Test-Path -Path $logPath)) {
		New-Item -Path $logPath -ItemType Directory -Force
	}
	Start-Transcript -Path "$logPath\$logFile"
}

try {
	Write-Verbose "Starting uninstall for $appID"
	$WorkingDir = $(Get-Location).Path
	Push-Location -StackName WorkingDir

	IF ([System.Environment]::Is64BitOperatingSystem) {
		$ProgramFiles = "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
	}
	ELSE {
		$ProgramFiles = "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x86__8wekyb3d8bbwe"		
	}

	IF ($([Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) -eq $True) {
		#Running as System		
		Push-Location $ProgramFiles -ErrorAction SilentlyContinue	
		IF ( $(Get-Location).Path -eq $WorkingDir) {
			Write-Verbose "$appID Not Installed"
			Exit 0
		}
		Else {	
			$installedVersionFolder = Split-Path -Path (Get-Location) -Leaf
			$AppInstallerPath = "$(Get-Location)\AppInstallerCLI.exe"
			$WinGetPath = "$(Get-Location)\winget.exe"
			Pop-Location -StackName WorkingDir

			$AppFilePath = (Resolve-Path $AppInstallerPath, $WinGetPath -ErrorAction SilentlyContinue).Path

			IF ($AppFilePath) {
				Remove-AppPackage -Package $installedVersionFolder
				Exit 0
			}
			else {
				Write-Verbose "$appID not Installed"
				Exit 1
			}
		}
	}
	ELSE {
		IF ($([Security.Principal.WindowsIdentity]::GetCurrent().Groups) -match "S-1-5-32-544") {
			#Running as Admin 
			Write-Error  "Script is running in Administrator Context not System or User Context - Unsupported configuration"
			Exit 1 
		}
		ELSE {
			#Running as Users
			Write-Error  "Script is running in User Context not System Context - Unsupported configuration for this app. "
			Exit 1
		}
	}	
}
Catch {
	$errorVar = $_.Exception.Message
}
Finally {
	IF ($errorVar) {
		Write-Verbose "Script Errored"
		Write-Error  $errorVar
	}
	else {
		Write-Verbose "Script Completed"
	}   

	IF ($debug) { Stop-Transcript }
	$VerbosePreference = "SilentlyContinue"
	$DebugPreference = "SilentlyContinue"

	IF ($errorVar) {
		throw $errorVar 
	}
}
