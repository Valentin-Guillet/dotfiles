# Helper functions for buffer modification
function local:Replace-FirstWord ($newCmd) {
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    $match = [regex]::Match($line, '^\s*\S+')
    if (-not($match.Success)) {
        return
    }

    $oldLen = $match.Length
    $newLen = $newCmd.Length
    $newLine = [regex]::Replace($line, '^\s*\S+', $newCmd)

    if ($cursor -le $oldLen) {
        # If cursor was inside/on the old word, place it at the end of the new word
        $newCursor = $newLen
    } else {
        # If cursor was in the remaining arguments, shift it by the length difference
        $newCursor = $cursor + ($newLen - $oldLen)
    }

    # Clamp position to valid line bounds
    $newCursor = [Math]::Max(0, [Math]::Min($newLine.Length, $newCursor))

    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $newLine)
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($newCursor)
}

function local:Prepend-FirstWord ($newCmd) {
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    $prefix = "$newCmd "
    $newLine = "$prefix$line"
    $newCursor = $cursor + $prefix.Length

    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $newLine)
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($newCursor)
}

Set-PSReadLineKeyHandler -Chord 'Alt+i' -ScriptBlock {
    Replace-FirstWord 'ls'
}

Set-PSReadLineKeyHandler -Chord 'Alt+I' -ScriptBlock {
    Prepend-FirstWord 'ls'
}

Set-PSReadLineKeyHandler -Chord 'Alt+o' -ScriptBlock {
    Replace-FirstWord 'open'
}

Set-PSReadLineKeyHandler -Chord 'Alt+O' -ScriptBlock {
    Prepend-FirstWord 'open'
}

Set-PSReadLineKeyHandler -Chord 'Alt+v' -ScriptBlock {
    Replace-FirstWord 'vim'
}

Set-PSReadLineKeyHandler -Chord 'Alt+V' -ScriptBlock {
    Prepend-FirstWord 'vim'
}

Set-PSReadLineKeyHandler -Chord 'Alt+B' -ScriptBlock {
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    $match = [regex]::Match($line, '^\s*\S+\s*')
    if ($match.Success) {
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($match.Length)
    }
}

Set-PSReadLineKeyHandler -Chord 'Alt+C' -ScriptBlock {
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($line -match '\S+') {
        $tokens = [regex]::Matches($line, '\S+')
        $lastToken = $tokens[$tokens.Count - 1].Value
        $spacer = if ($line.EndsWith(' ')) { '' } else { ' ' }
        $newLine = "$line$spacer$lastToken"
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $newLine)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($newLine.Length)
    }
}

Set-PSReadLineKeyHandler -Chord 'Alt+e' -ScriptBlock {
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    $match = [regex]::Match($line, '^\s*\S+\s*')
    if ($match.Success) {
        $deletedLen = $match.Length
        $newLine = $line.Substring($deletedLen)
        $newCursor = [Math]::Max(0, $cursor - $deletedLen)
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $newLine)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($newCursor)
    }
}
