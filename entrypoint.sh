#!/bin/sh

# If there is some public key in keys folder
# then it copies its contain in authorized_keys file
if [ "$(ls -A /repos/git-keys/)" ]; then
  cd /home/git
  cat /repos/git-keys/*.pub > .ssh/authorized_keys
  chown -R git:git .ssh
  chmod 700 .ssh
  chmod -R 600 .ssh/*
fi

# Checking permissions and fixing SGID bit in repos folder
# More info: https://github.com/jkarlosb/git-server-docker/issues/1
if [ "$(ls -A /repos/git/)" ]; then
  cd /repos/git
  chown -R git:git .
  chmod -R ug+rwX .
  find . -type d -exec chmod g+s '{}' +
fi

echo $GIT_USER:$GIT_PASS | chpasswd
test ! -d "/repos/git/$REPO_TEST" && git init --bare /repos/git/$REPO_TEST
echo "Creating the git repository: $SVN_REPO into /repos/git/$SVN_REPO"
# -D flag avoids executing sshd as a daemon
/usr/sbin/sshd # -D

if [ ! -d "/repos/svn/$REPO_TEST" ]; then
  svnadmin create /repos/svn/$REPO_TEST
  sed -i -e '/anon-access /s/^# //' \
         -e '/auth-access /s/^# //' \
         -e '/password-db /s/^# //' \
         -e '/authz-db /s/^# //'    \
         -e '/anon-access /s/read/none/' \
         /repos/svn/$REPO_TEST/conf/svnserve.conf
  echo "$SVN_USER = $SVN_PASS" >> /repos/svn/$REPO_TEST/conf/passwd
  { \
    echo "[repository:/$REPO_TEST]";  \
    echo "$SVN_USER = rw"; \
  }>> /repos/svn/$REPO_TEST/conf/authz
  echo "Creating the svn repository: $REPO_TEST into /repos/svn/$REPO_TEST"
fi
/usr/bin/svnserve -r /repos/svn -d --foreground
