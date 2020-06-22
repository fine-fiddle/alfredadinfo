#! /bin/zsh
EMPLOYEE="$1"

if [[ "$EMPLOYEE" == *"@"* ]]; then
  EMPLOYEE=$(echo "$EMPLOYEE" | awk 'BEGIN { FS = "@" } ; {print $1}');
fi


# TODO: thumbnailPhoto, whenCreated, memberOf, accountExpires, fte vs AFW vs hourly,. Groups. only add team section if appropriate. Asset lookup
# Script not executable when downloaded - 


# Gathering multiple predicates in one command reduces time to run script
BULK=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE msExchExtensionAttribute16 SMBPasswordLastSet extensionAttribute8 userAccountControl extensionAttribute4 FirstName LastName extensionAttribute13 physicalDeliveryOfficeName State whenCreated 2>&1);

COSTC=$(echo $BULK | grep 'msExchExtensionAttribute16' | awk '{print $NF}';);
QID=$(echo $BULK | grep 'extensionAttribute8' | awk '{print $NF}';);
GIVEN=$(echo $BULK | grep 'FirstName' | awk '{print $NF}';);
SURNAME=$(echo $BULK | grep 'LastName' | awk '{print $NF}';);
EID=$(echo $BULK | grep "extensionAttribute4" | awk '{print $NF}';);
CITY=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE City | tail -n1 | awk '{$1=$1;print;}');
TITLE=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE JobTitle | tail -n1 | awk '{$1=$1;print;}');
STATE=$(echo $BULK | grep "State" | awk '{print $NF}';);
CN=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE cn | tail -n1 | awk '{$1=$1;print;}');
UAC=$(echo $BULK | grep "userAccountControl" | awk '{print $NF}';);
PASSSETNT=$(echo $BULK | grep 'SMBPasswordLastSet' | awk '{print $NF}';);
PASSSETUNIX="$((($PASSSETNT/10000000)-11644473600))";
PASSEXPIRESUNIX=$(expr $PASSSETUNIX + 7776000);
PASSEXPIRESHUMAN=$(date -j -f "%s" $(expr $PASSSETUNIX + 7776000));
PASSSETHUMAN=$(date -j -f "%s" "$PASSSETUNIX");
UNIXSECONDDIFFERENCE=$(expr $(date "+%s") - $PASSSETUNIX);
PASSWORDDAYDIFFERENCE=$(expr $UNIXSECONDDIFFERENCE / 86400);
PASSWORDDAYSREMAINING=$(expr 90 - $PASSWORDDAYDIFFERENCE);
COMMENT=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE Comment 2>&1| tail -n1 | awk '{$1=$1;print;}');
if [[ "$COMMENT" = "No such key: Comment" ]]; then COMMENT="null [no comment in AD]"; EMPLOYED="1"; fi;
HOLD=$(echo $BULK | grep "extensionAttribute13" | awk '{print $NF}';);
if [[ "$HOLD" = "extensionAttribute13" ]]; then HOLD="null [no legal hold]"; HELD="0" fi;
DESK=$(echo $BULK | grep "physicalDeliveryOfficeName" | awk '{print $NF}';);
if [[ "$DESK" = "physicalDeliveryOfficeName" ]]; then DESK="undesked"; fi;
RAWDIRECTS=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE directReports 2>&1 | grep -v "dsAttrTypeNative:directReports:" | awk '{$1=$1;print;}');
if [[ "$RAWDIRECTS" = "No such key: directReports" ]]; 
    then 
        RAWDIRECTS="null [no reports in AD]";
        ICORMANAGER="IC";
        DIRECTCOUNT="IC";
    else 
        DIRECTCOUNT=$(echo $RAWDIRECTS | wc -l | awk '{$1=$1; print $1;}');
        ICORMANAGER="M";
fi;
RAWMANAGE=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE manager 2>&1 | tail -n1);
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



