#! /bin/zsh
EMPLOYEE="$1"
TEST="funky"

if [[ "$EMPLOYEE" == *"@"* ]]; then
  EMPLOYEE=$(echo "$EMPLOYEE" | awk 'BEGIN { FS = "@" } ; {print $1}')
fi

ADDOMAIN="PAYPALCORP"
# EMPLOYEE=""


# dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE msExchExtensionAttribute16 | awk '{print $NF}';
# dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE SMBPasswordLastSet | awk '{print $NF}';
# dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE extensionAttribute8 | awk '{print $NF}';
# dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE FirstName | awk '{print $NF}';
# dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE LastName | awk '{print $NF}';
# dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE userAccountControl | awk '{print $NF}';
# dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE extensionAttribute4 | awk '{print $NF}';

BULK=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE msExchExtensionAttribute16 SMBPasswordLastSet extensionAttribute8 userAccountControl extensionAttribute4 FirstName LastName extensionAttribute13 physicalDeliveryOfficeName 2>&1)

COSTC=$(echo $BULK | grep 'msExchExtensionAttribute16' | awk '{print $NF}';)
PASSSET=$(echo $BULK | grep 'SMBPasswordLastSet' | awk '{print $NF}';)
QID=$(echo $BULK | grep 'extensionAttribute8' | awk '{print $NF}';)
GIVEN=$(echo $BULK | grep 'FirstName' | awk '{print $NF}';)
SURNAME=$(echo $BULK | grep 'LastName' | awk '{print $NF}';)
UAC=$(echo $BULK | grep "userAccountControl" | awk '{print $NF}';)
EID=$(echo $BULK | grep "extensionAttribute4" | awk '{print $NF}';)
CITY=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE City | tail -n1 | awk '{$1=$1;print;}')
CN=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE cn | tail -n1 | awk '{$1=$1;print;}')
COMMENT=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE Comment 2>&1| tail -n1 | awk '{$1=$1;print;}')
if [[ "$COMMENT" = "No such key: Comment" ]]; then COMMENT="null [no comment in AD]"; fi
HOLD=$(echo $BULK | grep "extensionAttribute13" | awk '{print $NF}';)
if [[ "$HOLD" = "extensionAttribute13" ]]; then HOLD="unheld"; fi
DESK=$(echo $BULK | grep "physicalDeliveryOfficeName" | awk '{print $NF}';)
if [[ "$DESK" = "physicalDeliveryOfficeName" ]]; then DESK="undesked"; fi
RAWDIRECTS=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE directReports 2>&1 | grep -v "dsAttrTypeNative:directReports:" | awk '{$1=$1;print;}')
if [[ "$RAWDIRECTS" = "No such key: directReports" ]]; then RAWDIRECTS="null [no reports in AD]"; fi
RAWMANAGE=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE manager 2>&1 | tail -n1)
if [[ "$RAWMANAGE" = "No such key: manager" ]]; 
    then 
        RAWMANAGE="null - no manager listed in AD";
        MANAGERCN="null - no manager listed in AD";
        MANAGERSAM="null - no manager listed in AD";
    else 
        MANAGERCN=$(echo "$RAWMANAGE" | awk '{$1=$1;print;}' | sed 's/,OU.*//' | sed 's/CN=//' | tr -d '\\');
        MANAGERSAM=$(echo "$RAWMANAGE" | grep -o '(.*)' | tr -d '()');
fi



# echo "
# cost center is $COSTC  
# passet is $PASSSET  
# QID is $QID 
# Given is $GIVEN 
# Surname is $SURNAME  
# UserAccountContro is $UAC 
# EmployeeID is $EID 
# Legal is $HOLD
# Desk is $Desk
# City is $CITY
# Raw Manager is $RAWMANAGE
# Manager CN is $MANAGERCN
# Manager SAM is $MANAGERSAM
# Raw Directs are $RAWDIRECTS
# CN is $CN
# Comment is $COMMENT"

cat << EOB
{"items": [

	{
		"type": "default",
		"title": "$MANAGERCN",
		"subtitle": "Manager CN",
		"arg": "$MANAGERCN",
		"autocomplete": "Manager",
		"mods": {
            "alt": {
                "valid": true,
                "arg": "https://bridge.paypalcorp.com/profile/$MANAGERSAM",
                "subtitle": "Manager Bridge"
            },
            "cmd": {
                "valid": true,
                "arg": "alfredapp.com/shop/",
                "subtitle": "https://www.alfredapp.com/shop/"
            },
        },
        "icon": {
			"path": "smoking-boss.png"
		}
	},

	{
		"valid": false,
		"uid": "flickr",
		"title": "$ADDOMAIN",
		"icon": {
			"path": "flickr.png"
		}
	},

	{
		"uid": "image",
		"type": "file",
		"title": "My holiday photo",
		"subtitle": "~/Pictures/My holiday photo.jpg",
		"autocomplete": "My holiday photo",
		"icon": {
			"type": "filetype",
			"path": "public.jpeg"
		}
	},

	{
		"valid": false,
		"uid": "alfredapp",
		"title": "Alfred Website",
		"subtitle": "https://www.alfredapp.com/",
		"arg": "alfredapp.com",
		"autocomplete": "Alfred Website",
		"quicklookurl": "https://www.alfredapp.com/",
		"mods": {
			"alt": {
				"valid": true,
				"arg": "alfredapp.com/powerpack",
				"subtitle": "https://www.alfredapp.com/powerpack/"
			},
			"cmd": {
				"valid": true,
				"arg": "alfredapp.com/powerpack/buy/",
				"subtitle": "https://www.alfredapp.com/powerpack/buy/"
			},
		},
		"text": {
			"copy": "https://www.alfredapp.com/ (text here to copy)",
			"largetype": "https://www.alfredapp.com/ (text here for large type)"
		}
	}

]}
EOB