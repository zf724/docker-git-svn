#!/bin/sh

# If there is some public key in keys folder
# then it copies its contain in authorized_keys file
if [ "$(ls -A /repos/keys/)" ]; then
  cd /home/git
  cat /repos/keys/*.pub > .ssh/authorized_keys
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
# -D flag avoids executing sshd as a daemon
/usr/sbin/sshd -D

htpasswd -bc /etc/apache2/conf.d/davsvn.htpasswd $SVN_USER $SVN_PASS
httpd -D FOREGROUND

test ! -d "/repos/git/$REPO_TEST" && git init --bare /repos/git/$REPO_TEST
echo "Creating the git repository: $SVN_REPO into /repos/git/$SVN_REPO"
test ! -d "/repos/svn/$REPO_TEST" && svnadmin create /repos/svn/$REPO_TEST && chgrp -R apache /repos/svn/$REPO_TEST && chmod -R 775 /repos/svn/$REPO_TEST
echo "Creating the svn repository: $SVN_REPO into /repos/svn/$SVN_REPO"
