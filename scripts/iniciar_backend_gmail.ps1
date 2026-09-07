param([string]$PublicUrl = 'http://127.0.0.1:8000')

$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$pythonPath = Join-Path $projectPath '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $pythonPath)) { throw 'No se encuentra .venv. Ejecuta la configuración del proyecto primero.' }
$origin = [Uri]$PublicUrl
if (-not $origin.IsAbsoluteUri -or $origin.Scheme -notin @('http', 'https') -or $origin.AbsolutePath -ne '/' -or $origin.Query -or $origin.Fragment -or $origin.UserInfo) {
    throw 'PublicUrl debe ser solo el origen del backend, por ejemplo http://127.0.0.1:8000'
}
$sender = (Read-Host 'Gmail que enviará los correos de Serigraff').Trim()
if ($sender -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') { throw 'Ingresa un correo válido.' }
$securePassword = Read-Host 'Contraseña de aplicación de Google (no tu contraseña habitual)' -AsSecureString
$previousEnvironment = @{}
$names = @('EMAIL_BACKEND', 'EMAIL_HOST', 'EMAIL_PORT', 'EMAIL_USE_TLS', 'EMAIL_HOST_USER', 'EMAIL_HOST_PASSWORD', 'DEFAULT_FROM_EMAIL', 'PASSWORD_RESET_BASE_URL')
foreach ($name in $names) { $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    $env:EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
    $env:EMAIL_HOST = 'smtp.gmail.com'
    $env:EMAIL_PORT = '587'
    $env:EMAIL_USE_TLS = 'true'
    $env:EMAIL_HOST_USER = $sender
    $env:EMAIL_HOST_PASSWORD = ([System.Net.NetworkCredential]::new('', $securePassword)).Password.Replace(' ', '')
    $env:DEFAULT_FROM_EMAIL = "Serigraff <$sender>"
    $env:PASSWORD_RESET_BASE_URL = $PublicUrl.TrimEnd('/')
    Write-Host 'Gmail configurado para esta ejecución. No se guardarán las credenciales en archivos.'
    Write-Host 'El backend se iniciará en el puerto 8000. Detén cualquier servidor anterior en ese puerto.'
    & $pythonPath (Join-Path $projectPath 'manage.py') runserver 0.0.0.0:8000
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name], 'Process') }
    $securePassword.Dispose()
}
