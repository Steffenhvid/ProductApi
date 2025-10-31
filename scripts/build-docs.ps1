param(
  [string]$SrcRoot = "src",
  [string]$Framework = "net9.0",
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

# Restore local tools (ensures xmldocmarkdown exists)
Push-Location $repoRoot
dotnet tool restore
Pop-Location

# Find all .csproj under /src
$projects = Get-ChildItem -Path $srcPath -Recurse -Filter "*.csproj"
if (-not $projects) { throw "No .csproj files found under $SrcRoot" }

foreach ($proj in $projects) {
    $projDir = Split-Path $proj.FullName -Parent
    $projName = [IO.Path]::GetFileNameWithoutExtension($proj.Name)
    $outPath = Join-Path $outRootPath $projName
    $dllPath = Join-Path $projDir "bin/Debug/$Framework/$projName.dll"

    Write-Host "📦 Building $projName"
    dotnet restore $proj.FullName
    dotnet build $proj.FullName -c Debug

    if (-not (Test-Path $dllPath)) {
        Write-Warning "⚠️ Skipping $projName — DLL not found ($dllPath)"
        continue
    }

    Write-Host "🧾 Generating Markdown for $projName"
    dotnet xmldocmarkdown $dllPath $outPath --source $projDir --visibility public --clean --namespace-pages
}

Write-Host "✅ All Markdown generated under $outRootPath"
