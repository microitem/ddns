# Nastavenie VPS servera

## Systémové požiadavky
- Ubuntu 20.04 LTS alebo novší
- Minimálne 1GB RAM
- Minimálne 20GB priestoru na disku
- Verejná IP adresa

## Základné nastavenie servera

1. Aktualizácia systému:
sudo apt update
sudo apt upgrade -y

2. Inštalácia základných nástrojov:
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release ufw

3. Nastavenie firewallu:
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
sudo ufw enable

## Nastavenie DNS
1. Konfigurácia A záznamu:
   - Vytvorte A záznam vo vašom DNS registrátorovi
   - Nasmerujte doménu na IP adresu VPS

2. Overenie DNS záznamu:
dig @8.8.8.8 vasa-domena.com

## Bezpečnostné odporúčania
- Používajte SSH kľúče namiesto hesiel
- Pravidelne aktualizujte systém
- Monitorujte systémové logy
- Zálohujte dôležité dáta
