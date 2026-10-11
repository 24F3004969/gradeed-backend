<#
.SYNOPSIS
    Generates the feature-based package structure for the gradeed Spring Boot backend.

.DESCRIPTION
    Run this script from the Spring Boot project root, where pom.xml is located.
    It creates directories and .gitkeep files only. Existing files are never overwritten.

.EXAMPLE
    Set-ExecutionPolicy -Scope Process Bypass
    .\generate-gradeed-backend-structure.ps1

.EXAMPLE
    .\generate-gradeed-backend-structure.ps1 -BasePackage "org.gradeedclasses.backend"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$BasePackage = "org.gradeedclasses.backend",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectRoot = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "  Created: $Path" -ForegroundColor DarkGreen
    }
}

function Ensure-GitKeep {
    param([Parameter(Mandatory = $true)][string]$Directory)

    Ensure-Directory -Path $Directory
    $gitKeep = Join-Path $Directory ".gitkeep"
    if (-not (Test-Path -LiteralPath $gitKeep)) {
        New-Item -ItemType File -Path $gitKeep -Force | Out-Null
    }
}

$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$pomPath = Join-Path $ProjectRoot "pom.xml"
$gradlePath = Join-Path $ProjectRoot "build.gradle"
$gradleKtsPath = Join-Path $ProjectRoot "build.gradle.kts"

if (-not (Test-Path -LiteralPath $pomPath) -and
    -not (Test-Path -LiteralPath $gradlePath) -and
    -not (Test-Path -LiteralPath $gradleKtsPath)) {
    throw "No pom.xml, build.gradle, or build.gradle.kts was found in '$ProjectRoot'. Run this script from the Spring Boot project root or pass -ProjectRoot."
}

if ($BasePackage -notmatch '^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$') {
    throw "Invalid Java package name: '$BasePackage'."
}

$PackagePath = $BasePackage.Replace('.', [System.IO.Path]::DirectorySeparatorChar)
$MainJavaRoot = Join-Path $ProjectRoot "src/main/java"
$TestJavaRoot = Join-Path $ProjectRoot "src/test/java"
$MainResourcesRoot = Join-Path $ProjectRoot "src/main/resources"
$TestResourcesRoot = Join-Path $ProjectRoot "src/test/resources"
$MainPackageRoot = Join-Path $MainJavaRoot $PackagePath
$TestPackageRoot = Join-Path $TestJavaRoot $PackagePath

Write-Step "Project root: $ProjectRoot"
Write-Step "Base package: $BasePackage"

$CommonDirectories = @(
    "common/config",
    "common/exception",
    "common/response",
    "common/pagination",
    "common/validation",
    "common/audit",
    "common/util"
)

$SecurityDirectories = @(
    "security/controller",
    "security/dto/request",
    "security/dto/response",
    "security/entity",
    "security/repository",
    "security/service",
    "security/jwt",
    "security/config"
)

$StandardFeatureSubdirectories = @(
    "controller",
    "dto/request",
    "dto/response",
    "entity",
    "mapper",
    "repository",
    "service",
    "specification"
)

$Features = @(
    "student",
    "attendance",
    "fee",
    "academic",
    "questionbank",
    "exam",
    "result",
    "diagnostic",
    "timetable",
    "lessonplanner",
    "resource",
    "dashboard"
)

Write-Step "Creating main Java package directories"
Ensure-Directory -Path $MainPackageRoot

foreach ($relativePath in $CommonDirectories) {
    Ensure-GitKeep -Directory (Join-Path $MainPackageRoot $relativePath)
}

foreach ($relativePath in $SecurityDirectories) {
    Ensure-GitKeep -Directory (Join-Path $MainPackageRoot $relativePath)
}

foreach ($feature in $Features) {
    foreach ($subdirectory in $StandardFeatureSubdirectories) {
        Ensure-GitKeep -Directory (Join-Path $MainPackageRoot "$feature/$subdirectory")
    }
}

Write-Step "Creating resource directories"
$ResourceDirectories = @(
    "db/migration",
    "static",
    "templates"
)
foreach ($relativePath in $ResourceDirectories) {
    Ensure-GitKeep -Directory (Join-Path $MainResourcesRoot $relativePath)
}

Write-Step "Creating test package directories"
$TestFeatures = @(
    "student",
    "attendance",
    "fee",
    "academic",
    "questionbank",
    "exam",
    "result",
    "diagnostic",
    "timetable",
    "lessonplanner",
    "resource",
    "dashboard",
    "security",
    "integration"
)
foreach ($feature in $TestFeatures) {
    Ensure-GitKeep -Directory (Join-Path $TestPackageRoot $feature)
}
Ensure-GitKeep -Directory $TestResourcesRoot

