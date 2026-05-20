#!/bin/bash

#-----------------------------------------------------------
#this is a script aimed to be run by a cron job 
#it checks the main usages of system resoureces
#checks if the main services are down and attempts to restart 
#logs it into a file 
#Send Alerts 
#--------------------------------------------------------------

#----Apply Strict Mode------
# set -e: exit immediately if any command fails
# set -u: exit if an undefined variable is used
# set -o  pipefail: if any command in a pipeline fails, the whole pipeline is failed
 
set -euo pipefail

# Make sure the file is ran using SUDO
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (or with sudo)"
   exit 1
fi

echo "######################## Script Started #######################"
# Main Configuration for the resources thresholds in percentages 

CPU_THRESHOLD=80
DISK_THRESHOLD=90
MEM_THRESHOLD=85

# Define our most important services 

main_services=("sshd" "nginx" "ufw" "systemd-journald")

# Create a log file to log with time stamps 

today=$(date +"%Y-%m-%d")

LOG_FILE="/var/log/system_check-$today.log"

# check if file exists and permession 
{ : > "$LOG_FILE"; } 2>/dev/null

# $?: This is a special Bash variable that stores the Exit Status
if [ $? -ne 0 ]; then
    echo "Error: Cannot create log file at $LOG_FILE. Please run with 'sudo'."
    exit 1
else 
    echo "Log file Created at [$LOG_FILE]"
fi

#log info message to screen and log file 
log_info(){
        echo "[INFO] $1 $(date '+%H:%M:%S')" | tee -a "$LOG_FILE"
}

#log an error mesasge to stderr and log file
log_error(){
        echo "[ALERT] $1 $(date '+%H:%M:%S')" | tee -a "$LOG_FILE" >&2
}

#check cpu usage 
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print int(100 - $8)}')
if [ "$CPU_USAGE" -gt "$CPU_THRESHOLD" ]; then
    log_error "High CPU Usage detected at ${CPU_USAGE}%"
else
    log_info "CPU Usage: ${CPU_USAGE}% (Normal)"
fi

#Disk usage check (Primary partition) 
DISK_USAGE=$(df / | awk 'NR==2 {print int($5)}')
if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    log_error "Disk Space Low on / at ${DISK_USAGE}%"
else
    log_info "Disk Usage: ${DISK_USAGE}% (Normal)"
fi

#Check Memory usagea and health 
MEM_USAGE=$( free -m | awk 'NR==2 {
     print int(($3/$2)*100)
}')
if [ "$MEM_USAGE" -gt  "$MEM_THRESHOLD" ]; then
    log_error "High Memory Usage detected at ${MEM_USAGE}%"
else
    log_info "Memory Usage: ${MEM_USAGE}% (Normal)"
fi
 
echo "#######################################"
echo "Checking Services"
echo "#######################################"

#Loop over array of services

for service in "${main_services[@]}"; do

  if systemctl is-active --quiet "$service"; then
    log_info "Service $service is Running" 
else 
    log_error "Service $service is Down - ATTEMPTING RESTART" 

if systemctl restart "service" 2>/dev/null; then
  log_info "Service $service was down and was restarted successfully" 
else 
  log_error "Failed to restart $service, Needs Manual Intervention"
  fi
fi
done 

echo " ################### CHECK DONE #####################"


