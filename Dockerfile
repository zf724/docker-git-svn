FROM alpine

############################ git server ####################################
# "--no-cache" is new in Alpine 3.3 and it avoid using
# "--update + rm -rf /var/cache/apk/*" (to remove cache)
RUN apk add --no-cache \
    openssh \
    git
# Key generation on the server
RUN ssh-keygen -A
# -D flag avoids password generation
# -s flag changes user's shell
RUN set -xe \
    && sed -i '/^PasswordAuthentication/s/no/yes/' /etc/ssh/sshd_config \
    && adduser -D -s /usr/bin/git-shell git \
    && mkdir /home/git/.ssh
# This is a login shell for SSH accounts to provide restricted Git access.
# It permits execution only of server-side Git commands implementing the
# pull/push functionality, plus custom commands present in a subdirectory
# named git-shell-commands in the user’s home directory.
# More info: https://git-scm.com/docs/git-shell
COPY git-shell-commands /home/git/git-shell-commands
########################## subversion server #################################
# Install and configure Apache WebDAV and Subversion
RUN apk add --no-cache \
    apache2 \
    apache2-utils \
    apache2-webdav \
    mod_dav_svn \
    subversion
COPY davsvn.conf /etc/apache2/conf.d/
############################# others #########################################
ENV GIT_USER git
ENV GIT_PASS 123456
ENV SVN_USER svn
ENV SVN_PASS 123456
ENV REPO_TEST testrepo

RUN set -xe \
    && mkdir -p /repos/keys \
    && mkdir -p /repos/git \
    && mkdir -p /repos/svn

WORKDIR /repos

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 80

ENTRYPOINT ["/entrypoint.sh"]
