#!/bin/bash
GIT_URL=https://git.lab.example.com
GIT_USER=student
SRC=~/ex374-V2.6              # folder holding the 9 source folders
DEST=/home/student/script   # where the clones will live
REPOS="create_complex_user create_user custom_collection dynamic_inventory master_playbook tunning_ansible user_playbook web_content web_server"

read -sp "Gitea password for $GIT_USER: " GIT_PASS; echo
git config --global credential.helper 'cache --timeout=600'

cd "$DEST" || exit 1

# 1. Create the empty repos (no README, so they stay empty)
for r in $REPOS; do
  curl -s -o /dev/null -w "$r create: HTTP %{http_code}\n" \
    -u "$GIT_USER:$GIT_PASS" -X POST "$GIT_URL/api/v1/user/repos" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$r\",\"private\":false}"
done

# 2. Clone, copy content, commit, push
for r in $REPOS; do
  [ -d "$DEST/$r/.git" ] || git clone "$GIT_URL/$GIT_USER/$r.git"
  cd "$DEST/$r" || continue
  git checkout -B main
  rsync -a --exclude='.git' "$SRC/$r/" .
  git add -A
  git commit -m "first commit" || echo "nothing to commit in $r"
  git push -u origin main
  cd "$DEST"
done
