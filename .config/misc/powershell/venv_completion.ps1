Register-ArgumentCompleter -CommandName venv -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $venvs_base_dir = Join-Path $HOME ".local\venvs"
    $venvs = @()
    if (Test-Path $venvs_base_dir -PathType Container) {
        $venvs = (Get-ChildItem -Path $venvs_base_dir -Directory | Select-Object -ExpandProperty Name | Where-Object { $_ -ne "base" })
    }

    $options = @('--activate', '--deactivate', '--create',
        '--match', '--unmatch', '--venvs',
        '--list', '--edit', '--init',
        '--delete', '--clean', '--help',
        '-a', '-d', '-c',
        '-m', '-u', '-v',
        '-l', '-e', '-i', '-h'
    )

    $lastArgument = try {
        if ($commandAst.CommandElements.Count -gt 1) {
            $commandAst.CommandElements[-2].Text
        } else {
            '' # No previous argument
        }
    } catch {
        '' # Fallback
    }

    switch ($lastArgument) {
        # Match/unmatch completion: offer directories.
        {($_ -eq "--unmatch") -or ($_ -eq "-u")} {
            return Get-ChildItem -Path $PSScriptRoot -Directory -Force | Select-Object -ExpandProperty FullName
        }

        # Match completion: offer venv names first, then directories.
        {($_ -eq "--match") -or ($_ -eq "-m")} {
            if ($commandAst.CommandElements.Count -eq 3) {
                # First argument after '--match' should be a venv name.
                return $venvs | Where-Object { $_ -like "$wordToComplete*" }
            } elseif ($commandAst.CommandElements.Count -ge 4) {
                # Second argument after '--match' should be a directory.
                return Get-ChildItem -Path $PSScriptRoot -Directory -Force | Select-Object -ExpandProperty FullName
            }
        }

        # Activate/Delete completion: offer only venv names.
        {($_ -eq "--activate") -or ($_ -eq "-a") -or ($_ -eq "--delete")} {
            return $venvs | Where-Object { $_ -like "$wordToComplete*" }
        }

        # Default completion: offer command options or venv names.
        default {
            if ($wordToComplete.StartsWith('-')) {
                return $options | Where-Object { $_ -like "$wordToComplete*" }
            } else {
                return $venvs | Where-Object { $_ -like "$wordToComplete*" }
            }
        }
    }
}

