#Created by: Christian Joy, Last Modified 20150901 https://github.com/Christiansjoy
#Please leave this by section in when distributing the script, this script however does not carry a license.

#This script needs the SCCM 2012 console, Ninite Pro and powershell locally. 
#It also requires the "source" folder which is a slightly modified version of PSAppDeploy 3.1.5, with the modifications being removing the EXE and putting in keywords to replace in the powershell script
#It basically creates a Ninite Pro offline installation of the app, packages PSAppDeploy around it, throws it in SCCM with everything bar the detection method and distributes it.

#########################
###VARIABLES TO MODIFY###
#########################
$ApplicationTitle = "Firefox"
$ApplicationDownload = 'firefox'
$ApplicationPublisher = "Mozilla"
$PSBlocklist = "firefox"


# Other Variables
$SiteServer = "server.domain.local"
$SiteCode = "A01"
$DeploymentInstallCommandLine = "Deploy-Application.ps1 install"
$DeploymentUninstallCommandLine = "Deploy-Application.ps1 uninstall"
$ApplicationLanguage = (Get-Culture).Name
$date = Get-Date -format "yyyy-MM-dd"
$ApplicationDescription = " "


#Create Ninite Installer
write-host "Creating Content folder and Ninite Installer"

$NiniteOutput = (cmd /c "\\server\sources\Utilities\PSAppdeploy\ninite.exe /select $ApplicationDownload /freeze $ApplicationDownload.exe /silent .")
$ApplicationSoftwareVersion = $NiniteOutput[1] -replace ".*: "

#Create variables based on package versions
$InstallEXE = $ApplicationTitle + $ApplicationSoftwareVersion + ".exe"
$CMAppDisplayName = $ApplicationPublisher + " " + $ApplicationTitle + " " + $ApplicationSoftwareVersion
$CMApplDeployName = $ApplicationPublisher + " " + $ApplicationTitle + " " + $ApplicationSoftwareVersion + " PSAppDeploy"
$ContentSourcePath = "\\server\sources\packages\" + $ApplicationPublisher + "\" + $ApplicationTitle + "\" + $ApplicationTitle + $ApplicationSoftwareVersion + "\"


#Copy PSAppDeploy base scripts and Ninite installer to the packages Folder
md $ContentSourcePath | out-null
copy \\server\sources\Utilities\PSAppdeploy\source\* $ContentSourcePath -recurse
move \\server\sources\Utilities\PSAppdeploy\$ApplicationDownload.exe $ContentSourcePath"Files\"$InstallEXE

#Modify PSAppDeploy Deploy-Application.ps1 as needed
write-host "Modifying installer for the current application"
$path = $ContentSourcePath + "Deploy-Application.ps1"
$text = get-content $path 
$newText = $text -replace "PSVENDOR",$ApplicationPublisher
$newText = $newText -replace "PSAPP",$ApplicationTitle
$newText = $newText -replace "PSVERSION",$ApplicationSoftwareVersion
$newText = $newText -replace "PSDATE",$date
$newText = $newText -replace "PSBLOCK",$PSBlocklist
$newText = $newText -replace "PSEXECUTE",$InstallEXE
$newText > $path

#Import the SCCM ConfigMgr Module and connect to the SCCM Site
write-host "Creating application and deployment in SCCM"
Import-Module -Name "$(split-path $Env:SMS_ADMIN_UI_PATH)\ConfigurationManager.psd1"
Set-Location -Path A01:

#Create a new Application within SCCM, put it in the required folder and send to Distribution Point
write-host $CMAppDisplayName
New-CMApplication -Name $CMAppDisplayName -Description $ApplicationDescription -IconLocationFile "\\server\sources\Utilities\PSAppdeploy\Icons\$ApplicationTitle.ico" -SoftwareVersion $ApplicationSoftwareVersion -AutoInstall $true   | out-null
Add-CMDeploymentType -ApplicationName $CMAppDisplayName -ScriptInstaller -DeploymentTypeName $CMApplDeployName -InstallationProgram $DeploymentInstallCommandLine -InstallationBehaviorType InstallForSystem -LogonRequirementType WhereOrNotUserLoggedOn -ContentLocation $ContentSourcePath -ManualSpecifyDeploymentType -DetectDeploymentTypeByCustomScript -ScriptType Powershell -ScriptContent "Exit 1" -UninstallProgram $DeploymentUninstallCommandLine -EstimatedInstallationTimeMinutes 5
$DeployedApp = Get-CMApplication -Name $CMAppDisplayName
Move-CMObject -FolderPath .\Application\PSAppDeploy\New -InputObject $DeployedApp
Start-CMContentDistribution -ApplicationName $CMAppDisplayName -DistributionPointName $SiteServer

write-host "Dont forget to fix the detection method first!"