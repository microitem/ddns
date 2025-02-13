#!/bin/bash

# Konfigurácia
API_URL="http://84.247.160.146/api"
USERNAME="ddns_user"
PASSWORD="8b01a8b7f74caa356406bf75abc88def53e79ebc1979aa8fd82c5cca509549cf"
HOSTNAME="test"

# Získanie verejnej IP adresy
IP=$(curl -s https://api.ipify.org)

# Aktualizácia DNS záznamu
curl -s -u "$USERNAME:$PASSWORD" "$API_URL/?hostname=$HOSTNAME&ip=$IP"
