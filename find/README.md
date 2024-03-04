# Linux `find` Command

The `find` command in Linux is a powerful tool for searching and locating files and directories. It is used to traverse directory hierarchies and perform various operations on files based on different criteria. Here are some common use cases and options for the `find` command:

## Basic Syntax

    find [path] [options] [expression]

1. Search by Name

        find /path/to/search -name "filename"

2. Search by Extension

        find /path/to/search -name "*.txt"

3. Case-Insensitive Search

        find /path/to/search -iname "filename"

4. Search by Type

        find /path/to/search -type f    # Regular files
        find /path/to/search -type d    # Directories