Write-Step "Creating project-level operational directories"
$ProjectDirectories = @(
    "docs",
    "data/question-images",
    "data/student-photos",
    "data/exam-pdfs",
    "data/reports",
    "data/frontend-releases",
    "data/backups",
    "logs"
)
foreach ($relativePath in $ProjectDirectories) {
    Ensure-GitKeep -Directory (Join-Path $ProjectRoot $relativePath)
}

Write-Step "Creating documentation placeholders"
$DocumentationFiles = @{
    "architecture.md"    = "# Architecture`r`n`r`nArchitecture decisions for the gradeed backend.`r`n"
    "database-design.md" = "# Database Design`r`n`r`nPostgreSQL schema and migration notes.`r`n"
    "api-contract.md"    = "# API Contract`r`n`r`nREST API conventions and endpoint documentation.`r`n"
    "deployment.md"      = "# Deployment`r`n`r`nLocal server, PostgreSQL, backup, and tunnel deployment instructions.`r`n"
}
foreach ($entry in $DocumentationFiles.GetEnumerator()) {
    $filePath = Join-Path (Join-Path $ProjectRoot "docs") $entry.Key
    if (-not (Test-Path -LiteralPath $filePath)) {
        Set-Content -LiteralPath $filePath -Value $entry.Value -Encoding UTF8
    }
}

Write-Step "Creating safe environment template"
$envExamplePath = Join-Path $ProjectRoot ".env.example"
if (-not (Test-Path -LiteralPath $envExamplePath)) {
    @'
SPRING_PROFILES_ACTIVE=dev
SERVER_PORT=8080
DB_URL=jdbc:postgresql://localhost:5432/gradeed_2026
DB_USERNAME=gradeed_app
DB_PASSWORD=replace_me
JWT_SECRET=replace_with_a_long_random_secret
JWT_ACCESS_EXPIRATION=900000
JWT_REFRESH_EXPIRATION=604800000
ALLOWED_ORIGINS=http://localhost:5173
RESOURCE_STORAGE_PATH=./data
BACKUP_PATH=./data/backups
'@ | Set-Content -LiteralPath $envExamplePath -Encoding UTF8
}

Write-Step "Updating .gitignore with local runtime data exclusions"
$gitIgnorePath = Join-Path $ProjectRoot ".gitignore"
$RequiredGitIgnoreLines = @(
    "",
    "# Local gradeed backend runtime data",
    ".env",
    "logs/",
    "data/backups/",
    "data/question-images/",
    "data/student-photos/",
    "data/exam-pdfs/",
    "data/reports/",
    "data/frontend-releases/"
)

if (-not (Test-Path -LiteralPath $gitIgnorePath)) {
    New-Item -ItemType File -Path $gitIgnorePath -Force | Out-Null
}

$existingGitIgnore = Get-Content -LiteralPath $gitIgnorePath -Raw -ErrorAction SilentlyContinue
if ($null -eq $existingGitIgnore) {
    $existingGitIgnore = ""
}

if ($existingGitIgnore -notmatch '(?m)^# Local gradeed backend runtime data\s*$') {
    Add-Content -LiteralPath $gitIgnorePath -Value ($RequiredGitIgnoreLines -join [Environment]::NewLine) -Encoding UTF8
}

Write-Step "Creating Flyway migration placeholders"
$MigrationFiles = @{
    "V1__baseline_schema.sql" = @'
-- Baseline PostgreSQL schema.
-- Replace this placeholder with the validated schema exported after SQLite migration.
'@
    "V2__security_tables.sql" = @'
-- Add app_user, role, user_role, and refresh_token tables here.
'@
    "V3__audit_log.sql" = @'
-- Add the audit_log table here.
'@
    "V4__database_indexes.sql" = @'
-- Add application indexes after measuring query requirements.
'@
    "V5__normalize_timetables.sql" = @'
-- Future migration for normalized timetable and timetable_slot tables.
'@
}

$MigrationRoot = Join-Path $MainResourcesRoot "db/migration"
foreach ($entry in $MigrationFiles.GetEnumerator()) {
    $filePath = Join-Path $MigrationRoot $entry.Key
    if (-not (Test-Path -LiteralPath $filePath)) {
        Set-Content -LiteralPath $filePath -Value $entry.Value -Encoding UTF8
    }
}

Write-Success "Backend structure generated successfully."
Write-Host ""
Write-Host "Main package: $MainPackageRoot" -ForegroundColor Yellow
Write-Host "Test package: $TestPackageRoot" -ForegroundColor Yellow
Write-Host "Flyway path: $(Join-Path $MainResourcesRoot 'db/migration')" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: configure application.yml and create the security plus student modules." -ForegroundColor Magenta
