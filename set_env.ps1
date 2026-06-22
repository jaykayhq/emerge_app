
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$androidHome = "C:\Users\HP\AppData\Local\Android\Sdk"
$flutterBin = "C:\src\flutter\bin"
$npmGlobal = "C:\Users\HP\AppData\Roaming\npm"

# Set ANDROID_HOME
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidHome, "User")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidHome, "User")

# Paths to add
$pathsToAdd = @(
    "$androidHome\platform-tools",
    "$androidHome\cmdline-tools\latest\bin",
    $flutterBin,
    $npmGlobal
)

foreach ($path in $pathsToAdd) {
    if ($userPath -notlike "*$path*") {
        $userPath = "$path;$userPath"
        Write-Host "Adding $path to User Path"
    } else {
        Write-Host "$path already in User Path"
    }
}

# Save updated Path
[System.Environment]::SetEnvironmentVariable("Path", $userPath, "User")

# Set FLUTTER_HOME
[System.Environment]::SetEnvironmentVariable("FLUTTER_HOME", "C:\src\flutter", "User")

Write-Host "Environment variables set successfully."
