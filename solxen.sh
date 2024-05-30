#!/bin/bash

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try switching to the root user with 'sudo -i' and then run this script again."
    exit 1
fi

function install_without_wallet() {
    # Update system and install necessary packages
    echo "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    echo "Installing essential tools and dependencies..."
    sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen

    # Install Rust and Cargo
    echo "Installing Rust and Cargo..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source $HOME/.cargo/env

    # Install Solana CLI
    echo "Installing Solana CLI..."
    sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"

    # Check if solana-keygen is in the PATH
    if ! command -v solana-keygen &> /dev/null; then
        echo "Adding Solana CLI to PATH"
        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        export PATH="$HOME/.cargo/bin:$PATH"
    fi

    # Create Solana keypair
    echo "Creating Solana keypair..."
    solana-keygen new --derivation-path m/44'/501'/0'/0' --force | tee solana-keygen-output.txt

    # Display message to prompt user to backup
    echo "Please make sure you have backed up the mnemonic and private key information displayed above."
    echo "Please recharge the pubkey with SOL assets for mining gas fees."

    echo "After backup is complete, type 'yes' to continue:"

    read -p "" user_confirmation

    if [[ "$user_confirmation" == "yes" ]]; then
        echo "Backup confirmed. Continuing script..."
    else
        echo "Script terminated. Please ensure you have backed up your information before running the script again."
        exit 1
    fi

    # Get OS type and architecture
    OS=$(uname -s)
    ARCH=$(uname -m)

    # Determine download URL
    case "$OS" in
      "Darwin")
        if [ "$ARCH" = "x86_64" ]; then
          URL="https://github.com/mmc-98/solxen-tx/releases/download/mainnet-beta5/solxen-tx-mainnet-beta5-darwin-amd64.tar.gz"
        elif [ "$ARCH" = "arm64" ]; then
          URL="https://github.com/mmc-98/solxen-tx/releases/download/mainnet-beta5/solxen-tx-mainnet-beta5-darwin-arm64.tar.gz"
        else
          echo "Unsupported architecture: $ARCH"
          exit 1
        fi
        ;;
      "Linux")
        if [ "$ARCH" = "x86_64" ]; then
          URL="https://github.com/mmc-98/solxen-tx/releases/download/mainnet-beta5/solxen-tx-mainnet-beta5-linux-amd64.tar.gz"
        elif [ "$ARCH" = "aarch64" ]; then
          URL="https://github.com/mmc-98/solxen-tx/releases/download/mainnet-beta5/solxen-tx-mainnet-beta5-linux-arm64.tar.gz"
        else
          echo "Unsupported architecture: $ARCH"
          exit 1
        fi
        ;;
      *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
    esac

    # Create temporary directory and download file
    TMP_DIR=$(mktemp -d)
    cd $TMP_DIR
    echo "Downloading file from $URL..."
    curl -L -o solxen-tx.tar.gz $URL

    # Create solxen folder in user's home directory
    SOLXEN_DIR="$HOME/solxen"
    mkdir -p $SOLXEN_DIR

    # Extract the file
    echo "Extracting solxen-tx.tar.gz..."
    tar -xzvf solxen-tx.tar.gz -C $SOLXEN_DIR

    # Check if the file exists
    SOLXEN_FILE="$SOLXEN_DIR/solxen-tx.yaml"
    if [ ! -f $SOLXEN_FILE ]; then
      echo "Error: $SOLXEN_FILE does not exist."
      exit 1
    fi

    read -p "Enter SOL wallet mnemonic: " mnemonic
    read -p "Enter the number of wallets to run concurrently (recommended: 4): " num
    read -p "Enter priority fee: " fee
    read -p "Enter interval time (milliseconds): " time
    read -p "Enter airdrop receiving address (needs to be an ETH wallet address): " evm
    read -p "Enter sol rpc address: " url

    # Update solxen-tx.yaml file
    sed -i "s|Mnemonic:.*|Mnemonic: \"$mnemonic\"|" $SOLXEN_FILE
    sed -i "s|Num:.*|Num: $num|" $SOLXEN_FILE
    sed -i "s|Fee:.*|Fee: $fee|" $SOLXEN_FILE
    sed -i "s|Time:.*|Time: $time|" $SOLXEN_FILE
    sed -i "s|ToAddr:.*|ToAddr: $evm|" $SOLXEN_FILE
    sed -i "s|Url:.*|Url: $url|" $SOLXEN_FILE

    # Clean up temporary directory
    cd ~
    rm -rf $TMP_DIR

    # Start screen session and run command
    screen -dmS solxen bash -c 'while true; do cd $HOME/solxen && ./solxen-tx miner; sleep 5; done'

    echo "solxen-tx installed and configured successfully. Use option 3 to check running status."

    echo '====================== Installation complete, node is running in the background. Use script option 2 or type "screen -r solxen" to check running status ==========================='
}

