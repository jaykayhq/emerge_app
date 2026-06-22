
$zipUrl = "https://dl.google.com/android/repository/commandlinetools-win-10406996_latest.zip"
$tempDir = "C:\temp_android_tools"
if (!(Test-Path $tempDir)) { New-Item -ItemType Directory -Force $tempDir }
$zipPath = Join-Path $tempDir "tools.zip"
Write-Host "Downloading Android Command Line Tools..."
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
Write-Host "Extracting..."
Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
$sdkRoot = "C:\Users\HP\AppData\Local\Android\Sdk"
$cmdlineDir = Join-Path $sdkRoot "cmdline-tools"
$latestDir = Join-Path $cmdlineDir "latest"
if (!(Test-Path $cmdlineDir)) { New-Item -ItemType Directory -Force $cmdlineDir }
if (Test-Path $latestDir) { Remove-Item -Recurse -Force $latestDir }
New-Item -ItemType Directory -Force $latestDir
Write-Host "Moving tools to latest..."
Move-Item -Path "$tempDir\cmdline-tools\*" -Destination $latestDir -Force
Remove-Item -Recurse -Force $tempDir
Write-Host "Android Command Line Tools set up successfully."
