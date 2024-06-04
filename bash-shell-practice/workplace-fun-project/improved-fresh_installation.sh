#!/bin/bash

# Constants
SUCCESS=0
FAILURE=1
ATTEMPTS=2
TIMEOUT=1

# Function to check if the remote host is reachable
check_host_reachable() {
    local ip=$1
    ping -c $ATTEMPTS -W $TIMEOUT $ip &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Error: Host $ip is not reachable."
        exit $FAILURE
    fi
}

# Function to run a command using SSH with Expect
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
    return $?
}

# Function to execute a remote bash script using SSH with Expect
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
    return $?
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
    return $?
}

# Function to check the result of a command and update the overall success flag
check_command_result() {
    local message_success=$1
    local message_failure=$2

    if [ $? -eq 0 ]; then
        echo "$message_success"
        return $SUCCESS
    else
        echo "$message_failure"
        return $FAILURE
    fi
}

# Main function to orchestrate the script execution
main() {
    local destination_ip=$1
    local config_path=$2
    local file_path=$3
    local destination_location_config=$4
    local destination_location=$5
    local password=$6
    local username=$7
    local app_loc=$8
    local is_marker=$9
    local overall_success=$SUCCESS

    # Check if the host is reachable before executing further commands
    check_host_reachable $destination_ip

    # Flush pm2 logs
    run_ssh_command $username $destination_ip "pm2 flush" $password
    check_command_result "Successfully flushed pm2 logs." "Failed to flush pm2 logs."
    overall_success=$((overall_success + $?))

    # Clean db/shots folder
    run_ssh_command $username $destination_ip "cd $destination_location_config && rm -r ../db/shots/* || rm ../db/andino.db" $password
    check_command_result "Successfully removed db/shots folder." "Failed to remove db/shots folder."
    overall_success=$((overall_success + $?))

    # Copy full folder structure
    run_scp_command $username $destination_ip $file_path $destination_location $password
    check_command_result "Successfully copied full folder." "Failed to copy full folder."
    overall_success=$((overall_success + $?))

    # Copy config file
    run_scp_command $username $destination_ip $config_path $destination_location_config $password
    check_command_result "Successfully copied config file." "Failed to copy config file."
    overall_success=$((overall_success + $?))

    # Rename a config file on the remote server
    run_ssh_command $username $destination_ip "cd $destination_location_config && mv *_config.json config.json" $password
    check_command_result "Successfully renamed config file." "Failed to rename config file."
    overall_success=$((overall_success + $?))

    # Install node modules and run the build_device script
    run_ssh_command $username $destination_ip "cd $app_loc && tar -xf node_modules.tar.gz" $password
    check_command_result "Successfully installed node modules." "Failed to install node modules."
    overall_success=$((overall_success + $?))

    # Run build_device script
    run_ssh_command $username $destination_ip "cd $app_loc && npm run build_device" $password
    check_command_result "Successfully ran build_device script." "Failed to run build_device script."
    overall_success=$((overall_success + $?))

    # Execute andino_preparation.sh on the remote server
    remote_script="/home/pi/andino/andino_preparation.sh"
    execute_remote_bash_file $username $destination_ip $password $remote_script
    check_command_result "Successfully ran andino_preparation." "Failed to run andino_preparation."
    overall_success=$((overall_success + $?))

    # Execute specific script for marker recipe if applicable
    if [ $is_marker -eq 1 ]; then
        remote_script="/home/pi/andino/andino_preparation_borris.sh"
        execute_remote_bash_file $username $destination_ip $password $remote_script
        check_command_result "Successfully ran andino_preparation for borris." "Failed to run andino_preparation for borris."
        overall_success=$((overall_success + $?))
    else
        remote_script="/home/pi/andino/delete_marker_process.sh"
        execute_remote_bash_file $username $destination_ip $password $remote_script
        check_command_result "Successfully deleted marker_srv." "Failed to delete marker_srv."
        overall_success=$((overall_success + $?))
    fi

    # Copy a crontab to the remote server's cron.daily
    run_ssh_command $username $destination_ip "cd $app_loc && sudo cp clear_day_counter /etc/cron.daily/" $password
    check_command_result "Successfully copied crontab." "Failed to copy crontab."
    overall_success=$((overall_success + $?))

    # Provide a final success or error message based on the overall success flag
    if [ $overall_success -eq $SUCCESS ]; then
        echo "All commands executed successfully."
        exit $SUCCESS
    else
        echo "One or more commands failed."
        exit $FAILURE
    fi
}

# Get command-line arguments
main "$@"
