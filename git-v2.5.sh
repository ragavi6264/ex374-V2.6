#!/bin/bash
GIT_URL=https://git.lab.example.com
GIT_USER=student
SRC=~/ex374-V2.6
DEST=/home/student/script
REPOS="create_complex_user create_user custom_collection dynamic_inventory master_playbook tunning_ansible user_playbook web_content web_server"

HOST=${GIT_URL#*://}

read -rsp "GitLab access token (api scope): " GIT_TOKEN; echo

mkdir -p "$DEST" || exit 1
cd "$DEST" || exit 1

# Let git use the token for clone/push without prompting
git config --global credential.helper 'cache --timeout=600'
printf "protocol=https\nhost=%s\nusername=%s\npassword=%s\n\n" \
  "$HOST" "$GIT_USER" "$GIT_TOKEN" | git credential approve

# 1. Create 9 PUBLIC projects under the student user
for r in $REPOS; do
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    --request POST "$GIT_URL/api/v4/projects" \
    --header "PRIVATE-TOKEN: $GIT_TOKEN" \
    --data-urlencode "name=$r" \
    --data-urlencode "visibility=public")
  case $code in
    201) echo "$r: created" ;;
    400) echo "$r: already exists" ;;
    401) echo "ERROR: token rejected (HTTP 401)"; exit 1 ;;
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

unset GIT_TOKEN
