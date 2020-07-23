#!/bin/bash

query="$1"

if [[ "$query" == *"@"* ]]; then
  query=$(echo "$query" | awk 'BEGIN { FS = "@" } ; {print $1}')
fi


CC=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$query msExchExtensionAttribute16 | awk '{print $NF}')

if [[ "$CC" == "dsRecTypeStandard:Users" ]]; then
  echo "User Not Found.";
  exit 1
fi

if [[ "$CC" == "valid." ]]; then
  echo "No connection to Active Directory."
  exit 1
fi

echo "$CC"

#bad user "dsRecTypeStandard:Users"
#from "name: dsRecTypeStandard:Users"
#bad connection: "valid."
# from "Data source (/Active Directory/PAYPALCORP/All Domains/) is not valid."