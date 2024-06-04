#!/bin/bash

# Function to check if the remote host is reachable
check_host_reachable() {
    local ip=$1
    local attempts=2  # Number of ping attempts
    local timeout=1   # Timeout in seconds per ping attempt

    ping -c $attempts -W $timeout $ip &> /dev/null
    if [ $? -ne 0 ]; then
        echo 2
        exit 1
    fi
}


# Function to run an SSH command with Expect
run_ssh_command() {
    local user=$1
    local ip=$2
    local command=$3
    local password=$4

    expect <<END
        log_user 0
        set timeout -1
        spawn ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$ip "$command"
        expect {
            "password" {
                send "$password\r"
                exp_continue
            }
            eof {
                catch wait result
                set exit_status [lindex \$result 3]
                exit \$exit_status
            }
        }
END
    return $?  # Return the exit status of the Expect block
}

execute_remote_bash_file() {
    local user=$1
    local ip=$2
    local password=$3
    local remote_script=$4

    expect <<END
        log_user 0
        set timeout -1
        spawn ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$ip "bash $remote_script"
        expect {
            "password" {
                send "$password\r"
                exp_continue
            }
            eof {
                catch wait result
                set exit_status [lindex \$result 3]
                exit \$exit_status
            }
        }
END
    return $?  # Return the exit status of the Expect block
}

# Function to run an SCP command with Expect
run_scp_command() {
    local user=$1
    local ip=$2
    local source=$3
    local destination=$4
    local password=$5

    expect <<END
        log_user 0
        set timeout -1
        spawn scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $source $user@$ip:$destination
        
        expect {
            "password" {
                send "$password\r"
                exp_continue
            }
            eof {
                catch wait result
                set exit_status [lindex \$result 3]
                exit \$exit_status
            }
        }
END
    return $?  # Return the exit status of the Expect block
}

# Function to check the result of the SSH command
check_ssh_result() {
    local message_success=$1
    local message_failure=$2

    if [ $? -eq 0 ]; then
        # echo $message_success
        return 0
    else
        # echo $message_failure
        return 1
    fi
}

# Get command-line arguments
destination_ip=$1
config_path=$2
filePath=$3
destination_location_config=$4
destination_location=$5
password=$6
username=$7
app_loc=$8
is_marker=$9

# Check if the host is reachable before executing further commands
check_host_reachable $destination_ip

# Initialize a flag to track overall success
overall_success=0

# Flush pm2 logs
run_ssh_command $username $destination_ip "pm2 flush" $password
check_ssh_result "Successfully flushed pm2 logs." "Failed to flush pm2 logs."
overall_success=$(($overall_success + $?))

# Clean db/shots folder
run_ssh_command $username $destination_ip "cd $destination_location_config && rm -r ../db/shots/* || rm ../db/andino.db" $password
check_ssh_result "Successfully removed db/shots folder." "Failed to remove db/shots folder."
overall_success=$(($overall_success + $?))

# To copy full folder structure
run_scp_command $username $destination_ip $filePath $destination_location $password
check_ssh_result "Successfully copied full folder." "Failed to copied full folder."
overall_success=$(($overall_success + $?))

# To copy config file
run_scp_command $username $destination_ip $config_path $destination_location_config $password
check_ssh_result "Successfully copied config file." "Failed to copied config file."
overall_success=$(($overall_success + $?))

# Rename a config file on the remote server
run_ssh_command $username $destination_ip "cd $destination_location_config && mv *_config.json config.json" $password
check_ssh_result "Successfully rename config file." "Failed to rename config file."
overall_success=$(($overall_success + $?))

# Install node modules and run the build_device script
run_ssh_command $username $destination_ip "cd $app_loc && tar -xf node_modules.tar.gz" $password
check_ssh_result "Successfully installed node modules and build_device script" "Failed to installed node modules and build_device script"
overall_success=$(($overall_success + $?))

# To run build_device script
run_ssh_command $username $destination_ip "cd $app_loc && npm run build_device" $password
check_ssh_result "Successfully runs build_device script" "Failed to run build_device script"
overall_success=$(($overall_success + $?))

# Execute andino_preparation.sh on the remote server || For this copy the andino_preparation.sh file into andino bitbucket root directory folder
remote_script="/home/pi/andino/andino_preparation.sh"
execute_remote_bash_file $username $destination_ip $password $remote_script
check_ssh_result "Successfully runs andino_preparation" "Failed to run andino_preparation"
overall_success=$(($overall_success + $?))

# Execute this if the machine is marker recipe: Only for Bohai Trimet
if [ $is_marker -eq 1 ]; then
    remote_script="/home/pi/andino/andino_preparation_borris.sh"
    execute_remote_bash_file $username $destination_ip $password $remote_script
    check_ssh_result "Successfully ran andino_preparation for borris" "Failed to run for borris"
    overall_success=$(($overall_success + $?))
fi

# Delete Marker srv if it was a marker previously, but not anymore
if [ $is_marker -ne 1 ]; then
    remote_script="/home/pi/andino/delete_marker_process.sh"
    execute_remote_bash_file $username $destination_ip $password $remote_script
    check_ssh_result "Successfully delete marker_srv" "Failed to delete marker_srv"
    overall_success=$(($overall_success + $?))
fi

overall_success=$(($overall_success + $?))

# Copy a crontab to the remote server's cron.daily
run_ssh_command $username $destination_ip "cd $app_loc && sudo cp clear_day_counter /etc/cron.daily/" $password
check_ssh_result "Successfully copied crontab" "Failed to copy crontab"
overall_success=$(($overall_success + $?))

# Provide a final success or error message based on the overall success flag
if [ $overall_success -eq 0 ]; then
    # For success message
    # echo "All commands executed successfully."
    echo 1
else
    # echo "One or more commands failed."
    # For failure message
    echo 0
fi



