# set PATH so it includes user's private bin if it exists
if [[ -d "$HOME"/.local/bin && "$PATH" != *"$HOME"/.local/bin* ]]; then
  PATH="$HOME/.local/bin:$PATH"
fi

if [[ -n "$BASH_VERSION" && -f "$HOME"/.bashrc ]]; then
  source "$HOME"/.bashrc
fi
