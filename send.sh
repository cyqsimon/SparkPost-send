#!/usr/bin/env bash

# Sends an email using SparkPost Rest API
# See https://www.sparkpost.com/docs/getting-started/getting-started-sparkpost/#rest-api

# Usage:
# 1st arg: email subject
# 2nd arg: email recipients, separated by spaces
# stdin: email message body
# E.g. echo "This email says hello." | ./send.sh "Greetings!" "alice@foo.com bob@bar.net"

# Config
USE_EU=false
API_KEY="CHANGEME"
FROM="CHANGEME"
# End Config

if [ "$USE_EU" = true ]; then
  API_PATH="https://api.eu.sparkpost.com/api/v1/transmissions"
else
  API_PATH="https://api.sparkpost.com/api/v1/transmissions"
fi
SUBJ="$1"
RECIPS=($2)
MSG=$(cat -) # stdin

# guard clauses
if [ "$SUBJ" = "" ]; then
  echo "Subject cannot be empty!"
  exit 1
fi
if [ "${#RECIPS[@]}" -eq 0 ]; then
  echo "No recipients specified!"
  exit 1
fi
if [ "$MSG" = "" ]; then
  echo "Warning. Sending empty message!"
fi
if [ "${#MSG}" -gt 10000000 ]; then
  echo "Cannot send message more than 10MB!"
  exit 1
fi

# escape recipients
for i in ${!RECIPS[@]}; do
  RECIPS[$i]=$(echo "${RECIPS[$i]}" | jq -Rc '.')
done
RECIPS_JSON=$(echo "${RECIPS[@]}" | jq -c '{address: .}' | jq -sc '.')

# compose final POST data
POST_DATA=$(echo "$RECIPS_JSON" | jq -c \
  --arg from "$FROM" \
  --arg subj "$SUBJ" \
  --arg msg "$MSG" \
  '{content: {from: $from, subject: $subj, text: $msg}, recipients: .}')

# send mail request via API
curl "$API_PATH" \
  -s \
  -H "Authorization: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$POST_DATA" | jq '.'
