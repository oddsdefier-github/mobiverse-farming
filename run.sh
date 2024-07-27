#!/bin/bash

# Define constants
TMUX_SESSION_NAME="mobi"
ENV_FILE=".env"
INDEX_FILE="index.js"
RUNNING_FROM_UPDATE_TOKEN=false

# Function to check if the .env file exists; if not, call update_token
check_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        update_token
    fi
}

# Function to run index.js with Node.js in a new tmux session
run_index_js() {
    # Check if the .env file exists; if not, call update_token
    check_env_file

    # Check if a tmux session named 'mobi' already exists
    if tmux has-session -t $TMUX_SESSION_NAME 2>/dev/null; then
        echo "Tmux session $TMUX_SESSION_NAME already exists."
        # Print messages only if not called from update_token
        if [ "$RUNNING_FROM_UPDATE_TOKEN" = false ]; then
            echo ""
            echo "Mining has already started."
            echo "You can check the mining status by selecting option 2 from the main menu."
        fi
        return
    fi

    # Create a new tmux session named 'mobi'
    if ! tmux new-session -d -s $TMUX_SESSION_NAME; then
        echo "Failed to create new tmux session: $TMUX_SESSION_NAME"
        return
    fi

    # Send command to run index.js
    if ! tmux send-keys -t $TMUX_SESSION_NAME "node $INDEX_FILE" C-m; then
        echo "Failed to send command to tmux session: $TMUX_SESSION_NAME"
        return
    fi

    # Print messages only if not called from update_token
    if [ "$RUNNING_FROM_UPDATE_TOKEN" = false ]; then
        echo ""
        echo "Mining has started."
        echo "You can check the mining status by selecting option 2 from the main menu."
    fi
}

# Function to attach to tmux session
attach_tmux() {
    if ! tmux attach -t $TMUX_SESSION_NAME; then
        echo "Failed to attach to tmux session: $TMUX_SESSION_NAME"
    fi
}

# Function to update .env file with new token
update_token() {
    echo "Please enter the new token:"
    read -r new_token
    if [ -z "$new_token" ]; then
        echo "No token entered. Exiting."
        return
    fi

    # Check if the .env file exists, and create it if not
    if [ ! -f "$ENV_FILE" ]; then
        echo "$ENV_FILE does not exist. Creating it."
        if ! touch "$ENV_FILE"; then
            echo "Failed to create $ENV_FILE."
            return
        fi
    fi

    echo "Updating $ENV_FILE with new token."
    if ! echo "TOKEN=$new_token" > $ENV_FILE; then
        echo "Failed to update $ENV_FILE with new token."
        return
    fi
    echo ".env file updated successfully."

    # Reset the flag
    RUNNING_FROM_UPDATE_TOKEN=false
}

# Function to kill the tmux session
kill_tmux() {
    if tmux has-session -t $TMUX_SESSION_NAME 2>/dev/null; then
        if ! tmux kill-session -t $TMUX_SESSION_NAME; then
            echo "Failed to kill tmux session: $TMUX_SESSION_NAME"
        else
            echo "Mining has stopped."
        fi
    else
        echo "No tmux session named $TMUX_SESSION_NAME exists."
    fi
}

# Main menu
while true; do
    clear
    echo "================================="
    echo " Mobi Session Management Menu"
    echo "================================="
    echo "1. Start mining"
    echo "2. Check mining"
    echo "3. Update token in .env file"
    echo "4. Stop mining"
    echo "5. Exit (or press Enter)"
    echo "================================="
    echo "Enter your choice (1-5) or press Enter to exit:"
    read -r choice

    # If the user presses Enter without input, exit
    if [ -z "$choice" ]; then
        echo "Exiting..."
        break
    fi

    case $choice in
        1)
            run_index_js
            ;;
        2)
            attach_tmux
            ;;
        3)
            update_token
            run_index_js
            ;;
        4)
            kill_tmux
            ;;
        5)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid choice. Please select a valid option."
            ;;
    esac

    echo ""
    echo "Press any key to return to the main menu..."
    read -n 1 -s
done
