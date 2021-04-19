# dot
https://www.atlassian.com/git/tutorials/dotfiles

```bash
alias dot='git "--git-dir=${HOME}/.cfg/" "--work-tree=${HOME}"'
git clone --bare git@github.com:FlavioAmurrioCS/dot.git "${HOME}/.cfg"

if dot checkout; then
  echo "Checked out config.";
else
    echo "Backing up pre-existing dot files.";
    mkdir -p ~/.config-backup
    dot checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} ~/.config-backup/{}
    dot checkout
fi;
```

```bash
python3 -m pip install -U pipenv virtualenvwrapper bpython pip autopep8 flake8-mypy --user
```

# dot

This repo is to setup development enviroment all at onces. This uses
[this system](https://www.atlassian.com/git/tutorials/dotfiles) to manage
dotfiles. Having this repo on your VDE will also rebuild will all dev tools
already installed. To activate this please fork this repo:
[vdi-cloud-init](https://github.vrsn.com/famurriomoya/vdi-cloud-init).

## Installation Instructions(MAC and LINUX)

```bash
# Using git bare repositories. All config files are non user specific.
alias config='git "--git-dir=${HOME}/.cfg/" "--work-tree=${HOME}"'
git clone --bare git@github.vrsn.com:famurriomoya/dot.git "${HOME}/.cfg"

# Backs up previous config files to ~/.config-backup/ and places in new ones.
if config checkout; then
  echo "Checked out config.";
else
    echo "Backing up pre-existing dot files.";
    mkdir -p ~/.config-backup
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} ~/.config-backup/{}
    config checkout
fi;

# Get the new enviromental Variables
source ~/.bashrc

# Dont show untracked files in home directory
config config --local status.showUntrackedFiles no

# Backup ~/.ssh/config and place in a new one.
setup_ssh

# Setup up current machine. Includes extension installation for mac, VDE and VDI.
setup
```


bat
direnv
docker-compose
fd
fzf
hadolint
lazydocker
lazydocker
lazygit
lazynpm
rg
shellcheck
shfmt
tldr
tmux
