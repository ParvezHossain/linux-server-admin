### 🔧 Step 1: Update your system

    sudo apt update && sudo apt upgrade -y

### 📦 Step 2: Install IBus (if not already installed)

    sudo apt install ibus ibus-gtk ibus-gtk3 ibus-clutter -y

### 📥 Step 3: Install IBus Avro

Ubuntu’s official repo may not always have the latest Avro, so use PPA:

        sudo add-apt-repository ppa:ibus-avro/stable
        sudo apt update
        sudo apt install ibus-avro -y

### 🔄 Step 4: Restart IBus

    ibus restart

Or log out and log back in (safer).

### ⚙️ Step 5: Add Avro keyboard
1. Open Settings

2. Go to Keyboard → Input Sources

3. Click +

4. Search for Bangla (Avro Phonetic)

5. Add it

### ⌨️ Step 6: Switch input
* Use: Super (Windows key) + Space or Ctrl + Space

### 🧪 Optional: Verify installation

    ibus list-engine | grep avro

### ⚠️ Common issues (Ubuntu 25)

* If Avro doesn’t appear:

        ibus-setup
### Then manually add Avro Phonetic

* If still not working:

        sudo apt install ibus-m17n

### 💡 Pro tip

If you're using Wayland (default in newer Ubuntu) and facing issues:

        export GTK_IM_MODULE=ibus
        export QT_IM_MODULE=ibus
        export XMODIFIERS=@im=ibus

Add these to ~/.profile and reboot.