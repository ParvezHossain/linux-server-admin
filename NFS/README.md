### NFS

    sudo apt install nfs-kernel-server
    sudo systemctl status nfs-kernel-server
    sudo mv /etc/exports /etc/exports/orig
    sudo nano /etc/exports 