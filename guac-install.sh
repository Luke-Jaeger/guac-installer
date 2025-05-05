#!/bin/bash

## step 1.1
add-apt-repository -y ppa:remmina-ppa-team/remmina-next-daily ;  

## step 1.2
apt update && apt upgrade -y ;

## step 1.3
apt install -y gcc vim curl wget g++ libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev build-essential libpango1.0-dev libssh2-1-dev libvncserver-dev libtelnet-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev libwebsockets-dev ubuntu-desktop-minimal freerdp2-dev freerdp2-x11 xrdp -y ;

## step 2.1 
apt install -y openjdk-11-jdk ;

## step 2.2
echo $(java --version) ;

## set java home environment variable for all users
echo "JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
PATH=$PATH:$JAVA_HOME/bin
export JAVA_HOME
export PATH" >> /etc/profile ;
source /etc/profile ;

## step 2.3
# useradd -m -U -d /opt/tomcat -s /bin/false tomcat ;

## step 2.4
# curl -O --output-dir /tmp https://downloads.apache.org/tomcat/tomcat-9/v9.0.100/bin/apache-tomcat-9.0.100.tar.gz ;

## step 2.5
# tar -xzf /tmp/apache-tomcat-*.tar.gz -C /opt/tomcat/ ;

## step 2.6
# mv /opt/tomcat/apache-tomcat-* /opt/tomcat/tomcatapp ;

## step 2.7
# chown -R tomcat:tomcat /opt/tomcat ;

## step 2.8
find /opt/tomcat/tomcatapp/bin/ -type f -iname "*.sh" -exec chmod +x {} \;

## step 2.9 / 2.10
echo "[Unit]
Description=Tomcat 9 servlet container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment=\"JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64\"
Environment=\"JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true\"

Environment=\"CATALINA_BASE=/opt/tomcat/tomcatapp\"
Environment=\"CATALINA_HOME=/opt/tomcat/tomcatapp\"
Environment=\"CATALINA_PID=/opt/tomcat/tomcatapp/temp/tomcat.pid\"
Environment=\"CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC\"

ExecStart=/opt/tomcat/tomcatapp/bin/startup.sh
ExecStop=/opt/tomcat/tomcatapp/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/tomcat.service ;

## step 2.11s
systemctl daemon-reload ;

## step 2.12
systemctl enable --now tomcat ;

## step 2.13
echo $(systemctl status tomcat) ;

## create shared dir for downloads
mkdir -p /shared ;
chown maker:tomcat /shared ;
chmod 775 /shared ;

## step 3.1
curl -O --output-dir /shared https://downloads.apache.org/guacamole/1.5.5/source/guacamole-server-1.5.5.tar.gz ;

## step 3.2
tar -xzf /shared/guacamole-server-1.5.5.tar.gz -C /shared/ ;

## step 3.3
cd /shared/guacamole-server-1.5.5 ;

## step 3.4
./configure --with-init-dir=/etc/init.d ;

## step 3.5
make ;
make install ;

## step 3.6
ldconfig ;

## step 3.7
mkdir -p /etc/guacamole ;


## step 3.8 / 3.9
echo "[daemon]
pid_file = /var/run/guacd.pid
#log_level = debug

[server]
#bind_host = localhost
bind_host = 127.0.0.1
bind_port = 4822

#[ssl]
#server_certificate = /etc/ssl/certs/guacd.crt
#server_key = /etc/ssl/private/guacd.key
" > /etc/guacamole/guacd.conf ;

## step 3.10
systemctl daemon-reload ;

## step 3.11
systemctl start guacd ;
systemctl enable guacd ;

## step 3.12
echo $(systemctl status guacd) ;

## step 4.1
curl -O --output-dir /shared/ https://archive.apache.org/dist/guacamole/1.5.5/binary/guacamole-1.5.5.war ;

## step 4.2
mv /shared/guacamole-1.5.5.war /etc/guacamole/guacamole.war ;

## step 4.3
ln -s /etc/guacamole/guacamole.war /opt/tomcat/tomcatapp/webapps ;

## step 4.4
echo "GUACAMOLE_HOME=/etc/guacamole" >> /etc/default/tomcat ;

## step 4.5
echo "export GUACAMOLE_HOME=/etc/guacamole" >> /etc/profile ;

## step 4.6 / 4.7
echo "guacd-hostname: localhost
guacd-port:  4822
user-mapping:  /etc/guacamole/user-mapping.xml
auth-provider:  net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
" > /etc/guacamole/guacamole.properties ;

## step 4.8
ln -s /etc/guacamole /opt/tomcat/tomcatapp/.guacamole ;

## step 4.9
chown -R tomcat:tomcat /opt/tomcat ;

## step 4.10 / 4.11
echo "<user-mapping>
        <authorize username=\"\" password=\"\">
                <protocol>rdp</protocol>
                <param name=\"hostname\">127.0.0.1</param>
                <param name=\"port\">3389</param>
                <param name=\"ignore-cert\">true</param>
        </authorize>
</user-mapping>" > /etc/guacamole/user-mapping.xml

## step 4.12
systemctl restart tomcat guacd ;

## step 4.13
echo $(systemctl status tomcat guacd) ;




