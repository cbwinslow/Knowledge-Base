#!/usr/bin/env bash
#===============================================================================
# Script Name : cbw-install-guacamole.sh
# Author      : CBW + GPT-5 Thinking
# Date        : 2025-09-15
# Summary     : Bare-metal install of Apache Guacamole (guacd + Tomcat webapp)
#               on Ubuntu 24.04 with auto port reservation via cbw-port-guard.
# Inputs      : /etc/cbw-ports.conf (managed by cbw-port-guard.sh)
# Outputs     : guacd systemd service + Tomcat webapp at /guacamole
#===============================================================================

set -euo pipefail
trap 'echo \"[ERROR] Failed at line $LINENO\" >&2' ERR

PORT_GUACD_DEFAULT=4822
PORT_TOMCAT_DEFAULT=8080

PORT_GUACD=\"$(/usr/local/sbin/cbw-port-guard.sh reserve GUACD \"$PORT_GUACD_DEFAULT\" | tail -n1)\"
PORT_TOMCAT=\"$(/usr/local/sbin/cbw-port-guard.sh reserve TOMCAT_HTTP \"$PORT_TOMCAT_DEFAULT\" | tail -n1)\"

apt update
apt install -y tomcat10 \
  freerdp2-dev libssh2-1-dev libtelnet-dev libvncserver-dev \
  libjpeg62-turbo-dev libcairo2-dev libpng-dev libossp-uuid-dev libwebp-dev libpulse-dev \
  build-essential autoconf automake libtool pkg-config

GUAC_VER=\"1.5.5\"
cd /tmp
wget -q \"https://downloads.apache.org/guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz\" -O guac-src.tgz
tar -xzf guac-src.tgz
pushd \"guacamole-server-${GUAC_VER}\"
./configure --with-init-dir=/etc/init.d
make -j\"$(nproc)\"
make install
ldconfig
popd

# Configure guacd to chosen port
if grep -q '^#*GUACD_ARGS=' /etc/default/guacd 2>/dev/null; then
  sed -i \"s/^#*GUACD_ARGS=.*/GUACD_ARGS=\\\"-b 127.0.0.1 -l ${PORT_GUACD}\\\"/\" /etc/default/guacd
else
  echo \"GUACD_ARGS=\\\"-b 127.0.0.1 -l ${PORT_GUACD}\\\"\" > /etc/default/guacd
fi
systemctl enable --now guacd

# Webapp
wget -q \"https://downloads.apache.org/guacamole/${GUAC_VER}/binary/guacamole-${GUAC_VER}.war\" -O /var/lib/tomcat10/webapps/guacamole.war
mkdir -p /etc/guacamole /var/lib/guacamole/{extensions,lib}

cat >/etc/guacamole/user-mapping.xml <<'EOF'
<user-mapping>
  <authorize username=\"cbw\" password=\"change_me_now\">
    <connection name=\"Local-SSH\">
      <protocol>ssh</protocol>
      <param name=\"hostname\">127.0.0.1</param>
      <param name=\"port\">22</param>
    </connection>
  </authorize>
</user-mapping>
EOF

cat >/etc/guacamole/guacamole.properties <<EOF
guacd-hostname: 127.0.0.1
guacd-port: ${PORT_GUACD}
user-mapping: /etc/guacamole/user-mapping.xml
EOF

ln -sf /etc/guacamole /usr/share/tomcat10/.guacamole || true

# Bind Tomcat HTTP connector to reserved port
TOMCAT_SERVER_XML=\"/etc/tomcat10/server.xml\"
cp -a \"$TOMCAT_SERVER_XML\" \"${TOMCAT_SERVER_XML}.bak.$(date +%Y%m%d-%H%M%S)\"
sed -i \"s/Connector port=\\\"[0-9]\\+\\\"/Connector port=\\\"${PORT_TOMCAT}\\\"/\" \"$TOMCAT_SERVER_XML\"

systemctl restart tomcat10

echo
echo \"[+] Guacamole installed.\"
echo \"    * guacd: 127.0.0.1:${PORT_GUACD}\"
echo \"    * Tomcat/Guac UI: http://<host>:${PORT_TOMCAT}/guacamole\"
echo \"      (Bind behind Cloudflare Tunnel + Access before exposing)\"
