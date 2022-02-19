$VerbosePreference = "Continue"
	$DebugPreference = "Continue"
	
	$appID = $args[0]
	$logPath = "$env:SystemRoot\Intune\Logging\Uninstall"
	$logFile = "$($(Get-Date -Format "yyyy-MM-dd hh.mm.ssK").Replace(":",".")) - $appID.log"
	$errorVar = $null
	$uninstallResult = $null
	
	$intuneSettings = Get-Content -Raw -Path "$env:SystemRoot\Intune\Logging\settings.json" | ConvertFrom-Json
	$debug = [bool]$intuneSettings.Settings.UninstallDebug
	
	IF (!(Test-Path -Path $logPath)){
		New-Item -Path $logPath -ItemType Directory -Force
	}
	
	IF ($debug) {Start-Transcript -Path "$logPath\$logFile"}
	
	try{
		Write-Verbose "Starting uninstall for $appID"
		Push-Location "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" -ErrorAction SilentlyContinue
		$appFilePath = "$(Get-Location)\AppInstallerCLI.exe"
		IF (Test-Path -Path $appFilePath){
			$argumentList =  [System.Collections.ArrayList]@("uninstall", "--silent", "$appID")  
			$cliCommand = '& "' + $($appFilePath) + '" ' + $argumentList
			$uninstallResult =  Invoke-Expression $cliCommand | Out-String
			Write-Verbose $uninstallResult
		}else{
			Write-Verbose "WinGet not Installed"
			Exit 1
		}
	}
	Catch {
		$errorVar = $_.Exception.Message
	}
	Finally {
		IF ($errorVar){
			Write-Verbose "Script Errored"
			Write-Error  $errorVar
		}else{
			Write-Verbose "Script Completed"
		}   
	
		IF ($debug) {Stop-Transcript}
		$VerbosePreference = "SilentlyContinue"
		$DebugPreference = "SilentlyContinue"
	
		IF ($errorVar){
			throw $errorVar 
		}
	}
