### How to Install PyCharm on Ubuntu: A Step-by-Step Guide
PyCharm is one of the most powerful Integrated Development Environments (IDEs) for Python. While Ubuntu offers several ways to install software, manual installation via the .tar.gz archive provides the most control over your environment.

This guide covers the entire process: downloading, installing, and creating a permanent desktop shortcut.

1. ### Prerequisites
   Before beginning, ensure your system is up to date:
`sudo apt update && sudo apt upgrade -y`   

2. ### Download and Extraction

    1. Visit the official JetBrains website and download the Community or Professional `.tar.gz package`.
    2. Open your terminal and navigate to your Downloads folder: `cd ~/Downloads`
    3. Extract the archive to the /opt directory (a standard location for manual software installations): `sudo tar -xzf pycharm-*.tar.gz -C /opt`
    4. Rename the extracted folder for easier navigation (replace pycharm-version with your actual folder name): `sudo mv /opt/pycharm-community-202X.X /opt/pycharm`

3. ### Initial Launch

   To ensure everything is working correctly, launch PyCharm directly from the terminal
`sh /opt/pycharm/bin/pycharm.sh`


4. ### Creating a Desktop Shortcut
   By default, manual installations do not appear in your Application Menu. We can fix this by creating a .desktop entry.

    1. #### Create the Entry File
        `sudo nano /usr/share/applications/pycharm.desktop`
   2. #### Step 2: Add Configuration
      Copy and paste the configuration block below into the editor. This tells Ubuntu how to handle the application, where the icon is located, and which script to execute.
        
        ```
        [Desktop Entry]
        Version=1.0
        Type=Application
        Name=PyCharm
        Icon=/opt/pycharm/bin/pycharm.svg
        Exec="/opt/pycharm/bin/pycharm.sh" %f
        Comment=Python IDE
        Categories=Development;IDE;
        Terminal=false
        StartupWMClass=jetbrains-pycharm
       ```
      **Note**: Use `Ctrl + O` then Enter to save, and `Ctrl + X` to exit the nano editor.
   3. #### Set Permissions
      To make the shortcut recognized and executable by the system, update its permissions:
`sudo chmod +x /usr/share/applications/pycharm.desktop`

5. ### Summary
   You have successfully installed PyCharm! You can now find it by pressing the **Super key (Windows key)** and searching for "PyCharm." For quick access, right-click the icon in your search results and select Add to Favorites.

---

Troubleshooting Tips
* Icon not appearing? Verify that the path `/opt/pycharm/bin/pycharm.svg` actually contains the icon file. Some versions may use `.png`.

* Permission Denied? Always ensure you use sudo when modifying files inside the `/opt` or `/usr/share/applications` directories.
