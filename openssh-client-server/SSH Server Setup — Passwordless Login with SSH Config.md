````
# SSH Server Setup — Passwordless Login

This guide explains how to configure SSH on Ubuntu so you can connect to your server using:

```bash
ssh server
````

instead of repeatedly typing:

```
ssh java@192.168.0.44
```

It also configures SSH key authentication so you do not need to enter the server password every time.

---

## Server Information

| Setting | Value |
| --- | --- |
| Server IP | `192.168.0.44` |
| Server Username | `java` |
| SSH Alias | `server` |
| Original Command | `ssh java@192.168.0.44` |
| New Command | `ssh server` |

---

# 1\. Create the SSH Directory

On your Ubuntu client machine, open a terminal and run:

```
mkdir -p ~/.ssh
```

Set the correct permissions:

```
chmod 700 ~/.ssh
```

---

# 2\. Configure the SSH Alias

Create or edit the SSH configuration file:

```
nano ~/.ssh/config
```

Add:

```
Host server
    HostName 192.168.0.44
    User java
```

Save the file:

1. Press `Ctrl + O`
2. Press `Enter`
3. Press `Ctrl + X`

Set the correct permissions:

```
chmod 600 ~/.ssh/config
```

---

# 3\. Test the SSH Alias

Run:

```
ssh server
```

This is equivalent to:

```
ssh java@192.168.0.44
```

The first time you connect, SSH may ask:

```
The authenticity of host '192.168.0.44' can't be established.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Type:

```
yes
```

Then enter the `java` user's password.

If you successfully connect, the SSH alias is working.

Exit the server:

```
exit
```

---

# 4\. Check for an Existing SSH Key

Before creating a new key, check whether you already have one:

```
ls -la ~/.ssh/
```

Look for:

```
id_ed25519
id_ed25519.pub
```

If these files exist, you can use the existing key and skip to **Step 6**.

If they do not exist, continue to Step 5.

---

# 5\. Generate an SSH Key

Generate a modern Ed25519 SSH key:

```
ssh-keygen -t ed25519
```

You will see:

```
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/your-user/.ssh/id_ed25519):
```

Press `Enter` to accept the default location.

You will then see:

```
Enter passphrase (empty for no passphrase):
```

You have two choices.

## Option A — No Passphrase

Press `Enter` twice.

This provides maximum convenience.

After setup, you can simply run:

```
ssh server
```

without entering either:

- The server password
- An SSH key passphrase

For a personal computer and trusted home server, this may be acceptable.

## Option B — Use a Passphrase

Enter a strong passphrase.

This is more secure because someone who obtains your private key cannot immediately use it without the passphrase.

You can use `ssh-agent` later so that you do not have to type the passphrase every time.

---

# 6\. Verify the SSH Key

Run:

```
ls -la ~/.ssh/
```

You should see:

```
id_ed25519
id_ed25519.pub
```

These files have different purposes:

```
id_ed25519       → Private key
id_ed25519.pub   → Public key
```

## Important

**Never share your private key:**

```
~/.ssh/id_ed25519
```

The public key:

```
~/.ssh/id_ed25519.pub
```

is the key that will be copied to the server.

---

# 7\. Copy the Public Key to the Server

Because we already configured the `server` alias, run:

```
ssh-copy-id server
```

You will be asked for the `java` user's password.

Enter the password.

You should see something similar to:

```
Number of key(s) added: 1
```

The public key is now installed on the server.

---

# 8\. Test Passwordless Login

Exit the server if you are currently connected:

```
exit
```

Now run:

```
ssh server
```

If you created the SSH key without a passphrase, you should now be logged in without entering the server password.

Your new login command is:

```
ssh server
```

---

# 9\. Set SSH File Permissions

For security, run:

```
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

Verify:

```
ls -la ~/.ssh/
```

You should have permissions similar to:

```
drwx------  ~/.ssh
-rw-------  config
-rw-------  id_ed25519
-rw-r--r--  id_ed25519.pub
```

---

# 10\. Final SSH Configuration

Your SSH configuration file should contain:

```
Host server
    HostName 192.168.0.44
    User java
