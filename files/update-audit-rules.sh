#!/bin/bash

########################################################################################################
# Title             : update-audit-rules.sh
# Author            : Ahmed Elkholy [ahmedelkholy89@gmail.com]
# Version			: V1.0.0
# Date of creation  : 2026-03-03
# Purpose           : Update the audit rules for auditing users’ commands
########################################################################################################

#--------------------------------- Set bash behavior ---------------------------------#
# e: Exit immediately if any command returns a non-zero exit status
# E: This enables the ERR trap to be inherited by functions, command substitutions, and subshells in Bash.
set -eE

#--------------------------------- Functions ---------------------------------#
function usage
{
	cat <<-EOF
		Update the audit rules to audit users’ commands.

		Usage: $SCRIPT_NAME [options]

		Options:
		  -h, --help	display this help message and exits
	EOF
}

function logging
{
	local LOG_FILE LOG_USER LOG_DATETIME LOG_TYPE LOG_MESSAGE

	# Log file
	LOG_FILE='/var/log/update-audit-rules.log'

	# Get log user
	LOG_USER="$SUDO_USER"
	[ -z "$LOG_USER" ] && LOG_USER="$USER"

	# Set log datetime
	LOG_DATETIME="$(date +"%F %X")"

	# Log type
	LOG_TYPE="$1"

	# Log message
	LOG_MESSAGE="$2"

	echo "[$LOG_DATETIME][$LOG_USER][$LOG_TYPE] $LOG_MESSAGE" | tee -a "$LOG_FILE"

}

function runtime_error
{
	logging "ERROR" "Error in function ${FUNCNAME[1]} on line ${BASH_LINENO[0]} with this command: $BASH_COMMAND"
}


#--------------------------------- Main ---------------------------------#
# Define the scrip base name
SCRIPT_NAME="$(basename "$0")"

# Need to help
[ $# -eq 1 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} && usage && exit 0

# Check args
[ $# -ne 0 ] && echo "Invalid syntax" && exit 1

# Check the root user
[ $UID -ne 0 ] && echo -e "Permission denied" && exit 1

#Start the logs
logging 'INFO' 'Running the script…'

# Register ERR signal
trap runtime_error ERR

# Get the users with id >= 1000 except nobody user
logging 'INFO' 'Getting all normal accounts…'
mapfile -t NORMAL_USERS < <(getent passwd | awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}')

# Get the curret
AUDIT_RULES_FILE="/etc/audit/rules.d/users_commands.rules"
need_reload=0	# It will be used to check whether it should reload the rules
for normal_user in "${NORMAL_USERS[@]}"
do
	# Filter the disabled accounts
	is_active="$(getent shadow "$normal_user" | cut -d: -f8)"
	[ -n "$is_active" ] && continue

	# Check the existed rule for the user
	if grep -q "$normal_user" "$AUDIT_RULES_FILE"
	then
		continue
	fi
	
	# Add the rule
	user_id="$(id -u "$normal_user")"
	echo "-a always,exit -F arch=b64 -S execve -F uid=$user_id -k $normal_user-commands" >> "$AUDIT_RULES_FILE"
	
	# We need reload the rules
	need_reload=1	# It will be used to check whether it should reload the rules

	logging 'INFO' "[$normal_user] Added" 
done

# Reload the rules
[ $need_reload -eq 1 ] && logging 'INFO' 'Reloading the audit rules…' && augenrules --load
[ $need_reload -eq 0 ] && logging 'INFO' 'No updates'

logging 'INFO' 'Done! :)'
exit 0
