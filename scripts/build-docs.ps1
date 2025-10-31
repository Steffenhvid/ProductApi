param(
  [string]$SrcRoot = "src",
  [string]$OutRoot = "docs/api"
)

$ErrorActionPreference = "Stop"

# Resolve paths
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..") | ForEach-Object { $_.Path }
$srcPath = Join-Path $repoRoot $SrcRoot
$outRootPath = Join-Path $repoRoot $OutRoot

# Clean output
if (Test-Path $outRootPath) { Remove-Item $outRootPath -Recurse -Force }
New-Item -ItemType Directory -Path $outRootPath | Out-Null

# Install DocFx if missing
if (-not (Get-Command docfx -ErrorAction SilentlyContinue)) {
    dotnet tool install -g docfx
    $env:PATH = "$env:PATH;$(Join-Path $env:USERPROFILE '.dotnet/tools')"
}

# Build all projects under /src
$projects = Get-ChildItem -Path $srcPath -Recurse -Filter "*.csproj"
if (-not $projects) { throw "No .csproj files found under $SrcRoot" }

foreach ($proj in $projects) {
    $projDir = Split-Path $proj.FullName -Parent
    $projName = [IO.Path]::GetFileNameWithoutExtension($proj.Name)
    $projOutput = Join-Path $outRootPath $projName
    New-Item -ItemType Directory -Force -Path $projOutput | Out-Null

    Write-Host "📦 Generating Markdown for $projName"

    Push-Location $projDir
    docfx metadata $proj.FullName -o "$projOutput/metadata"
    docfx build "$projOutput/metadata" -o "$projOutput" --serve false
    Pop-Location
}

Write-Host "✅ Markdown generated under $outRootPath"
