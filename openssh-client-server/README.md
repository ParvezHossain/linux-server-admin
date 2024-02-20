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

Go to the ssh folder

    cd ~/.ssh

you might need to create the .ssh folder if it does not exist

    mkdir ~/.ssh

To enhance security and convenience, map server names to their respective IP addresses in your local configuration. This enables logging into servers without remembering their IP addresses, usernames, or passwords. Ensure that this configuration file's permissions restrict access to the current user for security purposes.

This setup simplifies remote access from your PC to designated servers, enhancing usability while maintaining security by guarding against unauthorized access to sensitive login information.

    touch config

see the contents to the config file

## Generating SSH Keys Safely in your server (private / public key)

Check Existing Keys: Ensure that the /home/username/.ssh/id_rsa file is empty before generating new keys. Overwriting existing keys might lead to access issues with remote servers.

    ls -l ~/.ssh/id_rsa

Generate SSH Keys: If the file is empty or doesn't exist, proceed with key generation:

    ssh-keygen -t rsa -b 4096
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys

Follow Prompts: Follow the prompts to specify a filename (if needed) and passphrase. Be cautious while choosing the filename to avoid overwriting existing keys unintentionally.

Check Generated Keys: After generation, confirm that the new keys are created and accessible:

    ls -l ~/.ssh/id_rsa*

Use Caution: Take care not to overwrite existing keys inadvertently, as this may prevent access to remote servers. Back up existing keys if necessary.

#### Logging to the remote server without password

copy the content of id_rsa.pub file to those client server where from you want to connect to. Make a directory to the remote server.

    ssh username@192.168.1.10
    cd ~/.ssh
    sudo mkdir authorized_keys

copy the id_rsa.pub content to the the authorized_keys

ssh -v username@192.168.1.10

## Disable password authentication

    sudo rm id_rsa*
    ssh-keygen -t rsa -b 4096

copy the id_rsa.pub content to the remote server /home/username/.ssh/authorized_keys file

## Copy the ssh key to the remote server

    ssh-copy-id -i ~/.ssh/id_rsa.pub root@192.168.1.10

here, -i for input file

## Managing Multiple SSH Keys for Different Servers

To differentiate between encryption algorithms and easily identify keys for multiple servers:

Selecting Encryption Algorithm: Choose a specific encryption algorithm using ssh-keygen. For instance, use ed25519 for a specific client:

    ssh-keygen -t ed25519 -C "Autoheinen_14_6"

Customized Key Saving Location: To help remember the algorithm and client, adjust the key saving location:

    /home/username/.ssh/Autoheinen_14_6_id_ed25519

Then copy the content of the Autoheinen_14_6_id_ed25519.pub to the remote server authorized_keys file

    ssh-copy-id -i ~/.ssh/Autoheinen_14_6_id_ed25519.pub username@192.168.1.10
    ssh -i ~/.ssh/Autoheinen_14_6_id_ed25519.pub username@192.168.1.10

## SSH-Agent

check ssh-agent is running or not

    ps aux | grep ssh-agent

start ssh-agent

    eval "$(ssh-agent)"

Cache the ssh private key to the ssh-agent

    ssh-add ~/.ssh/Autoheinen_14_6_id_ed25519
    ssh-add ~/.ssh/you_private_key

## Configuring OpenSSH (OpenSSH Server) server component

    which sshd
    sudo systemctl status sshd
    sudo systemctl restart sshd
    systemctl stop sshd (be careful if you don't directly access to the server physically)
    sudo systemctl enable sshd

    cd /etc/ssh

Read / modify the file cat /etc/ssh/sshd_config

    Port 22 => 2222
    PermitRootLogin yes => no
    MaxAuthTries 6 => 2
    MaxSessions 10 > 2
    PasswordAuthentication yes => no
    ClientAliveInterval
    ClientAliveCountMax

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