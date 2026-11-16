param([Parameter(ValueFromRemainingArguments = $true)][string[]]$FlutterArgs)

$projectRoot = Split-Path $PSScriptRoot -Parent
$localFlutter = Join-Path $projectRoot '.tooling/flutter/bin/flutter.bat'
if (-not (Test-Path -LiteralPath $localFlutter)) {
    Write-Error 'SDK lokal belum tersedia. Instal Flutter 3.50.0 atau gunakan flutter dari PATH.'
    exit 1
}
$previousCache = $env:PUB_CACHE
$previousJava = $env:JAVA_HOME
$previousAndroid = $env:ANDROID_HOME
$previousGradle = $env:GRADLE_USER_HOME
try {
    $env:PUB_CACHE = Join-Path $projectRoot '.tooling/pub-cache'
    $javaDirectory = Join-Path $projectRoot '.tooling/java/jdk-17.0.21+9'
    $androidDirectory = Join-Path $projectRoot '.tooling/android-sdk'
    if (Test-Path -LiteralPath $javaDirectory) { $env:JAVA_HOME = $javaDirectory }
    if (Test-Path -LiteralPath $androidDirectory) { $env:ANDROID_HOME = $androidDirectory }
    $env:GRADLE_USER_HOME = Join-Path $projectRoot '.tooling/gradle'
    Push-Location $projectRoot
    try {
        & $localFlutter @FlutterArgs
        $resultCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }
} finally {
    $env:PUB_CACHE = $previousCache
    $env:JAVA_HOME = $previousJava
    $env:ANDROID_HOME = $previousAndroid
    $env:GRADLE_USER_HOME = $previousGradle
}
exit $resultCode
