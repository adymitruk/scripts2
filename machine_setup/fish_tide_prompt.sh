 #!/bin/bash
 
 function check_if_installed {
     # Check if tide is installed
     if ! fish -c "type -q tide"
     then
         echo "tide could not be found"
         return 1
     fi
 
     return 0
 }
 
 if [ "$1" == "check" ]; then
     check_if_installed
     exit $?
 fi
 
 # Install tide prompt through fisher
 fish -c "fisher install IlanCosman/tide"

 fish -c "tide configure"




