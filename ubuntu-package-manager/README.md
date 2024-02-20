### How to list all or specific packages installed on Debian/Ubuntu Linux system

    sudo dpkg -i package-name

### The general syntax of using apt command follows:

    apt [COMMAND] [PACKAGE]

### Update Package Database

    sudo apt update

### Upgrade Installed Packages

    sudo apt upgrade
    sudo apt update && sudo apt upgrade -y [in single command]

### Full-Upgrade Packages

apt also offers a full-upgrade command. It differs from upgrade command as it will remove currently installed packages if this is needed to upgrade the system as a whole. As such be careful with this command and if possible, go with the upgrade command instead.

    sudo apt full-upgrade

### Install Single Package

    sudo apt install [package-name]

### Install Multiple Packages

    sudo apt install [package-name-1] [package-name-2] ... [package-name-n]

### Install Specific Version

    sudo apt install [package-name]=[version]
    sudo apt install unzip=6.0-25ubuntu1

### Remove a Package

    sudo apt remove [package-name]

### Purge a Package

Like removing a package, purging a package also does the same task but while with remove command apt just removes the binaries of a package leaving the configuration files as it is. On the other hand, purge command ensures that everything related to the package including its binaries and configuration files is removed from the system. Leaving the configuration files allows you to reuse the same configuration files again if you plan to reinstall the application.

    sudo apt purge [package-name]

### Search for Packages

apt can not only serve as the utility to install and remove packages. It can also search the required package in the repository with search command as:

    apt search [search-text]
    apt search netstat

### View Package Content

To get details about a package, whether it is installed or to be installed, you can use show command as given below:

    apt show [package-name]

### List Installed Packages

We often need to list installed packages on a system for different purposes. apt allows you to get the list of installed packages simply with

    apt list --installed

### List All Packages

To list all packages available for your system, use list command with --all-versions keyword as

    apt list --all-versions

### List Upgradable Packages

Packages need to be kept up-to-date as new versions keep releasing with improved or additional features and bug fixes including critical security loopholes. apt ensures you can patch your Debian/Ubuntu system easily with upgrade command as suggested earlier in the article. To list all available upgrades for installed packages on your system, run

    apt list --upgradable
    

### Clean Unused Packages

With normal usage, sometimes your system may have packages installed that are no longer required. It may happen as these packages were installed as part of the dependency of another package which has already been removed later though the dependencies are left lingering on the system. To clean such packages and free up some disk space you can use

    sudo apt autoremove

### Check Package Dependencies

A package may have one or more dependencies that must be installed on a system for the package to work correctly. apt ensures required dependencies are installed as part of package installation. If you want to check dependencies of a package, use

    apt depends [package-name]

### Reinstall a Package

A package may get corrupted or you may need to reinstall it to ensure all package files are in the right order. To install a package again without removing it first you can use

    sudo apt reinstall [package-name]

### Download a Package

Package files can be downloaded to the local filesystem without installing them. To download a package with apt, use:

    apt download [package-name]
    apt download unzip

### Check Package Changelog

We can easily check the changelog about any package with apt by using

    apt changelog [package-name]

### Edit Sources

apt‘s edit-sources command lets you edit your sources.list files while also providing sanity checks to ensure the changes are consistent and valid. This is a work-in-progress command and hence should be used with care. You can edit sources.list as 

    sudo apt edit-sources

### Get APT Help

    apt help
    man apt