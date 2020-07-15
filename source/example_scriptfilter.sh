#!/bin/zsh

ADDOMAIN="PAYPALCORP"
EMPLOYEE="JEKNAPP"
RAWDIRECTS=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$EMPLOYEE directReports 2>&1 | grep -v "dsAttrTypeNative:directReports:" | awk '{$1=$1;print;}');
if [[ "$RAWDIRECTS" = "No such key: directReports" ]]; 
    then RAWDIRECTS="null [no reports in AD]"; 
    else DIRECTCOUNT=$(echo $RAWDIRECTS | wc -l)
fi;


DIRECTCNS=$(echo $RAWDIRECTS | sed 's/CN=//' | tr -d '\\' | awk 'BEGIN{FS=",OU=";}  {print $1}');
DIRECTSAMS=$(echo $RAWDIRECTS | sed 's/.*(//' | sed 's/).*//' | tr '\n' ' ';);

function echousercsv SAMACCOUNTNAME {
    SUBJECT=$1
    GIVEN=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$SUBJECT FirstName | awk '{print $NF}';);
    SURNAME=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$SUBJECT LastName | awk '{print $NF}';);
    CN=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$SUBJECT cn | tail -n1 | awk '{$1=$1;print;}');
    EMAIL=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$SUBJECT EMailAddress | awk '{print $NF}';);
    QID=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$SUBJECT extensionAttribute8 | awk '{print $NF}';);
    COSTC=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$SUBJECT msExchExtensionAttribute16 | awk '{print $NF}';);
    JOBTYPE=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$SUBJECT extensionAttribute1 | awk '{print $NF;}');
    TITLE=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$SUBJECT JobTitle | tail -n1 | awk '{$1=$1;print;}');
    RAWMANAGE=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$SUBJECT manager 2>&1 | tail -n1);
    if [[ "$RAWMANAGE" = "No such key: manager" ]]; 
        then 
            # Only happens with the departed
            MANAGER="null - no manager listed in AD";
        else 
            MANAGER=$(echo "$RAWMANAGE" | grep -o '(.*)' | tr -d '()');
    fi

    echo "$GIVEN,$SURNAME,\"$CN\",$EMAIL,$QID,$COSTC,$JOBTYPE,\"$TITLE\",$MANAGER,"
 }

for TARGET in ${(z)DIRECTSAMS};
    do echousercsv($TARGET);
done;


function recursereport SAMACCOUNTNAME {
    SUBJECT=$1
    RAWDIRECTS=$(dscl /Active\ Directory/${ADDOMAIN}/All\ Domains/ -read /Users/$SUBJECT directReports 2>&1 | grep -v "dsAttrTypeNative:directReports:" | awk '{$1=$1;print;}');
    
    if [[ "$SUBJECT" = *"CN="* ]] then
        echo "There has been an error parsing CN - $SUBJECT";
        return 1;
    fi

    if [[ "$SUBJECT" = *"OU="* ]] then
        echo "$SUBJECT - This error ends here";
        return 1;
    fi


    if [[ "$RAWDIRECTS" = *"eDSRecordNotFound"* ]]; then
        echo "subject: $SUBJECT -eDSRecordNotFound";
        return 1;
    fi

    if [[ "$RAWDIRECTS" = "No such key: directReports" ]]; then
        echo $SUBJECT
        return 0;
    fi;

    echo "$SUBJECT, m";
    
    DIRECTSAMS=$(echo $RAWDIRECTS | sed 's/.*(//' | sed 's/).*//' | tr '\n' ' ';);
    for DIRECT in ${(z)DIRECTSAMS}; do
        recursereport "$DIRECT";
    done;
}





COLOR="036AFF"
magik convert orange_gavel.png -fuzz 10% -fill "#$COLOR" +opaque none logot_red6.png

036AFF - blue
F65C00 - orange