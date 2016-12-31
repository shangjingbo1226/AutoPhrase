FROM debian:jessie
MAINTAINER Jialu Liu <remenberl@gmail.com>

RUN \
    echo "===> add webupd8 repository..."  && \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list  && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list  && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886  && \
    apt-get update  && \
    \
    \
    echo "===> install Java"  && \
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections  && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections  && \
    DEBIAN_FRONTEND=noninteractive  apt-get install -y --force-yes oracle-java8-installer oracle-java8-set-default

RUN \
    echo "===> install g++" && \
    apt-get update && apt-get install -y --force-yes g++

RUN \
    echo "===> install make, curl, perl" && \
    apt-get update && apt-get install -y --force-yes make curl perl

ADD autophrase.tar.gz /

RUN \
    echo "===> compile" &&\
    cd /autophrase && bash compile.sh 

RUN \
    echo "===> clean up..."  && \
    apt-get purge -y --force-yes make && \
    apt-get autoremove -y --purge make && \
    rm -rf /var/cache/oracle-jdk8-installer  && \
    apt-get clean  && \
    rm -rf /var/lib/apt/lists/*

ENV COMPILE 0

WORKDIR /autophrase
