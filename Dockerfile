FROM tomcat:8-jdk8 as tomcat

FROM apache/skywalking-java-agent:8.11.0-alpine as skywalking

FROM bitnami/jmx-exporter:latest as jmx-exporter

FROM library/consul:latest as consul

FROM hashicorp/consul-template:latest as consul-template

FROM tomcat:8-jdk8

ENV TZ=Asia/Shanghai LANG=en_US.UTF-8 UMASK=0022 CATALINA_HOME=/usr/local/tomcat CATALINA_BASE=/app/tomcat 
ENV PATH=$CATALINA_HOME/bin:/usr/java/latest/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

COPY --from=consul  /bin/consul          /usr/local/bin/

COPY --from=consul-template  /bin/consul-template          /usr/local/bin/

COPY --from=skywalking  /skywalking/agent/          /app/skywalking/

COPY --from=jmx-exporter /opt/bitnami/jmx-exporter/ /app/jmx-exporter/

# apt: cron openjdk-17-jdk-headless
# yum crontabs cronie
RUN set -eux; useradd -u 8080 -o -s /bin/bash app || true ;\
    echo -e 'export PATH=$JAVA_HOME/bin:$PATH\n' | tee /etc/profile.d/91-env.sh ;\
	apt-get update -y ;\
    apt-get install -y bash ca-certificates curl wget    openssl sudo iproute2 iputils-ping iputils-arping iputils-tracepath  net-tools iptables tzdata \
        procps   wget tzdata less   unzip  tcpdump   socat jq mtr psmisc logrotate  rsync  cron strace \
        openssh-client luajit luarocks iperf3 atop htop iftop gnupg2 vim libpcre++-dev libpcre2-dev libpcre3-dev ;\
     echo "app"> /etc/cron.allow  ;\
	 mkdir -p /logs /usr/local/tomcat /app/war /app/tomcat/conf /app/tomcat/logs /app/tomcat/work /app/tomcat/bin /app/tomcat/lib/org/apache/catalina/util ; \
	 cp -rv /usr/local/tomcat/conf/server.xml /app/tomcat/conf/ ;\
    echo "<tomcat-users/>" | tee  /app/tomcat/conf/tomcat-users.xml ;\
    sed -i -e 's@webapps@/app/war@g' -e 's@SHUTDOWN@_SHUTUP_8080@g' /app/tomcat/conf/server.xml ;\
    echo -e "server.info=WAF\nserver.number=\nserver.built=\n" | tee /app/tomcat/lib/org/apache/catalina/util/ServerInfo.properties ;\
    mkdir -p /app/jar/conf /app/jar/lib /app/jar/tmp  /app/jar/bin ;\
    chown app:app -R /usr/local/tomcat /app /logs;
