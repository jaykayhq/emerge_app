
# Set Home Variables
Write-Host "Setting Home Variables..."
[System.Environment]::SetEnvironmentVariable("FLUTTER_HOME", "C:\src\flutter", "User")
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Users\HP\AppData\Local\Android\Sdk", "User")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "C:\Users\HP\AppData\Local\Android\Sdk", "User")
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk-17", "User")

# Path Updates
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$pathsToAdd = @(
    "C:\src\flutter\bin",
    "C:\Users\HP\AppData\Local\Android\Sdk\platform-tools",
    "C:\Users\HP\AppData\Local\Android\Sdk\cmdline-tools\latest\bin",
    "C:\Users\HP\AppData\Roaming\npm",
    "C:\Program Files\Java\jdk-17\bin"
)

foreach ($path in $pathsToAdd) {
    if ($userPath -notlike "*$path*") {
        $userPath = "$path;$userPath"
        Write-Host "Adding $path to Path"
    }
    else {
        Write-Host "$path is already in Path"
    }
}

[System.Environment]::SetEnvironmentVariable("Path", $userPath, "User")
Write-Host "Environment variables updated successfully."
