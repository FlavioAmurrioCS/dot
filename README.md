# dot

```bash
alias dot='git "--git-dir=${HOME}/.cfg/" "--work-tree=${HOME}"'
git clone --bare git@github.com:FlavioAmurrioCS/dot.git "${HOME}/.cfg"

mkdir -p ~/.config-backup
dot checkout
if [ $? = 0 ]; then
  echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    dot checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} ~/.config-backup/{}
fi;
dot checkout
dot config status.showUntrackedFiles no
```