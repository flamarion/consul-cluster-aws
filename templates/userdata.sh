#!/bin/bash

echo "Installing dependencies ..."
apt-get update
apt-get install -y unzip curl jq wget dnsutils

echo "Creating consul user"
useradd --system --home /etc/consul.d --shell /bin/false consul

echo "Creating directory structure for Consul"
mkdir -p /etc/consul.d
mkdir -p /etc/consul.d/certs
mkdir -p /opt/consul


echo "Fetching Consul version $CONSUL_VERSION ..."
wget https://releases.hashicorp.com/consul/1.9.6/consul_1.9.6_linux_amd64.zip
unzip -d /bin consul_1.9.6_linux_amd64.zip
consul version

# echo "Creating TLS certs fo DC1"
# cd /etc/consul.d/certs
# consul tls ca create
# consul tls cert create -server -dc dc1
# consul tls cert create -client -dc dc1

echo "Creating the Consul config file"

cat > /etc/consul.d/server.json <<EOF
{
  "datacenter": "dc1",  
  "server": true,
  "ui_config": {
    "enabled": true
  },
  "data_dir": "/opt/consul",
  "retry_join": ["provider=aws tag_key=Role tag_value=Consul_Server"],
  "encrypt": "YPXR+ci3gyAlm3Cp3XrxdmVio7ZpUBy478NzvtlYZ7g=",
  "ca_file": "/etc/consul.d/certs/consul-agent-ca.pem",
  "cert_file": "/etc/consul.d/certs/dc1-server-consul-0.pem",
  "key_file": "/etc/consul.d/certs/dc1-server-consul-0-key.pem",
  "verify_incoming": true,
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "addresses": {
    "http": "0.0.0.0"
  },
  "performance": {
    "raft_multiplier": 1
  },
  "client_addr": "0.0.0.0",
  "bootstrap_expect": 3,
  "enable_syslog": true
}
EOF

echo "Creating Systemd Unit"
cat > /usr/lib/systemd/system/consul.service <<EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target

[Service]
Type=notify
User=consul
Group=consul
ExecStart=/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF


# Final act 
chown -R consul:consul /etc/consul.d /opt/consul
systemctl daemon-reload
systemctl start consul