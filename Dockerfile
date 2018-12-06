FROM centos:centos7

MAINTAINER Marcelo Teixeira Monteiro (tuxmonteiro)

ARG ruby_ver=2.3.6
ARG node_ver=8.9.3
ENV RUBY_ENV=${ruby_ver}

RUN groupadd -g 12386 globodns; useradd -m -u 12386 -g globodns -d /home/globodns globodns && \
    set -x \  
    yum install epel-release \ 
    && yum -y install libyaml libyaml-devel readline-devel ncurses-devel gdbm-devel tcl-devel openssl-devel db4-devel libffi-devel which gpg gcc gcc-c++ make bind-utils \ 
    && gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB \ 
    || (gpg --keyserver hkp://pgp.mit.edu --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && exit 1) \ 
    && curl -L get.rvm.io | bash -s stable \ 
    && yum clean all \ 
    && /bin/bash -l -c "rvm requirements" \ 
    && /bin/bash -l -c "rvm install ${RUBY_ENV}" \ 
    && /bin/bash -l -c "rvm use ${RUBY_ENV} --default" \
    && chown -R globodns.globodns /usr/local/rvm/gems/ruby-${RUBY_ENV}

ENV PATH "${PATH}:/usr/local/rvm/rubies/ruby-${RUBY_ENV}/bin"

USER globodns

WORKDIR /home/globodns

COPY ./* ./.versions.conf ./.rspec /home/globodns/

ADD docker/start.sh /usr/bin/

CMD ["/usr/bin/start.sh"]
