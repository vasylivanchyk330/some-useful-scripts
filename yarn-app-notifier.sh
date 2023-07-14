#!/bin/bash

# Check if the correct number of arguments were provided
if [ $# -lt 2 ]; then
  echo "Error: Not all obligatory arguments were provided."
  echo "Usage: xx.sh <email> <hours> [user]"
  echo "  email: Recipient of the report."
  echo "  hours: Time in hours an application has to be running for to be included in the report."
  echo "  user: (Optional) User whose applications to check. Default is the current user."
  exit 1
fi

# Assign the arguments to variables for easier reference
recipient=$1
N_of_Hs=$2
user=${3:-$(whoami)}  # Default to the output of `whoami` command if user is not provided

# Initialize a counter for applications running for more than N hours
app_over_NofH_count=0
# list of all applications for current user 
applications=$(yarn application -list -appStates RUNNING | grep $user | awk -F" " '{print $1}')
# Initialize the variable
app_num_msg="THERE IS NO APP FOR $user THAT RUNS MORE THAN $N_of_Hs HOURS. We are fine. "

# Check if the mapr ticket exists
if [[ -f $HOME/$user.mapr_ticket ]]
then
  export MAPR_TICKETFILE_LOCATION=$HOME/$user.mapr_ticket
else
  echo "Could not find $HOME/$user.mapr_ticket file. Exiting..."
  exit 0
fi

get_property() {
    property=$1
    echo "$app_status" | grep "$property"
}

# Open a subshell
{
echo "ZOBACZ CO MAMY. AUTOMATYCZNY REPORT Z APLIKACJAMI KTORE BIEGAJA WIECEJ X GODZIN"
echo "================================================================"

for app in $applications
do
  app_timestamp=$(yarn application -status $app | grep Start-Time | awk -F" " '{print $3}')
  app_start=${app_timestamp:0:10}
  app_runtime=$(($(date +%s)-$app_start))
  app_runtime_h=$(echo "$app_runtime/3600" | bc)

  # If app runtime is greater than N hours
  if (( $app_runtime_h >= $N_of_Hs ))
  then
    ((app_over_NofH_count++))  # Increment the counter
    app_num_msg="FOUND $app_over_NofH_count APPLICATION(S) THAT RUN MORE THAN ${N_of_Hs}H."
    
    app_status=$(yarn application -status $app)

    echo "-----------------------------------------------------------------------------------"
    echo $(get_property "Application-Id")
    echo $(get_property "Application-Name")
    echo $(get_property "Application-Type")
    echo $(get_property "User")
    echo $(get_property "Queue")
    echo $(get_property "Start-Time")
    echo $(get_property "Finish-Time")
    echo $(get_property "Progress")
    echo $(get_property "State")
    echo $(get_property "Aggregate Resource Allocation")
  fi
done

# Print the message at the beginning of the report
echo $app_num_msg

# Close the subshell and pipe its output to the mail command
} | mail -s "ZOBACZ: Auto Application Status Report" "$recipient"
