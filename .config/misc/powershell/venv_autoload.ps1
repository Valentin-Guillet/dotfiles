$venvList = Join-Path $HOME ".local\state\python" "venv_list"

# Ensure the state directory and venv list exist
if (-not (Test-Path $venvList -PathType Leaf)) {
    New-Item -ItemType File -Force -Path $venvList
}

$currPath = (Get-Location).Path
$longestMatch = ""
$venvName = $null

foreach ($line in Get-Content $venvList) {
    $vpath, $vname = $line -split "`t", 2

    if (-not $vname) {
        continue
    }

    # Check whether the current directory is inside this path
    if (-not $currPath.StartsWith($vpath, [StringComparison]::OrdinalIgnoreCase)) {
        continue
    }

    # Make sure this is actually a path component match
    if ($currPath.Length -gt $vpath.Length -and $currPath[$vpath.Length] -ne '\') {
        continue
    }

    if ($vpath.Length -lt $longestMatch.Length) {
        continue
    }

    $longestMatch = $vpath
    $venvName = $vname
}

if ($venvName) {
    # Venv found in venv_list
    & "$HOME\.local\venvs\$venvName\Scripts\Activate.ps1"

} elseif (Test-Path ".venv" -PathType Container) {
    # Local venv found
    & ".\.venv\Scripts\Activate.ps1"

    # Rename the prompt from the normal venv prompt to "(local)"
    $env:VIRTUAL_ENV_DISABLE_PROMPT = ""
    $env:VIRTUAL_ENV_PROMPT = "(local)"

} else {
    # No venv found: activate base
    $env:VIRTUAL_ENV_DISABLE_PROMPT = "1"
    $venvPath = Join-Path $HOME ".local\venvs\base"
    if (Test-Path $venvPath -PathType Container) {
        & "$venvPath\Scripts\Activate.ps1"
    } else {
        Write-Warning "No default virtual env created!"
    }
}
