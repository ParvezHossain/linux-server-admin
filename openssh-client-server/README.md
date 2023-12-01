## Work with openssh-server

Install openssh-server

    sudo apt install openssh-server
    sudo systemctl status ssh
    sudo systemctl start ssh
    sudo systemctl enable ssh

## Work with openssh-client

Install openssh-client

    sudo apt install openssh-client
    sudo systemctl status ssh
    ssh -V
    which ssh

## Connect to the remote server

    ssh username@remote-pc-ip-address
    ssh parvez@192.168.1.10

This will prompt for the remote pc password for that specific user

## Using Server Names for Login Instead of IP Addresses

To enhance security and convenience, map server names to their respective IP addresses in your local configuration. This enables logging into servers without remembering their IP addresses, usernames, or passwords. Ensure that this configuration file's permissions restrict access to the current user for security purposes.

This setup simplifies remote access from your PC to designated servers, enhancing usability while maintaining security by guarding against unauthorized access to sensitive login information.

    cd ~/.ssh
    touch config

see the content to the config file

## Using public / private ssh key

## Break down the .ssh folder contents

#### *known_hosts
The "known_hosts" file in the SSH (Secure Shell) folder is a file used to store host keys for SSH connections. When you connect to a remote server for the first time using SSH, the server's public key is saved in this file. On subsequent connections to the same server, SSH checks the server's key against the one stored in the "known_hosts" file to verify the server's identity.

Each line in the "known_hosts" file typically contains the following information:

The server's IP address or hostname
The type of encryption used
The server's public key
The purpose of this file is to prevent man-in-the-middle attacks. If the server's key changes unexpectedly, SSH will display a warning, indicating a potential security issue. This usually occurs when the server's key changes (e.g., after a server reinstall or if the server is replaced).

If you trust the new key (for instance, if you know that the server has been reinstalled), you can remove the old key from the "known_hosts" file, and on the next connection attempt, SSH will prompt you to save the new key.

It's important to keep this file secure as it contains information about the servers you've connected to. However, it's often fine to delete specific lines related to old or no longer used servers from this file, especially if you know they won't be accessed in the future.