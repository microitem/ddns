#!/bin/bash

USERNAME="ddns_user"
PASSWORD="8b01a8b7f74caa356406bf75abc88def53e79ebc1979aa8fd82c5cca509549cf"
HOSTNAME="test"
IP="2.2.2.2"

curl -v -u "${USERNAME}:${PASSWORD}" \
     "http://ns1.goodboog.com/ddns/api/?hostname=${HOSTNAME}&ip=${IP}"

echo -e "\n\nOverenie DNS záznamu:"
sleep 2
dig @localhost test.ns1.goodboog.com A
