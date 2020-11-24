#!/bin/bash

query="$(pbpaste)";


if [[ "$query" == *"@"* ]]; then
  query=$(echo "$query" | awk 'BEGIN { FS = "@" } ; {print $1}');
fi

RAWMANAGE=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$query manager 2>&1 | tail -n1);
if [[ "$RAWMANAGE" = "No such key: manager" ]]; 
    then 
        # Only happens with the departed
        RAWMANAGE="null - no manager listed in AD";
        MANAGERCN="null - no manager listed in AD";
        MANAGERSAM="null - no manager listed in AD";
    else 
        MANAGERCN=$(echo "$RAWMANAGE" | awk '{$1=$1;print;}' | sed 's/,OU.*//' | sed 's/CN=//' | tr -d '\\');
        MANAGERSAM=$(echo "$RAWMANAGE" | grep -o '(.*)' | tr -d '()');
        MANAGERTITLE=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$MANAGERSAM JobTitle | tail -n1 | awk '{$1=$1;print;}');
        MANAGERQID=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$MANAGERSAM extensionAttribute8 | awk '{print $NF}');
fi

if [[ "$MANAGERCN" == "dsRecTypeStandard:Users" ]]; then
  echo "User Not Found.";
  exit 1
fi

if [[ "$MANAGERCN" == "valid." ]]; then
  echo "No connection to Active Directory."
  exit 1
fi

echo "$MANAGERCN";




