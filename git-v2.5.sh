#!/bin/bash
GIT_URL=https://git.lab.example.com      # must be your GITEA server (see note below)
GIT_USER=student
SRC=~/ex374-V2.6
DEST=/home/student/script
REPOS="create_complex_user create_user custom_collection dynamic_inventory master_playbook tunning_ansible user_playbook web_content web_server"

PROTO=${GIT_URL%%://*}
HOST=${GIT_URL#*://}

read -sp "Gitea password for $GIT_USER: " GIT_PASS; echo

mkdir -p "$DEST" || exit 1
cd "$DEST" || exit 1

# Give git the credentials up front so clone/push never prompt
git config --global credential.helper 'cache --timeout=600'
printf "protocol=%s\nhost=%s\nusername=%s\npassword=%s\n\n" \
  "$PROTO" "$HOST" "$GIT_USER" "$GIT_PASS" | git credential approve

# 1. Create 9 empty PUBLIC repos under the student user
for r in $REPOS; do
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "$GIT_USER:$GIT_PASS" -X POST "$GIT_URL/api/v1/user/repos" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$r\",\"private\":false}")
  case $code in
    201) echo "$r: created" ;;
    409) echo "$r: already exists" ;;
    *)   echo "$r: FAILED (HTTP $code)" ;;
  esac
done

# 2. Clone, copy content, commit, push
for r in $REPOS; do
  [ -d "$SRC/$r" ] || { echo "$r: source folder missing, skipping"; continue; }
  [ -d "$DEST/$r/.git" ] || git clone "$GIT_URL/$GIT_USER/$r.git" || continue
  cd "$DEST/$r" || continue
  git checkout -B main
  rsync -a --exclude='.git' "$SRC/$r/" .
  git add -A
  if git diff --cached --quiet; then
    echo "$r: nothing to commit"
  else
    git commit -m "first commit"
  fi
  git push -u origin main
  cd "$DEST"
done

unset GIT_PASS
