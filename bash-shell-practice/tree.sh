# Run the script
# ./tree.sh /path/to/directory

#!/bin/bash

# Function to print the directory tree
print_tree() {
    local directory="$1"
    local prefix="$2"

    # Get the list of files and directories in the current directory
    local items=("$directory"/*)

    # Remove the directory itself from the list if empty
    if [[ ${#items[@]} -eq 0 ]]; then
        return
    fi

    for ((i = 0; i < ${#items[@]}; i++)); do
        local item="${items[$i]}"
        local basename="$(basename "$item")"

        # Determine the prefix to use for the current item
        if [[ $i -lt $((${#items[@]} - 1)) ]]; then
            local current_prefix="$prefix├── "
            local next_prefix="$prefix│   "
        else
            local current_prefix="$prefix└── "
            local next_prefix="$prefix    "
        fi

        # Print the current item
        echo "${current_prefix}${basename}"

        # If the current item is a directory, recursively print its contents
        if [[ -d "$item" ]]; then
            print_tree "$item" "$next_prefix"
        fi
    done
}

# Get the target directory from the command line arguments, default to the current directory
target_directory="${1:-.}"

# Print the directory structure
echo "$target_directory"
print_tree "$target_directory" ""
