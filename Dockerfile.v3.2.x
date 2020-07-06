FROM ubuntu:18.04
MAINTAINER Matt Bentley <mbentley@mbentley.net>

# install omada controller (instructions taken from install.sh); then create a user & group and set the appropriate file system permissions
RUN \
  echo "**** Install Dependencies ****" &&\
  apt-get update &&\
  DEBIAN_FRONTEND="noninteractive" apt-get install -y gosu net-tools tzdata wget &&\
  rm -rf /var/lib/apt/lists/* &&\
  echo "**** Download Omada Controller ****" &&\
  cd /tmp &&\
  wget -nv "https://static.tp-link.com/2020/202004/20200420/Omada_Controller_v3.2.10_linux_x64.tar.gz" &&\
  echo "**** Extract and Install Omada Controller ****" &&\
  tar zxvf Omada_Controller_v3.2.10_linux_x64.tar.gz &&\
  rm Omada_Controller_v3.2.10_linux_x64.tar.gz &&\
  cd Omada_Controller_* &&\
  mkdir /opt/tplink/EAPController -vp &&\
  cp bin /opt/tplink/EAPController -r &&\
  cp data /opt/tplink/EAPController -r &&\
  cp properties /opt/tplink/EAPController -r &&\
  cp webapps /opt/tplink/EAPController -r &&\
  cp keystore /opt/tplink/EAPController -r &&\
  cp lib /opt/tplink/EAPController -r &&\
  cp install.sh /opt/tplink/EAPController -r &&\
  cp uninstall.sh /opt/tplink/EAPController -r &&\
  cp jre /opt/tplink/EAPController/jre -r &&\
  chmod 755 /opt/tplink/EAPController/bin/* &&\
  chmod 755 /opt/tplink/EAPController/jre/bin/* &&\
  echo "**** Cleanup ****" &&\
  cd /tmp &&\
  rm -rf /tmp/Omada_Controller* &&\
  echo "**** Setup omada User Account ****" &&\
  groupadd -g 508 omada &&\
  useradd -u 508 -g 508 -d /opt/tplink/EAPController omada &&\
  mkdir /opt/tplink/EAPController/logs /opt/tplink/EAPController/work &&\
  chown -R omada:omada /opt/tplink/EAPController/data /opt/tplink/EAPController/logs /opt/tplink/EAPController/work

RUN sed -i -e 's:8043:443:' -e 's:8088:80:' \
    /opt/tplink/EAPController/properties/jetty.properties

COPY entrypoint.sh /entrypoint.sh

WORKDIR /opt/tplink/EAPController
EXPOSE 80 443 27001/udp 27002 29810/udp 29811 29812 29813
HEALTHCHECK --start-period=5m CMD wget --quiet --tries=1 --no-check-certificate -O /dev/null --server-response --timeout=5 https://127.0.0.1:8043/login || exit 1
VOLUME ["/opt/tplink/EAPController/data","/opt/tplink/EAPController/work","/opt/tplink/EAPController/logs","/cert"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/opt/tplink/EAPController/jre/bin/java","-server","-Xms128m","-Xmx1024m","-XX:MaxHeapFreeRatio=60","-XX:MinHeapFreeRatio=30","-XX:+HeapDumpOnOutOfMemoryError","-XX:-UsePerfData","-Deap.home=/opt/tplink/EAPController","-cp","/opt/tplink/EAPController/lib/*:","com.tp_link.eap.start.EapLinuxMain"]
