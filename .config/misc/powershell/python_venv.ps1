
# UV autocompletion

if (Get-Command uv -ErrorAction Ignore)
{
    (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression
    (& uvx --generate-shell-completion powershell) | Out-String | Invoke-Expression
}

