# Prepara el celular conectado por USB para usar el backend local.
# Equivale a: adb reverse tcp:8000 tcp:8000
$ErrorActionPreference = 'Stop'

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    throw 'No se encontró adb en el PATH. Instala Android SDK Platform-Tools y agrégalo al PATH.'
}

$lines = & adb devices
if ($LASTEXITCODE -ne 0) {
    throw 'No se pudo consultar adb devices.'
}

$deviceLine = $lines | Where-Object { $_ -match '\s+device\s*$' } | Select-Object -First 1
if (-not $deviceLine) {
    throw 'No hay ningún celular Android conectado por USB con la depuración habilitada.'
}

$deviceId = ($deviceLine -split '\s+')[0]

& adb -s $deviceId reverse tcp:8000 tcp:8000 | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'No se pudo crear el reenvío adb reverse tcp:8000 tcp:8000.'
}

$reverseList = & adb -s $deviceId reverse --list
if (-not ($reverseList | Where-Object { $_ -match 'tcp:8000\s+tcp:8000' })) {
    throw 'El reenvío tcp:8000 no quedó activo. Vuelve a conectar el celular e inténtalo de nuevo.'
}

Write-Host "adb reverse activo en $deviceId : tcp:8000 -> tcp:8000" -ForegroundColor Green

try {
    $response = Invoke-WebRequest -Uri 'http://127.0.0.1:8000/openapi.json' -UseBasicParsing -TimeoutSec 5
    Write-Host "Backend local respondiendo (HTTP $($response.StatusCode))." -ForegroundColor Green
} catch {
    Write-Warning 'El backend local no responde en 127.0.0.1:8000. Inícialo con: uvicorn app.main:app --reload --port 8000'
}
