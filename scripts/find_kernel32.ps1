$searchPaths = @(
    'C:\Program Files',
    'C:\Program Files (x86)',
    "${env:ProgramFiles}",
    "${env:ProgramFiles(x86)}",
    'C:\Program Files (x86)\Microsoft Visual Studio',
    'C:\Program Files\Microsoft Visual Studio',
    'C:\Program Files (x86)\Windows Kits\10\Lib'
)

$results = @()
foreach ($p in $searchPaths) {
    if ([string]::IsNullOrEmpty($p)) { continue }
    try {
        $found = Get-ChildItem -Path $p -Filter kernel32.lib -Recurse -ErrorAction SilentlyContinue
        if ($found) { $results += $found }
    } catch { }
}

$results = $results | Select-Object -Unique

# Prefer x64 import libs under Windows Kits (um\x64)
$preferred = $results | Where-Object { $_.FullName -match '\\(um\\x64|lib\\x64)\\' }
if ($preferred -and $preferred.Count -gt 0) {
    $preferred | Select-Object -First 1 | ForEach-Object { Write-Output $_.FullName }
    return
}

# Otherwise return up to 5 matches
$results = $results | Select-Object -First 5
if ($results.Count -eq 0) { Write-Output "" } else { $results | ForEach-Object { Write-Output $_.FullName } }
