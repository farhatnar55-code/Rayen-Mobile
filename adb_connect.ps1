Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*?)\s*=\s*(.*)\s*$') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

adb connect "$($env:ADB_DEVICE_IP):$($env:ADB_DEVICE_PORT)"
adb devices