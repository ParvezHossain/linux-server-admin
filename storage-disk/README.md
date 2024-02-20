## ncdu (NCurses Disk Usage)

    sudo apt install ncdu
    ncdu --help
    ncdu
    ncdu /path/to/directory #scan directory
    ncdu -rr /path/to/directory #Read-Only Scan
    ncdu -x /path/to/directory  #Restrict to Current Filesystem
    ncdu -o output.txt /path/to/directory
    ncdu -q /path/to/directory  #Start in Quick Mode
    ncdu -f /path/to/directory  #Force Scan Including FIFOs and Sockets



## df (Disk Free)

    df
    df -i   # Display inode usage
    df -h   # human readable format
    df -hT  #include file type
    df -hTx file_type   #exclude specific file type
    df -a   # Display all filesystems
    watch df -hTx tmpfs #Monitor tmpfs file changes

tmpfs is a filesystem in Linux that resides entirely in the computer's memory (RAM) and is used to create a temporary filesystem. It's a volatile filesystem, meaning its contents are not stored on disk but exist in RAM, which gets cleared when the system reboots or when explicitly cleared

To use tmpfs, you typically mount it to a specific directory. For instance, to mount a tmpfs on /tmp, you'd use a command like

    sudo mount -t tmpfs tmpfs /tmp

## du (disk usage)

    du </path/to/directory>
    du -h  # Show disk usage in human-readable format
    du -h --max-depth 1 </path/to/directory>
    du -hs </path/to/directory> # total disk usage 
    du -hs </path/to/directory> </path/to/directory> # total disk usage
    sudo du -hs /etc /home
    du -c  # Display a total at the end of the output
    sudo du -hsc /etc /home
    du -hsc /home/username/*
    du -s  # Show only the total size of each argument
    du -x  # Exclude files from different filesystems
    du -d 1  # Show sizes up to a specified depth (e.g., 1 for current directory only)
