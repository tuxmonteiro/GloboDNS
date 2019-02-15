FROM tuxmonteiro/ruby:centos7

MAINTAINER Marcelo Teixeira Monteiro (tuxmonteiro)

ARG GIT_URL=https://github.com/globocom/GloboDNS.git
ARG GIT_BRANCH=master
ARG ruby_ver=2.3.6
ENV RUBY_ENV ${ruby_ver}
ENV PATH "${PATH}:/usr/local/rvm/rubies/ruby-${RUBY_ENV}/bin"
ENV GDNS_VERSION master
ENV BIND_MASTER_IPADDR 127.0.0.1
ENV BIND_CHROOT_DIR "/var/named/chroot"
ENV ADDITIONAL_DNS_SERVERS ""
ENV USER globodns
ENV SUBDIR_DEPTH 2
ENV ENABLE_VIEW true
ENV EXPORT_DELAY 10
ENV GIT_AUTHOR "GloboDNS <globodns@globodns.local>"
ENV GIT_USERNAME "GloboDNS"
ENV GDNS_HOME /home/globodns
ENV GIT_URL ${GIT_URL}
ENV GIT_BRANCH ${GIT_BRANCH}

ADD start.sh /usr/bin/

RUN set -x \
    && yum clean all \
    && yum -y install bind-utils bind-chroot git iproute nmap-ncat \
    && groupadd -g 12386 globodns; useradd -m -u 12386 -g globodns -G named -d ${GDNS_HOME} globodns \
    && mkdir -p "${BIND_CHROOT_DIR}" \
    && chown -R globodns.globodns /usr/local/rvm/gems/ruby-${RUBY_ENV} \
    && echo 'globodns ALL=(ALL) NOPASSWD: /usr/sbin/named-checkconf' >> /etc/sudoers \
    && echo 'globodns ALL=(ALL) NOPASSWD: /usr/libexec/setup-named-chroot.sh' >> /etc/sudoers \
    && chown -R globodns.named /etc/named \
    && mv /etc/named.conf /etc/named \
    && ln -s /etc/named/named.conf /etc/named.conf \
    && rndc-confgen -a -u globodns \
    && grep '^Host' /etc/ssh/ssh_config >/dev/null 2>&1 \
    && echo -e '\tUserKnownHostsFile /dev/null' >> /etc/ssh/ssh_config \
    && echo -e '\tStrictHostKeyChecking no' >> /etc/ssh/ssh_config \
    && echo -e '\tPort 2002' >> /etc/ssh/ssh_config \
    && git clone -b ${GIT_BRANCH} ${GIT_URL} ${GDNS_HOME}/app \
    && mkdir ${GDNS_HOME}/.ssh && chmod 700 ${GDNS_HOME}/.ssh \
    && echo "source /usr/local/rvm/environments/ruby-${RUBY_ENV}@global" >> "${GDNS_HOME}/.bash_profile" \
    && chmod +x "${GDNS_HOME}/.bash_profile"

ADD id_rsa ${GDNS_HOME}/.ssh/
ADD id_rsa.pub ${GDNS_HOME}/.ssh/

RUN chown -R globodns.globodns "${GDNS_HOME}/app" "${GDNS_HOME}/.ssh" \
    && chmod 600 ${GDNS_HOME}/.ssh/id_rsa \
    && chmod 644 ${GDNS_HOME}/.ssh/id_rsa.pub

USER globodns

WORKDIR ${GDNS_HOME}/app

RUN set -x \
    && source /usr/local/rvm/environments/ruby-${RUBY_ENV}@global \
    && rm -rf vendor; bundle lock; bundle install --deployment --without=test,development \
    && git config --global user.email "${GIT_AUTHOR}" \
    && git config --global user.name "${GIT_USERNAME}"

CMD ["/usr/bin/start.sh"]
