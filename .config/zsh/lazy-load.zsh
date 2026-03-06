# Lazy-load version managers for faster shell startup
# Instead of running init on every shell, create placeholder functions
# that initialize on first use, then call through to the real command.

# --- NVM (Node Version Manager) ---
_lazy_load_nvm() {
  unfunction nvm node npm npx pnpm yarn corepack 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

for cmd in nvm node npm npx pnpm yarn corepack; do
  eval "${cmd}() { _lazy_load_nvm; ${cmd} \"\$@\" }"
done

# --- pyenv (Python Version Manager) ---
_lazy_load_pyenv() {
  unfunction pyenv python python3 pip pip3 2>/dev/null
  if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
  fi
  if which pyenv-virtualenv-init >/dev/null 2>&1; then
    eval "$(pyenv virtualenv-init -)"
  fi
}

for cmd in pyenv python python3 pip pip3; do
  eval "${cmd}() { _lazy_load_pyenv; ${cmd} \"\$@\" }"
done

# --- rbenv (Ruby Version Manager) ---
_lazy_load_rbenv() {
  unfunction rbenv ruby gem bundle bundler irb 2>/dev/null
  eval "$(rbenv init - zsh)"
}

for cmd in rbenv ruby gem bundle bundler irb; do
  eval "${cmd}() { _lazy_load_rbenv; ${cmd} \"\$@\" }"
done
