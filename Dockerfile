FROM tuxmonteiro/ruby:centos7

MAINTAINER Marcelo Teixeira Monteiro (tuxmonteiro)

ARG ruby_ver=2.3.6
ENV RUBY_ENV=${ruby_ver}
ENV PATH "${PATH}:/usr/local/rvm/rubies/ruby-${RUBY_ENV}/bin"
ENV GDNS_VERSION 1.7.10

RUN set -x \  
    && yum clean all \ 
    && yum -y install bind-utils bind git

RUN groupadd -g 12386 globodns; useradd -m -u 12386 -g globodns -d /home/globodns globodns \
    && chown -R globodns.globodns /usr/local/rvm/gems/ruby-${RUBY_ENV} \
    && echo 'globodns ALL=(ALL) NOPASSWD: /usr/sbin/named-checkconf' >> /etc/sudoers

USER globodns

WORKDIR /home/globodns

ADD docker/start.sh /usr/bin/

RUN curl -Lk https://github.com/globocom/GloboDNS/archive/${GDNS_VERSION}.tar.gz | tar xzv \
    && mv GloboDNS-${GDNS_VERSION} app \
    && cd /home/globodns/app \
    && source /usr/local/rvm/environments/ruby-${RUBY_ENV}@global \
    && rm -rf vendor; bundle install --deployment --without=test,development

WORKDIR /home/globodns/app

CMD ["/usr/bin/start.sh"]
