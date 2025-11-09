param(
    [string]$Channel = "dev",
    [string]$Platform = "Windows",
    [int]$DataVersion = 0,
    [string]$Engine = $null,
    [string]$OutDir = $null,
    [string]$OutFile = $null,
    [Alias("h")][switch]$Help
)

# Lee propiedades de un fichero y devuelve un map de ellas
function Read-Props($path) {
    $map = @{}
    if (-not (Test-Path $path)) { return $map }
    foreach ($line in Get-Content $path) {
        $t = $line.Trim()
        if ($t -eq "" -or $t.StartsWith("#")) { continue }
        $kv = $t -split "=", 2
        if ($kv.Length -eq 2) { $map[$kv[0].Trim()] = $kv[1].Trim() }
    }
    return $map
}

# Garantiza que $path sea una carpeta de salida válida, y devuelve la ruta en $pfallback que finalmente se va a usar
function Confirm-dir($path, $fallback) {
    if ([string]::IsNullOrWhiteSpace($path)) { $path = $fallback }
    try { 
        New-Item -ItemType Directory -Force -Path $path | Out-Null
        return $path
    }
    catch { 
        Write-Warning "Ruta de salida inválida '$path'. Usando '$fallback'."
        New-Item -ItemType Directory -Force -Path $fallback | Out-Null
        return $fallback
    }
}

# Muestra la ayuda
if ($Help) {
    Write-Host ""
    Write-Host "make-buildinfo.ps1 - Genera un buildinfo.json con metadatos del build."
    Write-Host ""
    Write-Host "Uso:"
    Write-Host '  .\build\make-buildinfo.ps1 [-Channel <canal>] [-Platform <plataforma>]'
    Write-Host '                                [-DataVersion <n>] [-Engine <motor>]'
    Write-Host '                                [-OutDir <ruta>] [-OutFile <nombre>]'
    Write-Host ""
    Write-Host "Parámetros:"
    Write-Host "  -Channel       dev|beta|release (defecto: dev)"
    Write-Host "  -Platform      Windows|Linux|mac|android... (defecto: Windows)"
    Write-Host "  -DataVersion   Si no se pasa, se toma de version.txt (o 0 por defecto)"
    Write-Host "  -Engine        Si no se pasa, se toma de engine.txt (o 'unknown')"
    Write-Host "  -OutDir        Carpeta de salida (defecto: .)"
    Write-Host "  -OutFile       Nombre del fichero (defecto: buildinfo.json)"
    Write-Host "  -Help|-h       Muestra esta ayuda y termina"
    Write-Host ""
    Write-Host "Funcionamiento:"
    Write-Host "  - Lee version.txt (key=value) -> version, dataVersion con fallback 0.0.0 / 0"
    Write-Host "  - Lee engine.txt (key=value) -> engine o 'unknown'"
    Write-Host "  - Lee info Git (commit corto); si no hay, commit='nogit'"
    Write-Host "  - Genera buildId (yyyyMMdd-HHmmss-commit) y compiledAt (UTC)"
    Write-Host "  - Escribe el JSON en OutDir/OutFile"
    Write-Host ""
    exit 0
}
# ============================================================================

$ErrorActionPreference = "Stop"

# 1) version.txt 
$VERSION = "0.0.0"
if ($DataVersion -lt 0) { $DataVersion = 0 }
$verProps = Read-Props "version.txt"
if ($verProps.ContainsKey("version"))     { $VERSION = $verProps["version"] } else { Write-Warning "version.txt sin 'version' -> 0.0.0" }
if ($DataVersion -eq 0 -and $verProps.ContainsKey("dataVersion")) { $DataVersion = [int]$verProps["dataVersion"] } elseif ($DataVersion -eq 0) { Write-Warning "version.txt sin 'dataVersion' -> 0" }

# 2) engine
if (-not $Engine) {
    $engProps = Read-Props "engine.txt"
    if ($engProps.ContainsKey("engine")) {
        $Engine = $engProps["engine"]
    } else {
        $Engine = "unknown"
    }
}

# 3) Git (commit corto)
$COMMIT = "nogit"
try {
    $gitOut = (git rev-parse --short HEAD) 2>$null
    if ($gitOut) { $COMMIT = $gitOut.Trim() }
} catch { }

# 4) buildId + compiledAt
$timestamp   = Get-Date -Format "yyyyMMdd-HHmmss"
$BUILD_ID    = "$timestamp-$COMMIT"
$COMPILED_AT = (Get-Date).ToUniversalTime().ToString("s") + "Z"

# 5) machine
$BUILD_MACHINE = $env:COMPUTERNAME

# 6) Salida (dir/archivo)
if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $targetDir = Confirm-dir "build" "build"
} else {
    $targetDir = Confirm-dir $OutDir "build"
}

if ([string]::IsNullOrWhiteSpace($OutFile)) {
    $targetFile = "buildinfo.json"
} else {
    $targetFile = $OutFile.Trim()
}

$fullPath = Join-Path $targetDir $targetFile

# 7) JSON
$buildInfo = [ordered]@{
    version       = $VERSION
    channel       = $Channel
    platform      = $Platform
    commit        = $COMMIT
    buildId       = $BUILD_ID
    compiledAt    = $COMPILED_AT
    dataVersion   = [int]$DataVersion
    engineVersion = $Engine
    buildMachine  = $BUILD_MACHINE
}

$buildInfo | ConvertTo-Json -Depth 4 | Out-File -FilePath $fullPath -Encoding utf8

# 8) Resumen
Write-Host "Version:      $($buildInfo.version)"
Write-Host "Channel:      $($buildInfo.channel)"
Write-Host "Platform:     $($buildInfo.platform)"
Write-Host "Commit:       $($buildInfo.commit)"
Write-Host "BuildId:      $($buildInfo.buildId)"
Write-Host "CompiledAt:   $($buildInfo.compiledAt)"
Write-Host "DataVersion:  $($buildInfo.dataVersion)"
Write-Host "Engine:       $($buildInfo.engineVersion)"
Write-Host "BuildMachine: $BUILD_MACHINE"
Write-Host "Salida JSON:  $fullPath"

exit 0
