
Set-PSReadLineOption -EditMode Emacs

$LOCAL_PROFILE = "$(Split-Path -Parent $PROFILE)\Microsoft.PowerShell_local_profile.ps1"

# Source local profile
if (Test-Path -Path $LOCAL_PROFILE -PathType Leaf) {
    . $LOCAL_PROFILE
}


# Set Prompt to configure powershell to tell Terminal about its cwd
# (https://github.com/MicrosoftDocs/terminal/blob/main/TerminalDocs/tutorials/new-tab-same-directory.md)
function prompt {
    $loc = $executionContext.SessionState.Path.CurrentLocation;

    $out = ""
    if ($loc.Provider.Name -eq "FileSystem") {
        $out += "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\"
    }
    $out += "PS $loc$('>' * ($nestedPromptLevel + 1)) ";
    return $out
}



# Aliases

Set-Alias -Name unzip -Value Expand-Archive


# Functions

function la {
    ls -Force
}

function configg {
    vim $PROFILE
    . $PROFILE
}

function configa {
    vim $LOCAL_PROFILE
    . $PROFILE
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

# Venv management

function venv {
    $venv_action = "nothing"
    $venv_file = Join-Path $HOME ".local\state\python\venv_list"
    $venvs_base_dir = Join-Path $HOME ".local\venvs"

    $help_msg = @"
Tool to manage python virtual environments. Usage:
    - venv [VENV_NAME]         # Toggle activation of a VENV_NAME or current path's matched venv
    - venv [--activate|-a] [VENV_NAME] # Explicitly activate a VENV_NAME or current path's matched venv
    - venv [--deactivate|-d]   # Deactivate the current virtual environment
    - venv [--create|-c] VENV_NAME # Create a new virtual environment
    - venv [--match|-m] VENV_NAME [PATH] # Match a VENV_NAME to a specific PATH (defaults to current dir)
    - venv [--unmatch|-u] [PATH] # Unmatch a PATH from its associated venv (defaults to current dir)
    - venv [--venvs|-v]        # List all existing virtual environments
    - venv [--list|-l]         # List all path-to-venv mappings
    - venv [--edit|-e]         # Edit venv matching file
    - venv [--init|-i]         # Install common development tools into the current venv
    - venv --delete VENV_NAME  # Delete a specified virtual environment
    - venv --clean             # Clean up path-to-venv mappings for non-existent venvs or paths
"@

    # Display help message if '--help' or '-h' is provided.
    if ($args[0] -eq "--help" -or $args[0] -eq "-h") {
        Write-Host $help_msg
        return
    }

    # Handle the '--create' or '-c' command: Create a new virtual environment.
    elseif ($args[0] -eq "--create" -or $args[0] -eq "-c") {
        $venv_name = $args[1]
        if ([string]::IsNullOrEmpty($venv_name)) {
            Write-Host "Usage: venv --create VENV_NAME"
            return
        }

        $venv_path = Join-Path $venvs_base_dir $venv_name
        if (Test-Path -Path $venv_path -PathType Container) {
            Write-Host "Venv '$venv_name' already exists"
            return
        }

        if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
            Write-Host "uv is not installed. Please refer to the official uv installation guide for Windows (https://astral.sh/uv/install)."
            return
        }

        try {
            uv venv "$venv_path" # Executes 'uv venv <path>'
            Write-Host "New venv '$venv_name' created at '$venv_path'"
        } catch {
            Write-Host "Error creating venv: $($_.Exception.Message)"
            return
        }

        $venv_action = "activate"
        $args = $args | Select-Object -Skip 1
    }

    # Handle the '--match' or '-m' command: Associate a path with a virtual environment.
    elseif ($args[0] -eq "--match" -or $args[0] -eq "-m") {
        $venv_name = $args[1]
        # If no VENV_NAME is provided, try to use the name of the currently active venv (if not 'base').
        if ([string]::IsNullOrEmpty($venv_name)) {
            $currentVenvName = if ($env:VIRTUAL_ENV) { (Split-Path -Leaf $env:VIRTUAL_ENV) } else { "" }
            if ($currentVenvName -eq "base") {
                Write-Host "Usage: venv --match VENV_NAME [PATH]"
                return
            }
            $venv_name = $currentVenvName
        }

        # Determine the target path. Defaults to the current directory if not provided.
        $rawPath = if ($args.Length -ge 3 -and -not [string]::IsNullOrEmpty($args[2])) { $args[2] } else { (Get-Location).Path }
        try {
            $path = (Get-Item -Path $rawPath).FullName
        } catch {
            Write-Host "Invalid path: '$rawPath'"
            return
        }

        # Check that the specified virtual environment actually exists.
        if (-not (Test-Path -Path (Join-Path $venvs_base_dir $venv_name) -PathType Container)) {
            Write-Host "No venv named '$venv_name' exists in '$venvs_base_dir'."
            return
        }

        # Ensure the directory for the venv_file exists.
        $parentDir = Split-Path $venv_file -Parent
        if (-not (Test-Path $parentDir -PathType Container)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        # Ensure the venv_file itself exists.
        if (-not (Test-Path $venv_file -PathType Leaf)) {
            New-Item -ItemType File -Path $venv_file -Force | Out-Null
        }

        # Check if the path is already matched with this specific venv.
        $escapedPath = [regex]::Escape($path)
        $escapedVenvName = [regex]::Escape($venv_name)
        if ((Get-Content $venv_file | Select-String -Pattern "^$escapedPath`t$escapedVenvName`$" -Quiet)) {
            Write-Host "Path '$path' is already matched with venv '$venv_name'."
            return
        }

        # Update the match in the venv_file: remove any existing entries for this path, then add the new one.
        $fileContent = Get-Content $venv_file | Where-Object { $_ -notmatch "^$escapedPath`t" }
        $fileContent | Set-Content $venv_file
        "$path`t$venv_name" | Add-Content $venv_file
        Write-Host "Matched path '$path' with venv '$venv_name'."

        # If the target path is the current directory, set action to 'activate'.
        $currentLocationPath = (Get-Location).Path
        if ((Get-Item $path).FullName -eq (Get-Item $currentLocationPath).FullName) {
            $venv_action = "activate"
            $args = $args | Select-Object -Skip 1 # Simulate shift
        }
    }

    # Handle the '--unmatch' or '-u' command: Remove a path-to-venv association.
    elseif ($args[0] -eq "--unmatch" -or $args[0] -eq "-u") {
        $rawPath = if ($args.Length -ge 2 -and -not [string]::IsNullOrEmpty($args[1])) { $args[1] } else { (Get-Location).Path }
        try {
            $path = (Get-Item -Path $rawPath).FullName
        } catch {
            Write-Host "Invalid path: '$rawPath'"
            return
        }

        # If the venv_file doesn't exist, there are no matches to unmatch.
        if (-not (Test-Path $venv_file -PathType Leaf)) {
            Write-Host "No venv matched for path '$path'."
            return
        }

        $escapedPath = [regex]::Escape($path)
        # Find the line in the file that matches the path.
        $line = (Get-Content $venv_file | Select-String -Pattern "^$escapedPath`t" -ErrorAction SilentlyContinue).Line
        if ([string]::IsNullOrEmpty($line)) {
            Write-Host "No venv matched for path '$path'."
        } else {
            # Extract the venv name from the matched line.
            $venv_name = $line.Split("`t")[1]
            Write-Host "Path '$path' unmatched with venv '$venv_name'."
            # Remove the line matching the path from the file.
            Get-Content $venv_file | Where-Object { $_ -notmatch "^$escapedPath`t" } | Set-Content $venv_file
        }
    }

    # Handle the '--list' or '-l' command: List all created virtual environments.
    elseif ($args[0] -eq "--list" -or $args[0] -eq "-l") {
        if (Test-Path $venvs_base_dir -PathType Container) {
            $venvs = Get-ChildItem -Path $venvs_base_dir -Directory | Select-Object -ExpandProperty Name
            $currentActivatedVenvName = if ($env:VIRTUAL_ENV) { (Split-Path -Leaf $env:VIRTUAL_ENV) } else { "base" }

            foreach ($name in $venvs) {
                if ($name -eq $currentActivatedVenvName) {
                    Write-Host "[$name]" -ForegroundColor Yellow -NoNewline
                } else {
                    Write-Host "$name" -NoNewline
                }
                if ($name -ne $venvs[-1]) {
                    Write-Host " " -NoNewline
                }
            }
            Write-Host
        } else {
            Write-Host "No virtual environments found in '$venvs_base_dir'."
        }
    }

    # Handle the '--venvs' or '-v' command: Print all path-to-venv mappings.
    elseif ($args[0] -eq "--venvs" -or $args[0] -eq "-v") {
        if (-not (Test-Path $venv_file -PathType Leaf)) {
            Write-Host "No venv matched."
            return
        }
        $content = Get-Content $venv_file | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        if (-not $content) {
            Write-Host "No venv matched."
        } else {
            $content
        }
    }

    # Handle the '--edit' or '-e' command: Edit path-to-venv mapping file.
    elseif ($args[0] -eq "--edit" -or $args[0] -eq "-e") {
        vim $venv_file
    }

    # Handle the '--init' or '-i' command: Install common development tools.
    elseif ($args[0] -eq "--init" -or $args[0] -eq "-i") {
        if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
            Write-Host "uv is not installed. Please refer to the official uv installation guide for Windows."
            return
        }
        try {
            uv pip install pdbpp pdir2 ptpython pudb
            Write-Host "Common development tools installed."
        } catch {
            Write-Host "Error installing packages: $($_.Exception.Message)"
            return
        }
    }

    # Handle the '--delete' command: Delete a specific virtual environment.
    elseif ($args[0] -eq "--delete") {
        if ($args.Length -lt 2 -or [string]::IsNullOrEmpty($args[1])) {
            Write-Host "Usage: venv --delete VENV_NAME"
            return
        }

        $venv_name = $args[1]
        # Prevent deletion of the special 'base' venv.
        if ($venv_name -eq "base") {
            Write-Host "Cannot delete the 'base' virtual environment."
            return
        }

        $targetVenvPath = Join-Path $venvs_base_dir $venv_name
        if (-not (Test-Path -Path $targetVenvPath -PathType Container)) {
            Write-Host "No venv named '$venv_name' exists in '$venvs_base_dir'."
            return
        }

        # Ask for user confirmation before deleting.
        $confirm = Read-Host "Delete venv '$venv_name'? y/[N] "
        if ($confirm -match '^[Yy]') {
            try {
                Remove-Item -Path $targetVenvPath -Recurse -Force
                Write-Host "Venv '$venv_name' deleted."

                if ($env:VIRTUAL_ENV -and (Split-Path -Leaf $env:VIRTUAL_ENV) -eq $venv_name) {
                    $venv_action = "deactivate"
                }
            } catch {
                Write-Host "Error deleting venv: $($_.Exception.Message)"
                return
            }
        } else {
            Write-Host "Deletion aborted."
        }
    }

    # Handle the '--clean' command: Remove mappings for non-existent venvs or paths.
    elseif ($args[0] -eq "--clean") {
        # Check if the venv_file exists and has content.
        if (-not (Test-Path $venv_file -PathType Leaf) -or -not (Get-Content $venv_file | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
            Write-Host "No venv matched, nothing to clean."
            return
        }

        $filtered_content = @()
        $has_clean = $false

        Get-Content $venv_file | ForEach-Object {
            $line = $_
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $parts = $line.Split("`t")
                $path_from_file = $parts[0]
                $name_from_file = $parts[1]

                $venv_exists = Test-Path -Path (Join-Path "$venvs_base_dir" "$name_from_file") -PathType Container
                $path_exists = Test-Path -Path $path_from_file -PathType Container

                if (-not $venv_exists) {
                    Write-Host "Removing match: Path '$path_from_file' associated with nonexistent venv '$name_from_file'."
                    $has_clean = $true
                } elseif (-not $path_exists) {
                    Write-Host "Removing match: Directory '$path_from_file' does not exist anymore (matched to '$name_from_file')."
                    $has_clean = $true
                } else {
                    $filtered_content += $line
                }
            }
        }

        Set-Content $venv_file -Value $filtered_content -Force

        if (-not $has_clean) {
            Write-Host "No venv mappings needed cleaning!"
        }
    }

    # Handle the '--deactivate' or '-d' command: Deactivate the current virtual environment.
    elseif ($args[0] -eq "--deactivate" -or $args[0] -eq "-d") {
        $venv_action = "deactivate"
        $args = $args | Select-Object -Skip 1
    }

    # Handle the '--activate' or '-a' command: Explicitly activate a virtual environment.
    elseif ($args[0] -eq "--activate" -or $args[0] -eq "-a") {
        if ($args.Length -ge 2 -and $args[1] -eq "base") {
            # If 'base' is already activated, do nothing.
            if ($env:VIRTUAL_ENV -and (Split-Path -Leaf $env:VIRTUAL_ENV) -eq "base") {
                Write-Host "Base venv is already active."
                return
            }
            $venv_action = "deactivate" # Activating 'base' is effectively deactivating the current.
        } else {
            $venv_action = "activate"
        }
        $args = $args | Select-Object -Skip 1
    }

    # Handle invalid options (starting with '-').
    elseif ($args[0] -like "-*") {
        Write-Host "venv: Invalid option: '$($args[0])'"
        Write-Host $help_msg
        return
    }

    # Special case: 'venv base' (activates base, which means deactivating current).
    elseif ($args[0] -eq "base") {
        if ($env:VIRTUAL_ENV -and (Split-Path -Leaf $env:VIRTUAL_ENV) -eq "base") {
            Write-Host "Base venv is already active."
            return
        }
        $venv_action = "deactivate"
    }

    # Special case: 'venv' with no arguments when a non-base venv is active (deactivates).
    elseif ($args.Length -eq 0 -and $env:VIRTUAL_ENV -and (Split-Path -Leaf $env:VIRTUAL_ENV) -ne "base") {
        $venv_action = "deactivate"
    }

    # Default behavior: 'toggle' a venv (activate if not active, deactivate if active).
    else {
        $venv_action = "toggle"
    }

    # --- Activation and Deactivation Logic ---

    # Logic for activating or toggling a virtual environment.
    if ($venv_action -eq "activate" -or $venv_action -eq "toggle") {
        $venv_name = $args

        # If no venv name was explicitly provided, try to find a matched venv for the current path.
        if ([string]::IsNullOrEmpty($venv_name)) {
            $curr_path = (Get-Location).Path
            $longest_match = ""
            $matched_venv_name = ""

            if (Test-Path $venv_file -PathType Leaf) {
                Get-Content $venv_file | ForEach-Object {
                    $line = $_
                    if (-not [string]::IsNullOrWhiteSpace($line)) {
                        $parts = $line.Split("`t")
                        $vpath_from_file = $parts[0]
                        $vname_from_file = $parts[1]

                        try {
                            $canonical_vpath = (Get-Item -Path $vpath_from_file).FullName
                        } catch {
                            # Skip if the path in the file is invalid.
                            return # Equivalent to 'continue' in bash loop.
                        }

                        # Check if the current path starts with the matched path from the file.
                        # OrdinalIgnoreCase ensures case-insensitive comparison, suitable for Windows paths.
                        if ($curr_path.StartsWith($canonical_vpath, [System.StringComparison]::OrdinalIgnoreCase)) {
                            # If this matched path is longer than previous longest match, update.
                            if ($canonical_vpath.Length -ge $longest_match.Length) {
                                $longest_match = $canonical_vpath
                                $matched_venv_name = $vname_from_file
                            }
                        }
                    }
                }
            }
            $venv_name = $matched_venv_name # Set the determined venv name.
        }

        # If after all checks, no venv name could be determined.
        if ([string]::IsNullOrEmpty($venv_name)) {
            Write-Host "No virtual environment matched to the current path found."
            return
        }

        # Check if the determined venv actually exists on disk.
        $targetVenvPath = Join-Path "$venvs_base_dir" "$venv_name"
        if (-not (Test-Path -Path $targetVenvPath -PathType Container)) {
            Write-Host "Virtual environment '$venv_name' does not exist at '$venvs_base_dir'."
            return
        }

        # Determine the name of the currently active venv (if any).
        $currentActivatedVenvName = if ($env:VIRTUAL_ENV) { (Split-Path -Leaf $env:VIRTUAL_ENV) } else { "" }

        # If the target venv is already active.
        if ($venv_name -eq $currentActivatedVenvName) {
            if ($venv_action -eq "toggle") {
                $venv_action = "deactivate" # In toggle mode, if active, then deactivate.
            } else {
                Write-Host "Virtual environment '$venv_name' is already activated."
                return # If explicitly activating and already active, nothing to do.
            }
        } else {
            $activateScriptPath = Join-Path "$venvs_base_dir" "$venv_name" "Scripts\Activate.ps1"
            if (-not (Test-Path $activateScriptPath -PathType Leaf)) {
                Write-Host "Activation script not found for venv '$venv_name' at '$activateScriptPath'."
                Write-Host "Please ensure the venv is correctly created or verify the path."
                return
            }

            # If the target venv is not 'base', ensure the prompt is not disabled (assuming user's prompt respects this).
            if ($venv_name -ne "base") {
                Remove-Item Env:\VIRTUAL_ENV_DISABLE_PROMPT -ErrorAction SilentlyContinue
            }

            try {
                # Dot-source the activate script to execute it within the current PowerShell session.
                # This changes the environment variables (like PATH, VIRTUAL_ENV) for the current session.
                . $activateScriptPath
                Write-Host "Activated virtual environment: '$venv_name'."
            } catch {
                Write-Host "Error activating virtual environment '$venv_name': $($_.Exception.Message)"
                return
            }
        }
    }

    # Logic for deactivating a virtual environment.
    if ($venv_action -eq "deactivate") {
        $currentActivatedVenvName = if ($env:VIRTUAL_ENV) { (Split-Path -Leaf $env:VIRTUAL_ENV) } else { "" }
        $baseVenvPath = Join-Path $venvs_base_dir "base"

        # Only proceed if a non-base venv is currently active.
        if ($currentActivatedVenvName -ne "base" -and $env:VIRTUAL_ENV) {
            # Check if the 'deactivate' function (usually defined by `Activate.ps1`) exists.
            if (Get-Command deactivate -CommandType Function -ErrorAction SilentlyContinue) {
                deactivate # Call the existing deactivate function.
                Write-Host "Deactivated current virtual environment."
            } else {
                # Fallback for deactivation if the 'deactivate' function isn't found.
                # This attempts to manually clean up environment variables.
                Write-Host "Deactivate function not found. Attempting manual deactivation..."
                # Remove the venv's 'Scripts' path from the system PATH.
                $env:PATH = ($env:PATH -split ';') | Where-Object { -not $_.StartsWith($env:VIRTUAL_ENV, [System.StringComparison]::OrdinalIgnoreCase) } | Join-String -Separator ';'
                # Clear the VIRTUAL_ENV environment variable.
                Remove-Item Env:\VIRTUAL_ENV -ErrorAction SilentlyContinue
                # Clear the PROMPT environment variable (as activation scripts often modify it).
                Remove-Item Env:\PROMPT -ErrorAction SilentlyContinue
                Write-Host "Manually deactivated virtual environment."
            }

            # Set VIRTUAL_ENV_DISABLE_PROMPT (if user's prompt respects it).
            $env:VIRTUAL_ENV_DISABLE_PROMPT = 1

            # Attempt to activate the 'base' venv after deactivation.
            $baseActivateScriptPath = Join-Path $baseVenvPath "Scripts\Activate.ps1"
            if (Test-Path $baseActivateScriptPath -PathType Leaf) {
                Write-Host "Activating 'base' virtual environment."
                try {
                    . $baseActivateScriptPath # Dot-source the base venv's activation script.
                } catch {
                    Write-Host "Error activating 'base' virtual environment: $($_.Exception.Message)"
                }
            } else {
                Write-Host "Base virtual environment activation script not found. Consider creating a 'base' venv if you intend to use it as a default."
            }
        } else {
            Write-Host "No virtual environment is currently activated (or 'base' is already active)."
        }
    }
}

. $PSScriptRoot\venv_completion.ps1  # Setup autocompletion

$baseActivateScriptPath = Join-Path $HOME ".local\venvs\base\Scripts\Activate.ps1"
if (Test-Path $baseActivateScriptPath -PathType Leaf) {
    $env:VIRTUAL_ENV_DISABLE_PROMPT = 1
    . $baseActivateScriptPath
} else {
    Write-Host "No default virtual env created!"
}
Remove-Variable baseActivateScriptPath

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