# echo "
#- cost center is $COSTC  
# passet is $PASSSET  
#- QID is $QID 
# Given is $GIVEN 
# Surname is $SURNAME  
#- UserAccountContro is $UAC 
#- EmployeeID is $EID 
#- City is $CITY
#- State is $STATE
# CN is $CN
#- UAC is $UAC
#- Comment is $COMMENT"
#- Legal is $HOLD
#- Desk is $Desk
# Raw Directs are $RAWDIRECTS
#- Raw Manager is $RAWMANAGE
#- Manager CN is $MANAGERCN
#- Manager SAM is $MANAGERSAM

if [[ "$MANAGERCN" = *"Data source"* ]]; then
    cat << NOADERROR 
    {"items": [{
            "type": "default",
            "uid": "No AD Connection",
            "title": "No Active Directory Connection",
            "subtitle": "Did you set the Alfred Workflow Environment Variable? Are you on the right network?",
            "arg": "Did you set the Alfred Workflow Environment Variable? On the right network?",
            "autocomplete": "x",
            "mods": {
                "alt": {
                    "valid": true,
                    "arg": "$MANAGERCN",
                    "subtitle": "$MANAGERCN"
                },
                "cmd": {
                    "valid": true,
                    "arg": "$MANAGERCN",
                    "subtitle": "$MANAGERCN"
                }
            },

            "icon": {
                "path": "icons/no_server.png"
            },
        }
    ]}
NOADERROR
    exit 1
fi

if [[ "$MANAGERCN" = *"14136"* ]]; then
    cat << NOUSERERROR 
    {"items": [{
            "type": "default",
            "uid": "no-such-account",
            "title": "Failed Lookup",
            "subtitle": "No Such Account",
            "arg": "Failed Lookup: No Such Account",
            "mods": {
                "alt": {
                    "valid": true,
                    "arg": "$MANAGERCN",
                    "subtitle": "$MANAGERCN"
                },
                "cmd": {
                    "valid": true,
                    "arg": "$MANAGERCN",
                    "subtitle": "$MANAGERCN"
                }
            },
            "icon": {
                "path": "icons/what_person.png"
            },
        }
    ]}
NOUSERERROR
    exit 1
fi


