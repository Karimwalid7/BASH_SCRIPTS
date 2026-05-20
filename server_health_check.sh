#!/usr/bin/env bash 

# A devOps bash scripting capestone project, check the health of mutiple servers via SSH
#
# Usage: ./server_health_check.sh -f <serever_list_file> -u <remote_user>
#
# --- Part 1: "Strict Mode" ------
# set -e: exit immediately if any command fails 
# set -u: exit if an undefined variable is used
# set -o  pipefail: if any command in a pipeline fails, the whole pipeline is failed

set -euo pipefail 

#---Part 2:"  Cleanup ----" 
# we create a temp log file to record everything 
# mktemp creates log file that won't clash with any exsiting files 

LOG_FILE=$(mktemp /tmp/server_health.XXXX)
readonly LOG_FILE

# log an informational message to screen and log file

log_info(){
	echo "[INFO] $1" | tee -a "$LOG_FILE"
}

#log an error mesasge to stderr and log file 

log_error(){
	echo "[ERROR] $1" | tee -a "$LOG_FILE" >&2
} 
#print script usgae
print_usage(){
	echo " Usage :$0 -  ./server_health_check -f <server_list_file> -u <remote_user>"
	echo " -f : path to the file containing the list of the servers." 
	echo " -u : the remote SSH user to connect as."
	echo " -h: display help message." 
}

# cleanup Funcution 
cleanup(){
	echo "Cleaning up temporary file log:$LOG_FILE"
	rm -f "$LOG_FILE"
}
# trap is the "hook". We tell it:
# "Whenever this script exits for any reason (EXIT),
# or receives INT/TERM signals, call the cleanup function."
trap cleanup EXIT INT TERM
echo "Script started. Log file created at: $LOG_FILE"

checkup_server(){
   local server="$1"
   local user="$2"
   ssh -n -o ConnectTimeout=5 "${user}@${server}" << 'EOF'
# 1. Uptime Check
    echo "--- System Uptime ---"
    uptime
# 2. Disk Check (Root partition)
    echo "--- Disk Usage (Root /) ---"
# NR==2 means print only the second line of df output
     df -h / | awk 'NR==2 {print "Used: " $5 " (" $3 "/" $2 ")"}'
# 3. Memory Check
     echo "--- Memory Usage ---"
     free -m | awk 'NR==2 {
     printf "Used: %sMB / Total: %sMB (%.2f%%)\n", $3, $2, ($3/$2)*100
}'
# 4. Security Check (SSH brute-force failures)
     echo "--- Security (SSH) ---"
     AUTH_LOG="/var/log/auth.log"
     if [[ -f "$AUTH_LOG" ]]; then
        count=$(grep -c "Failed password" "$AUTH_LOG")
        echo "Failed SSH Attempts: $count"
     else
        echo "Failed SSH Attempts: auth log not found."
fi
EOF
log_info "--- Finished Check: $server ---"
}
# Main function: core logic of the script
main() {
  local server_file=""
  local remote_user=""
# --- Argument Parsing (using getopts) ---
  while getopts ":f:u:h" opt; do
    case "$opt" in
      f)
        server_file="$OPTARG"
        ;;
      u)
        remote_user="$OPTARG"
        ;;
      h)
        print_usage
        exit 0
        ;;
      \?) # Invalid flag
        log_error "Invalid option: -$OPTARG"
        print_usage
        exit 1
        ;;
      :) # Missing value for a flag
        log_error "Option -$OPTARG requires an argument."
        print_usage
        exit 1
        ;;
    esac
  done
# --- Input Validation ---
  if [[ -z "$server_file" || -z "$remote_user" ]]; then 
    log_error "Missing required argumets"
    print_usage
    exit 1
  fi 
  if [[ ! -f "$server_file" ]]; then 
   log_error "server file doesn't exist."
   exit 1
  fi 
log_info "Configuration valid, starting health checks..."

# array to hold the list of servers 

declare -a servers=()
# read the servers from the file 
   while IFS= read -r line; do
   if [[ -z "$line" || "$line" == \#* ]]; then 
      continue 
   fi
    servers+=("$line")
  done <"$server_file"
  if [[ ${#servers[@]} -eq 0 ]]; then
    log_error "no servers found in the file"
    exit 1 
  fi
log_info "Found ${#servers[@]} servers to check, checking"

# Loop through the array properly
  for server_host in "${servers[@]}"; do
    checkup_server "$server_host" "$remote_user"
  done
log_info "All checks completed"
}
main "$@"
 
