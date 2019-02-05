FROM tuxmonteiro/ruby:centos7

MAINTAINER Marcelo Teixeira Monteiro (tuxmonteiro)

ARG ruby_ver=2.3.6
ENV RUBY_ENV=${ruby_ver}
ENV PATH "${PATH}:/usr/local/rvm/rubies/ruby-${RUBY_ENV}/bin"
ENV GDNS_VERSION master
ENV BIND_MASTER_IPADDR 127.0.0.1
ENV BIND_CHROOT_DIR "/var/named/chroot"
ENV ADDITIONAL_DNS_SERVERS ""
ENV USER globodns
ENV SUBDIR_DEPTH 2
ENV ENABLE_VIEW true
ENV EXPORT_DELAY 10

RUN set -x \  
    && yum clean all \ 
    && yum -y install bind-utils bind-chroot git

RUN groupadd -g 12386 globodns; useradd -m -u 12386 -g globodns -G named -d /home/globodns globodns \
    && mkdir -p /var/named/chroot \
    && chown -R globodns.globodns /usr/local/rvm/gems/ruby-${RUBY_ENV} \
    && echo 'globodns ALL=(ALL) NOPASSWD: /usr/sbin/named-checkconf' >> /etc/sudoers \
    && chown -R globodns.named /etc/named \
    && mv /etc/named.conf /etc/named \
    && ln -s /etc/named/named.conf /etc/named.conf \
    && rndc-confgen -a -u globodns

USER globodns

WORKDIR /home/globodns

ADD docker/start.sh /usr/bin/

RUN curl -Lk https://github.com/globocom/GloboDNS/archive/${GDNS_VERSION}.tar.gz | tar xzv \
    && mv GloboDNS-${GDNS_VERSION} app \
    && cd /home/globodns/app \
    && source /usr/local/rvm/environments/ruby-${RUBY_ENV}@global \
    && rm -rf vendor; bundle lock; bundle install --deployment --without=test,development \
    && git config --global user.email "globodns@globodns.local" \
    && git config --global user.name "GloboDNS"

ADD config/globodns.yml /home/globodns/app/config/globodns.yml

WORKDIR /home/globodns/app

CMD ["/usr/bin/start.sh"]
