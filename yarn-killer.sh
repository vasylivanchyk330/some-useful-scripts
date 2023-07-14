#!/bin/bash

if [[ -f $HOME/$USER.mapr_ticket ]]
then
  export MAPR_TICKETFILE_LOCATION=$HOME/$USER.mapr_ticket
else
  echo "Could not find $HOME/$USER.mapr_ticket file. Exiting..."
  exit 0
fi

applications=$(yarn application -list -appStates RUNNING | grep $USER | awk -F" " '{print $1}')
echo
echo "Found $(echo $applications | xargs | wc -w) applications for user $USER."

for app in $applications
  do
    app_timestamp=$(yarn application -status $app | grep Start-Time | awk -F" " '{print $3}')
    app_start=${app_timestamp:0:10}
    echo -------------------------
    echo -e "\033[33m$app:\033[0;39m"
    yarn application -status $app
    app_runtime=$(($(date +%s)-$app_start))
    app_runtime_h=$(echo "$app_runtime/3600" | bc)
    app_runtime_m=$(echo "$app_runtime%3600/60" | bc)
    app_runtime_s=$(echo "$app_runtime%3600%60" | bc)
    #echo -e "\033[33mHas been running for $app_runtime_h:$app_runtime_m:$app_runtime_s.\033[0;39m"
    echo
    echo "Started at $(date -d @$app_start)." 
    printf '\033[33mHas been running for %02d:%02d:%02d.\033[0;39m\n\n' $app_runtime_h $app_runtime_m $app_runtime_s
  done
echo
echo "No more applications for $USER."

