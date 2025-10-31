param(
  [string]$ProjectPath = "src/Api/Api.csproj",
  [string]$Framework = "net9.0",
  [string]$OutDir = "docs/api"
)

$ErrorActionPreference = "Stop"

if (Test-Path $OutDir) { Remove-Item $OutDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutDir | Out-Null

dotnet restore $ProjectPath
dotnet build $ProjectPath -c Debug

$dll = Get-ChildItem -Path "src/Api/bin/Debug/$Framework" -Filter "Api.dll" -Recurse | Select-Object -First 1
if (-not $dll) { throw "Could not find Api.dll for $Framework" }

if (-not (Get-Command xmldocmarkdown -ErrorAction SilentlyContinue)) {
  dotnet tool install -g XmlDocMarkdown | Out-Null
  $env:PATH = "$env:PATH;$(Join-Path $env:USERPROFILE '.dotnet/tools')"
}

xmldocmarkdown $dll.FullName $OutDir --source "src/Api" --visibility public --clean --namespace-pages

Write-Host "API Markdown generated in $OutDir"