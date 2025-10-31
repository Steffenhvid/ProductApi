param(
  [string]$SrcRoot = "src",
  [string]$Framework = "net9.0",
  [string]$OutRoot = "docs/api"
)

$ErrorActionPreference = "Stop"

# Resolve repo root
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..") | ForEach-Object { $_.Path }

$srcPath = Join-Path $repoRoot $SrcRoot
$outRootPath = Join-Path $repoRoot $OutRoot

# Clean output
if (Test-Path $outRootPath) { Remove-Item $outRootPath -Recurse -Force }
New-Item -ItemType Directory -Path $outRootPath | Out-Null

# Ensure the tool exists
if (-not (Get-Command xmldocmarkdown -ErrorAction SilentlyContinue)) {
    dotnet tool install -g XmlDocMarkdown
    $env:PATH = "$env:PATH;$(Join-Path $env:USERPROFILE '.dotnet/tools')"
}

# Find all .csproj files under /src
$projects = Get-ChildItem -Path $srcPath -Recurse -Filter "*.csproj"
if (-not $projects) {
    Write-Error "No .csproj files found under $SrcRoot"
    exit 1
}

foreach ($proj in $projects) {
    Write-Host "📦 Building project: $($proj.FullName)"
    dotnet restore $proj.FullName
    dotnet build $proj.FullName -c Debug

    # Determine paths
    $projDir = Split-Path $proj.FullName -Parent
    $projName = [IO.Path]::GetFileNameWithoutExtension($proj.Name)
    $dllPath = Join-Path $projDir "bin/Debug/$Framework/$projName.dll"
    $outPath = Join-Path $outRootPath $projName

    if (-not (Test-Path $dllPath)) {
        Write-Warning "⚠️ DLL not found for $projName ($dllPath) — skipping"
        continue
    }

    Write-Host "🧾 Generating Markdown for $projName → $outPath"
    xmldocmarkdown $dllPath $outPath --source $projDir --visibility public --clean --namespace-pages
}

Write-Host "✅ All documentation generated under $outRootPath"
