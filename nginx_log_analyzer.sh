#!/bin/bash

# Safe Mode

set -euo pipefail
#------------------------------------------------------------

#defining log file to check

LOG_FILE="/var/log/nginx/access.log"


# We check if the file exists to avoid crashes.

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Could not find the log file at $LOG_FILE"
    echo "Please check if Nginx is installed or if you have the correct path."
    exit 1
fi

# We also check if we have permission to read the file.
if [ ! -r "$LOG_FILE" ]; then
    echo "Error: Permission denied. Try running with 'sudo'."
    exit 1
fi

# --- THE REPORT HEADER ---

echo "========================================"
echo "    NGINX LOG SUMMARY REPORT"
echo "    Target: $LOG_FILE"
echo "    Time: $(date +" %Y-%m-%d %H:%M:%S")"
echo "========================================"

# --- 4. DATA PROCESSING ---

# Get total lines (requests) using wc -l
TOTAL_REQUESTS=$(wc -l < "$LOG_FILE")
echo "Total Requests Processed: $TOTAL_REQUESTS"
echo "----------------------------------------"

# Analyze Status Codes
echo "HTTP Status Code Frequency:"
printf "%-10s %-10s %-10s\n" "Status" "Count" "Percentage"

# awk '{print $9}': Pulls the status code (column 9)
# sort | uniq -c: Groups and counts occurrences
# sort -rn: Sorts highest count to the top
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -rn | while read -r count status; do
    
    # Calculate percentage using 'bc' for floating point math
    percent=$(echo "scale=2; ($count / $TOTAL_REQUESTS) * 100" | bc)
    
    # Format the table row
    printf "[%-6s] %-10s %-10s%%\n" "$status" "$count" "$percent"
done

echo "----------------------------------------"

# Target 404s Specifically
echo "Top 5 '404 Not Found' Paths:"

# Filter for 404s and count them
found_404s=$(awk '$9 == "404" {print $7}' "$LOG_FILE" | wc -l)

if [ "$found_404s" -gt 0 ]; then
    # Grab the top 5 offending URLs
    awk '$9 == "404" {print $7}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -5 | while read -r count path; do
        printf "  - %-30s (%s times)\n" "$path" "$count"
    done
else
    echo "  Success! No 404 errors found in this log."
fi

echo "========================================"
