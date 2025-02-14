# Nastavenie VPS servera

## Systémové požiadavky
- Ubuntu 22.04 LTS
- 1GB RAM
- 20GB SSD
- Verejná IPv4 adresa

## Základná konfigurácia

1. Aktualizácia systému:
apt update && apt upgrade -y
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release ufw git

2. Vytvorenie používateľa:
useradd -m -s /bin/bash $SYSTEM_USER
usermod -aG sudo $SYSTEM_USER

3. Adresárová štruktúra:
mkdir -p $BASE_DIR $LOG_DIR $BACKUP_DIR $CONFIG_DIR
chown -R $SYSTEM_USER:$SYSTEM_GROUP $BASE_DIR $LOG_DIR $BACKUP_DIR $CONFIG_DIR

4. Firewall:
ufw default deny incoming
ufw default allow outgoing
ufw allow $PORTS_SSH/tcp
ufw allow $PORTS_DNS_TCP/tcp
ufw allow $PORTS_DNS_UDP/udp
ufw allow $PORTS_HTTP/tcp
ufw allow $PORTS_HTTPS/tcp
ufw enable

5. Základné zabezpečenie:
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

6. Monitoring:
apt install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

7. Časová zóna:
timedatectl set-timezone Europe/Bratislava
apt install -y chrony
systemctl enable chronyd
systemctl start chronyd

## DNS nastavenia
1. Vytvorte A záznamy:
- $EXAMPLE_DOMAIN -> VPS_IP
- $EXAMPLE_NS1 -> VPS_IP
- $EXAMPLE_NS2 -> VPS_IP

2. Overte nastavenia:
dig @8.8.8.8 $EXAMPLE_DOMAIN
dig @8.8.8.8 $EXAMPLE_NS1
dig @8.8.8.8 $EXAMPLE_NS2

## Monitoring
1. Inštalácia základných nástrojov:
apt install -y htop iftop iotop net-tools

2. Logovanie:
touch $LOG_DIR/system.log
chown $SYSTEM_USER:$SYSTEM_GROUP $LOG_DIR/system.log
