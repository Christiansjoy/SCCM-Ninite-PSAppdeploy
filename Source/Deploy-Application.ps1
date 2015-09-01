﻿<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).  
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s). 
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down in to 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
	To access the help section,
.EXAMPLE
	Deploy-Application.ps1
.EXAMPLE
	Deploy-Application.ps1 -DeployMode "Silent"
.EXAMPLE
	Deploy-Application.ps1 -AllowRebootPassThru -AllowDefer
.EXAMPLE
	Deploy-Application.ps1 Uninstall 
.PARAMETER DeploymentType
	The type of deployment to perform. [Default is "Install"]
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent or NonInteractive mode.
	Interactive = Default mode
	Silent = No dialogs
	NonInteractive = Very silent, i.e. no blocking apps. Noninteractive mode is automatically set if an SCCM task sequence or session 0 is detected.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation.
	If 3010 is passed back to SCCM a reboot prompt will be triggered. 
.PARAMETER TerminalServerMode
	Changes to user install mode and back to user execute mode for installing/uninstalling applications on Remote Destkop Session Host/Citrix servers
.NOTES
.LINK 
	Http://psappdeploytoolkit.codeplex.com
"#>
Param (
	[ValidateSet("Install","Uninstall")] 
	[string] $DeploymentType = "Install",
	[ValidateSet("Interactive","Silent","NonInteractive")]
	[string] $DeployMode = "Interactive",
	[switch] $AllowRebootPassThru = $false,
	[switch] $TerminalServerMode = $false
)

#*===============================================
#* VARIABLE DECLARATION
Try {
#*===============================================

#*===============================================
# Variables: Application

$appVendor = "PSVENDOR"
$appName = "PSAPP"
$appVersion = "PSVERSION"
$appArch = ""
$appLang = "EN"
$appRevision = "01"
$appScriptVersion = "1.0.0"
$appScriptDate = "PSDATE"
$appScriptAuthor = "Christian Joy"

#*===============================================
# Variables: Script - Do not modify this section

$deployAppScriptFriendlyName = "Deploy Application"
$deployAppScriptVersion = [version]"3.1.5"
$deployAppScriptDate = "08/01/2014"
$deployAppScriptParameters = $psBoundParameters

# Variables: Environment
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
# Dot source the App Deploy Toolkit Functions
."$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
# Handle ServiceUI invocation
If ($serviceUIExitCode -ne $null) { Exit-Script $serviceUIExitCode }

#*===============================================
#* END VARIABLE DECLARATION
#*===============================================

#*===============================================
#* PRE-INSTALLATION
If ($deploymentType -ne "uninstall") { $installPhase = "Pre-Installation"
#*===============================================

	# Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install and persist the prompt
	Show-InstallationWelcome -CloseApps "PSBLOCK" -AllowDeferCloseApps -DeferTimes 3 -DeferDays 3 -PersistPrompt -BlockExecution

	# Show Progress Message (with the default message)
	#Show-InstallationProgress

#*===============================================
#* INSTALLATION 
$installPhase = "Installation"
#*===============================================

	# Perform installation tasks here
	Execute-Process	-Action Install -FilePath "PSEXECUTE" -Arguments "/silent /disableautoupdate"

#*===============================================
#* POST-INSTALLATION
$installPhase = "Post-Installation"
#*===============================================

	# Perform post-installation tasks here

	# Display a message at the end of the install
	#Show-InstallationPrompt -Message "You can customise text to appear at the end of an install, or remove it completely for unattended installations." -ButtonRightText "Ok" -Icon Information -NoWait

#*===============================================
#* PRE-UNINSTALLATION
} ElseIf ($deploymentType -eq "uninstall") { $installPhase = "Pre-Uninstallation"
#*===============================================

	# Show Welcome Message, close Internet Explorer if required with a 60 second countdown before automatically closing
	Show-InstallationWelcome -CloseApps "PSBLOCK" -AllowDeferCloseApps -DeferTimes 3 -PersistPrompt -BlockExecution

	# Show Progress Message (with the default message)
	#Show-InstallationProgress

#*===============================================
#* UNINSTALLATION
$installPhase = "Uninstallation"
#*===============================================

	# Perform uninstallation tasks here
	Execute-Process -Action Uninstall -FilePath "PSEXECUTE" -Arguments "/silent /uninstall"

#*===============================================
#* POST-UNINSTALLATION
$installPhase = "Post-Uninstallation"
#*===============================================

	# Perform post-uninstallation tasks here

#*===============================================
#* END SCRIPT BODY
} } Catch { $exceptionMessage = "$($_.Exception.Message) `($($_.ScriptStackTrace)`)"; If (!($appDeployToolkitName)) {Throw "Failed to dot-source AppDeployToolkitMain.ps1 - please check if the file is present in the \AppDeployToolkit folder"; Exit 1} 
Else { Write-Log "$exceptionMessage"; Show-DialogBox -Text $exceptionMessage -Icon "Stop"; Exit-Script -ExitCode 1 } } # Catch any errors in this script 
Exit-Script -ExitCode 0 # Otherwise call the Exit-Script function to perform final cleanup operations
#*===============================================