# Ejecuta la app de negocio contra el backend local en un celular por USB.
# Uso: .\scripts\run_local.ps1 [argumentos de flutter run]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

try {
    & "$PSScriptRoot\setup_usb.ps1"
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

if ($FlutterArgs) {
    & flutter run @FlutterArgs
} else {
    & flutter run
}
exit $LASTEXITCODE
