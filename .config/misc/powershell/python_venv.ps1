
# UV autocompletion

if (Get-Command uv -errorAction SilentlyContinue)
{
    (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression
    (& uvx --generate-shell-completion powershell) | Out-String | Invoke-Expression
}

