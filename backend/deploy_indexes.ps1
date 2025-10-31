# Firestore Index Deployment Script (PowerShell)
# Deploy indexes to Firebase Firestore

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Firestore Index Deployment Script" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Firebase CLI is installed
Write-Host "Checking Firebase CLI..." -ForegroundColor Yellow
try {
    $firebaseVersion = firebase --version 2>&1
    Write-Host "✓ Firebase CLI installed: $firebaseVersion" -ForegroundColor Green
}
catch {
    Write-Host "✗ Firebase CLI not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Firebase CLI:" -ForegroundColor Yellow
    Write-Host "  npm install -g firebase-tools" -ForegroundColor White
    exit 1
}

# Check if logged into Firebase
Write-Host "Checking Firebase login..." -ForegroundColor Yellow
try {
    $loginCheck = firebase login:list 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Firebase login verified" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Not logged into Firebase" -ForegroundColor Red
        Write-Host ""
        Write-Host "Login to Firebase:" -ForegroundColor Yellow
        Write-Host "  firebase login" -ForegroundColor White
        exit 1
    }
}
catch {
    Write-Host "✗ Error checking Firebase login" -ForegroundColor Red
    exit 1
}

# Check if firestore.indexes.json exists
Write-Host "Validating firestore.indexes.json..." -ForegroundColor Yellow
$indexesFile = Join-Path $PSScriptRoot "..\firestore.indexes.json"

if (-not (Test-Path $indexesFile)) {
    Write-Host "✗ File not found: $indexesFile" -ForegroundColor Red
    exit 1
}

try {
    $indexes = Get-Content $indexesFile -Raw | ConvertFrom-Json
    $numIndexes = $indexes.indexes.Count
    Write-Host "✓ Found $numIndexes index(es) in firestore.indexes.json" -ForegroundColor Green
    
    # Display indexes
    $i = 1
    foreach ($index in $indexes.indexes) {
        $fields = $index.fields.fieldPath -join ", "
        Write-Host "  $i. $($index.collectionGroup): $fields" -ForegroundColor White
        $i++
    }
}
catch {
    Write-Host "✗ Invalid JSON in firestore.indexes.json" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Confirm deployment
Write-Host ""
Write-Host "⚠️  Ready to deploy indexes to Firebase project 'mealy-41bf0'" -ForegroundColor Yellow
$response = Read-Host "Continue? (y/N)"

if ($response -ne "y" -and $response -ne "Y") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

# Deploy indexes
Write-Host ""
Write-Host "📤 Deploying indexes to Firestore..." -ForegroundColor Cyan
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""

# Change to project root directory
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot

try {
    firebase deploy --only firestore:indexes
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✓ Indexes deployed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📝 Note: Index building may take 1-5 minutes to complete." -ForegroundColor Yellow
        Write-Host "   Check status at: https://console.firebase.google.com/project/mealy-41bf0/firestore/indexes" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Wait 1-5 minutes for indexes to build" -ForegroundColor White
        Write-Host "2. Check status: firebase firestore:indexes" -ForegroundColor White
        Write-Host "3. Test your queries" -ForegroundColor White
    }
    else {
        Write-Host ""
        Write-Host "✗ Deployment failed!" -ForegroundColor Red
        Write-Host "Check the error messages above." -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host ""
    Write-Host "✗ Error deploying indexes!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "✓ All done!" -ForegroundColor Green
