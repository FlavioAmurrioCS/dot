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
