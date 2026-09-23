
Set-PSReadLineOption -EditMode Emacs
$env:EDITOR = "vim"


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


foreach ($file in "paths.ps1", "functions.ps1", "aliases.ps1", "readline.ps1", "local_paths.ps1", "local_functions.ps1", "local_aliases.ps1") {
    $path = Join-Path $PSScriptRoot $file
    if (Test-Path -Path $path -PathType Leaf) {
        . $path
    }
}

Get-ChildItem "$PSScriptRoot\autocomplete\*.ps1" -ErrorAction Ignore | ForEach-Object {
    . $_.FullName
}

function configg {
    vim $PROFILE
    . $PROFILE
}

function configgp {
    vim $PSScriptRoot\paths.ps1
    . $PROFILE
}

function configgf {
    vim $PSScriptRoot\functions.ps1
    . $PROFILE
}

function configga {
    vim $PSScriptRoot\aliases.ps1
    . $PROFILE
}

function configp {
    vim $PSScriptRoot\local_paths.ps1
    . $PROFILE
}

function configf {
    vim $PSScriptRoot\local_functions.ps1
    . $PROFILE
}

function configa {
    vim $PSScriptRoot\local_aliases.ps1
    . $PROFILE
}
