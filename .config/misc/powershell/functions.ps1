
function la {
    ls -Force
}

function touch($file) {
    "" | Out-File $file -Encoding ASCII
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function grep($regex, $dir) {
    if ($dir) {
        Get-ChildItem $dir | select-string $regex
    } else {
        $input | select-string $regex
    }
}

function head {
    cat @Args | Select -First 10
}

function tail {
    cat @Args | Select -Last 10
}

function du($path) {
    # Path is a file
    if ($path -ne $null -And (Test-Path -Path $path -PathType Leaf)) {
        $item = Get-Item -Path $path
        _display_size ($item.Name) ($item.Length)
        return
    }

    $total_size = 0
    foreach ($folder in (Get-ChildItem -Path $path -Directory)) {
        $size = (Get-ChildItem -Recurse $folder.FullName | Measure-Object -Property Length -Sum).sum
        _display_size ("d  " + $folder.Name) $size
        $total_size += $size
    }
    foreach ($file in (Get-ChildItem -Path $path -File)) {
        _display_size ("f  " + $file.Name) $file.Length
        $total_size += $file.Length
    }
    " ---------------------------------"
    _display_size "Total" $total_size
}

function td {
    vim ~\.cache\ToDo
}

. $PSScriptRoot\venv_fn.ps1


# Helper functions

function _display_size($name, $size) {
    if ($size / 1KB -lt 1) {
        "{0:N0}B" -f $size + "      `t" + $name
    } elseif ($size / 1MB -lt 1) {
        "{0:N2}KB" -f ($size / 1KB) + "      `t" + $name
    } elseif ($size / 1GB -lt 1) {
        "{0:N2}MB" -f ($size / 1MB) + "      `t" + $name
    } else {
        "{0:N2}GB" -f ($size / 1GB) + "      `t" + $name
    }
}
