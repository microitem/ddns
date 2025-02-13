#!/bin/bash

# DDNS Client Configuration
API_URL="http://ns1.goodboog.com/api"
USERNAME="ddns_user"
# Replace with your password
PASSWORD="your_password_here"
HOSTNAME="your_hostname"

# Cron configuration (update every 5 minutes):
# */5 * * * * /path/to/ddns-client.sh