cat << EOB
{"items": [

	{
		"type": "default",
   		"uid": "manager",
		"title": "Manager",
		"subtitle": "$MANAGERCN - $MANAGERTITLE",
		"arg": "$MANAGERCN",
		"autocomplete": "Manager",
        "quicklookurl": "https://bridge.paypalcorp.com/profile/$MANAGERSAM",
		"mods": {
            "alt": {
                "valid": true,
                "arg": "https://bridge.paypalcorp.com/profile/$MANAGERSAM",
                "subtitle": "Bridge Link"
            },
            "cmd": {
                "valid": true,
                "arg": "https://myorg.paypalcorp.com/Pages/orgchart.aspx?loginId=$MANAGERSAM&type=ALL",
                "subtitle": "MyOrg Link"
            },
            "ctrl": {
                "valid": true,
                "arg": "https://eagleeye.paypalcorp.com/people/$MANAGERQID",
                "subtitle": "EagleEye Link"
            },
            "shift": {
                "valid": true,
                "arg": "$MANAGERSAM",
                "subtitle": "Manager's SAM"
            }
        },
        "icon": {
			"path": "icons/orange_boss.png"
		}
	},{
        "type": "default",
        "uid": "id-numbers",
        "title": "ID Numbers",
        "subtitle": "Cost Center: $COSTC",
        "arg": "$COSTC",
        "quicklookurl": "https://bridge.paypalcorp.com/profile/$EMPLOYEE",
        "autocomplete": "id",
        "mods": {
            "alt": {
                "valid": true,
                "arg": "$QID",
                "subtitle": "QID: $QID"
            },
            "cmd": {
                "valid": true,
                "arg": "$EID",
                "subtitle": "Employee ID: $EID"
            }
        },
        "icon": {
            "path": "icons/identification_card-orange.png"
        }
    },{
        "type": "default",
        "uid": "legal_status",
        "title": "$HOLD",
        "subtitle": "$COMMENT",
        "arg": "$EMPLOYEE - $HOLD - $COMMENT",
        "quicklookurl": "x",
        "autocomplete": "x",
        "mods": {
            "alt": {
                "valid": true,
                "arg": "$COMMENT",
                "subtitle": "$COMMENT"
            },
            "cmd": {
                "valid": true,
                "arg": "$HOLD",
                "subtitle": "$HOLD"
            }
        },
        "icon": {
            "path": "icons/orange_gavel.png"
        },
    },{
        "type": "default",
        "uid": "who_it_is",
        "title": "$GIVEN $SURNAME - $TITLE - $DIRECTCOUNT",
        "subtitle": "$STATE - $CITY - $DESK",
        "arg": "x",
        "quicklookurl": "x",
        "autocomplete": "x",
        "mods": {
            "alt": {
                "valid": true,
                "arg": "https://bridge.paypalcorp.com/profile/$EMPLOYEE",
                "subtitle": "Bridge Link"
            },
            "cmd": {
                "valid": true,
                "arg": "https://myorg.paypalcorp.com/Pages/orgchart.aspx?loginId=$EMPLOYEE&type=ALL",
                "subtitle": "My Org Link"
            },
            "ctrl": {
                "valid": true,
                "arg": "https://eagleeye.paypalcorp.com/people/$QID",
                "subtitle": "Eagle Eye Link"
            }

        },
        "icon": {
            "path": "icons/orange_employee.png"
        },
    },{
        "type": "default",
        "uid": "acct-status",
        "title": "UAC: $UAC   Pass set $PASSWORDDAYDIFFERENCE days ago.   $PASSWORDDAYSREMAINING days remain.",
        "subtitle": "Updated: $PASSSETHUMAN  -  Expires: $PASSEXPIRESHUMAN" ,
        "arg": "x",
        "quicklookurl": "x",
        "autocomplete": "x",
        "mods": {
            "alt": {
                "valid": true,
                "arg": "",
                "subtitle": ""
            },
            "cmd": {
                "valid": true,
                "arg": "",
                "subtitle": ""
            }
        },
        "icon": {
            "path": "icons/orange_status_check.png"
        },
    },{
        "type": "default",
        "uid": "team",
        "title": "Team List Generator",
        "subtitle": "Generate Direct Report List - $DIRECTCOUNT people",
        "arg": "",
        "autocomplete": "directs",
        "mods": {
            "alt": {
                "valid": true,
                "arg": "how do i make this efficient lol",
                "subtitle": "Recursive Reports"
            },
            "cmd": {
                "valid": true,
                "arg": "",
                "subtitle": ""
            }
        },
        "icon": {
            "path": "icons/orange_team.png"
        },
        "text": {
            "copy": "https://www.alfredapp.com/ (text here to copy)",
            "largetype": "https://www.alfredapp.com/ (text here for large type)"
        }
    },{
        "type": "default/file",
        "uid": "x",
        "title": "x",
        "subtitle": "x",
        "arg": "x",
        "quicklookurl": "x",
        "autocomplete": "x",
        "mods": {
            "alt": {
                "valid": true,
                "arg": "",
                "subtitle": ""
            },
            "cmd": {
                "valid": true,
                "arg": "",
                "subtitle": ""
            },
            "ctrl": {
                "valid": true,
                "arg": "",
                "subtitle": ""
            }
        },
        "icon": {
            "type": "filetype",
            "path": "x.png"
        },
        "text": {
            "copy": "https://www.alfredapp.com/ (text here to copy)",
            "largetype": "https://www.alfredapp.com/ (text here for large type)"
        }
    },

]}
EOB

	# {
	# 	"type": "default/file",
	# 	"uid": "x",
	# 	"title": "x",
    #     "subtitle": "x",
    #     "quicklookurl": "x",
    #     "arg": "x",
	# 	"autocomplete": "x",
	# 	"mods": {
    #         "alt": {
    #             "valid": true,
    #             "arg": "",
    #             "subtitle": ""
    #         },
    #         "cmd": {
    #             "valid": true,
    #             "arg": "",
    #             "subtitle": ""
    #         }
    #     },
    #     "icon": {
    #         "type": "filetype",
	# 		"path": "x.png"
	# 	},
    #     "text": {
	# 		"copy": "https://www.alfredapp.com/ (text here to copy)",
	# 		"largetype": "https://www.alfredapp.com/ (text here for large type)"
	# 	}
	# }
