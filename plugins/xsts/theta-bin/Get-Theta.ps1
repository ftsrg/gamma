$thetaVersion = "v4.2.2"
$z3release = "z3-4.5.0"
$z3version = "z3-4.5.0-x64-win"

$currentPath = (Resolve-Path .\).Path
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Download {
	param (
		$From,
		$To
	)
	$clnt = new-object System.Net.WebClient
	$clnt.DownloadFile($From, $To)
}

Write-Output "Downloading Theta binary"
Download "https://github.com/ftsrg/theta/releases/download/$thetaVersion/theta-xsts-cli.jar" "$currentPath\theta-xsts-cli.jar"

Write-Output "Downloading Z3 solver binaries"
Download "https://github.com/ftsrg/theta/raw/$thetaVersion/lib/libz3.dll" "$currentPath\libz3.dll"
Download "https://github.com/ftsrg/theta/raw/$thetaVersion/lib/libz3java.dll" "$currentPath\libz3java.dll"

Write-Output "Downloading MSVC++ binaries"
$zipFilePath = "$currentPath\$z3version.zip"
Download "https://github.com/Z3Prover/z3/releases/download/$z3release/$z3version.zip" $zipFilePath

$shellApp = new-object -com shell.application 
$zipFile = $shellApp.namespace($zipFilePath)
$dest = $shellApp.namespace($currentPath) 
$dest.Copyhere($zipFile.items())

Copy-Item "$currentPath\$z3version\bin\msvcp110.dll" -Destination $currentPath
Copy-Item "$currentPath\$z3version\bin\msvcr110.dll" -Destination $currentPath
Copy-Item "$currentPath\$z3version\bin\vcomp110.dll" -Destination $currentPath

Remove-Item $zipFilePath
Remove-Item "$currentPath\$z3version" -Recurse

Write-Output "DONE"
