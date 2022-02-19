$VerbosePreference = "Continue"
$DebugPreference = "Continue"

$appID = "DesktopAppInstaller"
$logPath = "$env:SystemRoot\Intune\Logging\Install"
$logFile = "$($(Get-Date -Format "yyyy-MM-dd hh.mm.ssK").Replace(":",".")) - $appID.log"
$errorVar = $null
$installResult = $null

$intuneSettings = Get-Content -Raw -Path "$env:SystemRoot\Intune\Logging\settings.json" -ErrorAction SilentlyContinue | ConvertFrom-Json 
$debug = [bool]$intuneSettings.Settings.InstallDebug

IF (!(Test-Path -Path $logPath)){
	New-Item -Path $logPath -ItemType Directory -Force
}

IF ($debug) {Start-Transcript -Path "$logPath\$logFile"}

try{
	$wingetURL = "https://aka.ms/getwinget"
	$bundlePath = "$PSScriptRoot\package.msixbundle"

	Write-Verbose -Verbose "Starting install for $appID"
	$WorkingDir = $(Get-Location).Path
	Push-Location -StackName WorkingDir
	Push-Location "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" -ErrorAction SilentlyContinue
	IF( $(Get-Location).Path -eq $WorkingDir){
		Write-Verbose "$appID Not Installed - Starting Download"
		Invoke-WebRequest $wingetURL -UseBasicParsing -OutFile $bundlePath
		Write-Verbose -Verbose "Installing msixbundle for $appID"
		DISM.EXE /Online /Add-ProvisionedAppxPackage /PackagePath:$bundlePath /SkipLicense
		exit 0
	}Else{
		$installedVersionFolder = Split-Path -Path (Get-Location) -Leaf
		$appFilePath = "$(Get-Location)\AppInstallerCLI.exe"
		Pop-Location -StackName WorkingDir

		IF (!(Test-Path -Path $appFilePath)){			
			Write-Verbose -Verbose "AppInstallerCLI.exe does not exist, uninstalling current version"
			Remove-AppPackage -Package $installedVersionFolder

			Write-Verbose -Verbose "$appID not installed, starting download"
			Invoke-WebRequest $wingetURL -UseBasicParsing -OutFile $bundlePath

			Write-Verbose -Verbose "Installing msixbundle for $appID"
			DISM.EXE /Online /Add-ProvisionedAppxPackage /PackagePath:$bundlePath /SkipLicense
			exit 0
		}else{
			Write-Verbose -Verbose "$appID already Installed"
			Exit 0
		}
	}
}
Catch {
	$errorVar = $_.Exception.Message
}
Finally {
	IF ($errorVar){
		Write-Verbose -Verbose "Script Errored"
		Write-Error  $errorVar
	}else{
		Write-Verbose -Verbose "Script Completed"
	}   

	IF ($debug) {Stop-Transcript}
	$VerbosePreference = "SilentlyContinue"
	$DebugPreference = "SilentlyContinue"

	IF ($errorVar){
		throw $errorVar 
	}
}
