<#
    Project Stats Tool for Reditus
    - Count lines
    - Count characters
    - Count files by type
    - Show largest/smallest files
    - Export results to CSV
    - Show total size
    - Show most common file extensions
    Interactive menu, runs on open.
#>

$root = "$PSScriptRoot"
$excludeDirs = @('node_modules', 'build', 'backups', 'certs', 'logs', '.git', '.vscode', 'dist')
$excludeFiles = @('.env', '.env.example', 'package-lock.json', 'Thumbs.db', '.DS_Store')

function Is-Excluded {
    param($path)
    foreach ($dir in $excludeDirs) {
        if ($path -match "\\$dir(\\|$)") { return $true }
    }
    foreach ($file in $excludeFiles) {
        if ($path -match "\\$file$") { return $true }
    }
    return $false
}

function Get-AllFiles {
    Get-ChildItem -Path $root -Recurse -File | Where-Object { -not (Is-Excluded $_.FullName) }
}

function Count-Lines {
    $totalLines = 0
    $results = @()
    foreach ($file in (Get-AllFiles)) {
        try {
            $lines = (Get-Content $file.FullName -ErrorAction SilentlyContinue).Count
            $results += [PSCustomObject]@{ File = $file.FullName; Lines = $lines }
            $totalLines += $lines
        } catch {}
    }
    $results | Sort-Object Lines -Descending | Format-Table -AutoSize
    Write-Host "\nTotal lines in project: $totalLines" -ForegroundColor Green
}

function Count-Characters {
    $totalChars = 0
    $results = @()
    foreach ($file in (Get-AllFiles)) {
        try {
            $chars = (Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue).Length
            $results += [PSCustomObject]@{ File = $file.FullName; Characters = $chars }
            $totalChars += $chars
        } catch {}
    }
    $results | Sort-Object Characters -Descending | Format-Table -AutoSize
    Write-Host "\nTotal characters in project: $totalChars" -ForegroundColor Green
}

function Count-FilesByType {
    $files = Get-AllFiles
    $groups = $files | Group-Object { $_.Extension.ToLower() }
    $groups | Sort-Object Count -Descending | Format-Table Name,Count -AutoSize
    Write-Host "\nTotal files: $($files.Count)" -ForegroundColor Green
}

function Show-LargestFiles {
    $files = Get-AllFiles
    $results = @()
    foreach ($file in $files) {
        try {
            $lines = (Get-Content $file.FullName -ErrorAction SilentlyContinue).Count
            $chars = (Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue).Length
            $size = $file.Length
            $results += [PSCustomObject]@{ File = $file.FullName; Lines = $lines; Characters = $chars; SizeMB = [math]::Round($size/1MB,2) }
        } catch {}
    }
    Write-Host "\nTop 10 Largest Files (by lines):" -ForegroundColor Cyan
    $results | Sort-Object Lines -Descending | Select-Object -First 10 | Format-Table -AutoSize
    Write-Host "\nTop 10 Largest Files (by characters):" -ForegroundColor Cyan
    $results | Sort-Object Characters -Descending | Select-Object -First 10 | Format-Table -AutoSize
    Write-Host "\nTop 10 Largest Files (by size):" -ForegroundColor Cyan
    $results | Sort-Object SizeMB -Descending | Select-Object -First 10 | Format-Table -AutoSize
}

function Show-SmallestFiles {
    $files = Get-AllFiles
    $results = @()
    foreach ($file in $files) {
        try {
            $lines = (Get-Content $file.FullName -ErrorAction SilentlyContinue).Count
            $chars = (Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue).Length
            $size = $file.Length
            $results += [PSCustomObject]@{ File = $file.FullName; Lines = $lines; Characters = $chars; SizeKB = [math]::Round($size/1KB,2) }
        } catch {}
    }
    Write-Host "\nTop 10 Smallest Files (by lines):" -ForegroundColor Cyan
    $results | Sort-Object Lines | Select-Object -First 10 | Format-Table -AutoSize
    Write-Host "\nTop 10 Smallest Files (by characters):" -ForegroundColor Cyan
    $results | Sort-Object Characters | Select-Object -First 10 | Format-Table -AutoSize
    Write-Host "\nTop 10 Smallest Files (by size):" -ForegroundColor Cyan
    $results | Sort-Object SizeKB | Select-Object -First 10 | Format-Table -AutoSize
}

function Export-Results {
    $files = Get-AllFiles
    $results = @()
    foreach ($file in $files) {
        try {
            $lines = (Get-Content $file.FullName -ErrorAction SilentlyContinue).Count
            $chars = (Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue).Length
            $size = $file.Length
            $results += [PSCustomObject]@{ File = $file.FullName; Lines = $lines; Characters = $chars; SizeBytes = $size }
        } catch {}
    }
    $csvPath = Join-Path $root "project-stats.csv"
    $results | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "\nResults exported to $csvPath" -ForegroundColor Green
}

function Show-TotalSize {
    $files = Get-AllFiles
    $totalSize = ($files | Measure-Object Length -Sum).Sum
    Write-Host "\nTotal size of all files: $([math]::Round($totalSize/1MB,2)) MB ($totalSize bytes)" -ForegroundColor Green
}

function Show-CommonExtensions {
    $files = Get-AllFiles
    $groups = $files | Group-Object { $_.Extension.ToLower() }
    Write-Host "\nMost common file extensions:" -ForegroundColor Cyan
    $groups | Sort-Object Count -Descending | Select-Object -First 10 | Format-Table Name,Count -AutoSize
}

function Show-Menu {
    Write-Host "\n==== Reditus's Project Stats Tool ====" -ForegroundColor Yellow
    Write-Host "1. Count lines"
    Write-Host "2. Count characters"
    Write-Host "3. Count files by type"
    Write-Host "4. Show largest files"
    Write-Host "5. Show smallest files"
    Write-Host "6. Export results to CSV"
    Write-Host "7. Show total size"
    Write-Host "8. Show most common file extensions"
    Write-Host "9. Exit"
    $choice = Read-Host "Select an option (1-9)"
    switch ($choice) {
        '1' { Count-Lines }
        '2' { Count-Characters }
        '3' { Count-FilesByType }
        '4' { Show-LargestFiles }
        '5' { Show-SmallestFiles }
        '6' { Export-Results }
        '7' { Show-TotalSize }
        '8' { Show-CommonExtensions }
        '9' { Write-Host "Exiting..."; exit }
        default { Write-Host "Invalid option. Try again."; Show-Menu }
    }
    Show-Menu
}



function Ask-Root {
    while ($true) {
        Write-Host "\nEnter folder to scan:" -ForegroundColor Yellow
        $input = Read-Host "Folder path"
        if ([string]::IsNullOrWhiteSpace($input)) {
            Write-Host "You must enter a folder path." -ForegroundColor Red
            continue
        }
        if (-not (Test-Path $input)) {
            Write-Host "Invalid path. Please try again." -ForegroundColor Red
            continue
        }
        return $input
    }
}

$scanRoot = Ask-Root

function Get-AllFiles {
    Get-ChildItem -Path $scanRoot -Recurse -File | Where-Object { -not (Is-Excluded $_.FullName) }
}

# Auto-run menu when script is opened
Show-Menu