function install_node() {
    # Get OS type and architecture
    OS=$(uname -s)
    ARCH=$(uname -m)

    # Determine download URL
    case "$OS" in
      "Darwin")
        if [ "$ARCH" = "x86_64" ]; then
          URL="https://github.com/mmc-98/solxen-tx/releases/download/mainnet-beta5/solxen-tx-mainnet-beta5-darwin-amd64.tar.gz"
        elif [ "$ARCH" = "arm64" ]; then
          URL="https://github.com/mmc-98/solxen-tx/releases/download/mainnet-beta5/solxen-tx-mainnet-beta5-darwin-arm64.tar.gz"
        else
          echo "Unsupported architecture: $ARCH"
          exit 1
        fi
        ;;
      "Linux")
        if [ "$ARCH" = "x86_64" ]; then
          URL="https://github.com/mmc-98/solxen-tx/releases/download/mainnet-beta5/solxen-tx-mainnet-beta5-linux-amd64.tar.gz"
        elif [ "$ARCH" = "aarch64" ]; then
          URL="https://github.com/mmc-98/solxen-tx/releases/download/mainnet-beta5/solxen-tx-mainnet-beta5-linux-arm64.tar.gz"
        else
          echo "Unsupported architecture: $ARCH"
          exit 1
        fi
        ;;
      *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
    esac

    # Create temporary directory and download file
    TMP_DIR=$(mktemp -d)
    cd $TMP_DIR
    echo "Downloading file from $URL..."
    curl -L -o solxen-tx.tar.gz $URL

    # Create solxen folder in user's home directory
    SOLXEN_DIR="$HOME/solxen"
    mkdir -p $SOLXEN_DIR

    # Extract the file
    echo "Extracting solxen-tx.tar.gz..."
    tar -xzvf solxen-tx.tar.gz -C $SOLXEN_DIR

    # Check if the file exists
    SOLXEN_FILE="$SOLXEN_DIR/solxen-tx.yaml"
    if [ ! -f $SOLXEN_FILE ]; then
      echo "Error: $SOLXEN_FILE does not exist."
      exit 1
    fi

    read -p "Enter SOL wallet mnemonic: " mnemonic
    read -p "Enter the number of wallets to run concurrently (recommended: 4): " num
    read -p "Enter priority fee: " fee
    read -p "Enter interval time (milliseconds): " time
    read -p "Enter airdrop receiving address (needs to be an ETH wallet address): " evm
    read -p "Enter sol rpc address: " url

    # Update solxen-tx.yaml file
    sed -i "s|Mnemonic:.*|Mnemonic: \"$mnemonic\"|" $SOLXEN_FILE
    sed -i "s|Num:.*|Num: $num|" $SOLXEN_FILE
    sed -i "s|Fee:.*|Fee: $fee|" $SOLXEN_FILE
    sed -i "s|Time:.*|Time: $time|" $SOLXEN_FILE
    sed -i "s|ToAddr:.*|ToAddr: $evm|" $SOLXEN_FILE
    sed -i "s|Url:.*|Url: $url|" $SOLXEN_FILE

    # Clean up temporary directory
    cd ~
    rm -rf $TMP_DIR

    # Start screen session and run command
    screen -dmS solxen bash -c 'while true; do cd $HOME/solxen && ./solxen-tx miner; sleep 5; done'

    echo "solxen-tx installed and configured successfully. Use option 3 to check running status."
}

# Check progress
function check_XEN() {
    screen -r solxen
}

function check_wallet() {
    cd solxen
    ./solxen-tx balance
}

function running() {
    cd ~
    screen -dmS solxen bash -c 'while true; do cd solxen && ./solxen-tx miner; sleep 5; done'
}

# Main menu
function main_menu() {
    while true; do
        clear
        echo "Script and tutorial written by Twitter user 大赌哥 @y95277777, free and open source, do not trust paid versions"
        echo "=========================Modified based on GitHub user: mmc-98======================================="
        echo "Node community Telegram group: https://t.me/niuwuriji"
        echo "Node community Telegram channel: https://t.me/niuwuriji"
        echo "To exit the script, press Ctrl+C on your keyboard"
        echo "Please select an action to perform:"
        echo "1. Fresh node installation, suitable for users without a Solana wallet"
        echo "2. Standard node installation, suitable for users with an existing Solana wallet"
        echo "3. Check running status"
        echo "4. View wallet address information"
        echo "5. Restart mining after modifying some configurations"
        read -p "Enter option (1-5): " OPTION

        case $OPTION in
        1) install_without_wallet ;;
        2) install_node ;;
        3) check_XEN ;;
        4) check_wallet ;;
        5) running ;;
        *) echo "Invalid option." ;;
        esac
        echo "Press any key to return to the main menu..."
        read -n 1
    done
}

# Display main menu
main_menu