```

The file is located at:

```
~/.ssh/config
```

Your SSH keys are:

```
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

---

# 11\. Daily Usage

From now on, simply run:

```
ssh server
```

SSH automatically knows:

```
Host:     192.168.0.44
Username: java
```

You no longer need to type:

```
ssh java@192.168.0.44
```

---

# 12\. Optional — Use `login server`

If you specifically want to type:

```
login server
```

instead of:

```
ssh server
```

you can create a shell function.

Edit your Bash configuration:

```
nano ~/.bashrc
```

Add:

```
login() {
    if [ "$1" = "server" ]; then
        ssh server
    else
        echo "Usage: login server"
    fi
}
```

Save the file and reload Bash:

```
source ~/.bashrc
```

Now you can use:

```
login server
```

This internally executes:

```
ssh server
```

---

# 13\. Optional — Use SSH Agent

If you chose to protect your SSH key with a passphrase, use `ssh-agent`.

Start the SSH agent:

```
eval "$(ssh-agent -s)"
```

Add your key:

```
ssh-add ~/.ssh/id_ed25519
```

Enter your SSH key passphrase when prompted.

After that, you can connect using:

```
ssh server
```

without repeatedly entering the key passphrase during that session.

---

# 14\. Troubleshooting

## `ssh-copy-id` is not found

Install the OpenSSH client:

```
sudo apt update
sudo apt install openssh-client
```

Then try:

```
ssh-copy-id server
```

---

## `Permission denied (publickey,password)`

Run SSH in verbose mode:

```
ssh -v server
```

This provides information about the authentication process.

Also check that your key exists:

```
ls -la ~/.ssh/id_ed25519*
```

---

## SSH Still Asks for the Server Password

Run:

```
ssh-copy-id server
```

and make sure you see:

```
Number of key(s) added: 1
```

Then try:

```
ssh server
```

---

## Check the Authorized Keys on the Server

Log in:

```
ssh server
```

Then run on the server:

```
cat ~/.ssh/authorized_keys
```

Your public key should be listed there.

Make sure the server has correct permissions:

```
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

# 15\. Security Recommendations

## Never Share Your Private Key

Never share or upload:

```
~/.ssh/id_ed25519
```

Do not:

- Send it through chat
- Upload it to GitHub
- Email it
- Put it in a public repository
- Give it to another person

Only the public key should be installed on the server:

```
~/.ssh/id_ed25519.pub
```

---

## Use a Passphrase for Important Servers

For production or sensitive servers, use a passphrase when creating the SSH key:

```
ssh-keygen -t ed25519
```

Then use `ssh-agent` to avoid entering the passphrase repeatedly.

---

# 16\. Final Setup

After completing all the steps, your setup should look like this:

```
Ubuntu Client
│
├── ~/.ssh/
│   ├── config
│   ├── id_ed25519
│   └── id_ed25519.pub
│
└── SSH
    │
    └── server
         │
         └── 192.168.0.44
              │
              └── User: java
```

Your SSH configuration:

```
Host server
    HostName 192.168.0.44
    User java
```

Your normal login command:

```
ssh server
```

Or, if you configured the optional Bash function:

```
login server
```

---

# 17\. Expected Result

Before:

```
ssh java@192.168.0.44
```

Then enter your password.

After setup:

```
ssh server
```

No IP address.

No username.

No server password.

Just:

```
ssh server
```

---

# Quick Reference

## Connect

```
ssh server
```

## SSH Configuration

```
~/.ssh/config
```

```
Host server
    HostName 192.168.0.44
    User java
```

## Generate Key

```
ssh-keygen -t ed25519
```

## Copy Key

```
ssh-copy-id server
```

## Fix Permissions

```
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

## Optional Login Command

```
login server
```

---

## End Result

The entire process is designed so that your daily workflow is simply:

```
ssh server
```

with SSH automatically handling the server address, username, and authentication.

```

```