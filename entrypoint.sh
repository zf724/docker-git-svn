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
