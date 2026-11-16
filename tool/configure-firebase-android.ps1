$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$config = Join-Path $projectRoot 'config'
$source = Get-Content -LiteralPath (Join-Path $config 'google-services.json') -Raw |
    ConvertFrom-Json
$packageName = 'id.runwild.app'
$apps = @($source.client | Where-Object {
    $_.client_info.android_client_info.package_name -eq $packageName
})
if ($apps.Count -ne 1) {
    throw "Harus ada tepat satu konfigurasi Android untuk $packageName."
}
$app = $apps[0]
$apiKey = $app.api_key | Select-Object -First 1
$webClient = $app.oauth_client | Where-Object client_type -eq 3 |
    Select-Object -First 1
$values = [ordered]@{
    FIREBASE_API_KEY = $apiKey.current_key
    FIREBASE_APP_ID = $app.client_info.mobilesdk_app_id
    FIREBASE_MESSAGING_SENDER_ID = $source.project_info.project_number
    FIREBASE_PROJECT_ID = $source.project_info.project_id
}
foreach ($name in $values.Keys) {
    if ([string]::IsNullOrWhiteSpace($values[$name])) {
        throw "Konfigurasi Firebase belum memuat $name."
    }
}
if ($source.project_info.storage_bucket) {
    $values.FIREBASE_STORAGE_BUCKET = $source.project_info.storage_bucket
}
if ($webClient.client_id) {
    $values.GOOGLE_SERVER_CLIENT_ID = $webClient.client_id
} else {
    Write-Warning 'Klien OAuth web belum ditemukan. Unduh ulang konfigurasi setelah menambahkan SHA-1 dan mengaktifkan Google.'
}
$values | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $config 'dev.android.json')
Write-Output 'config/dev.android.json siap.'
