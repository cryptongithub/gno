#!/bin/bash

if curl -s https://raw.githubusercontent.com/cryptongithub/init/main/empty.sh > /dev/null 2>&1; then
	echo ''
else
  sudo apt install curl -y
fi

alias gnokey="cd $HOME/gno && ./build/gnokey"

curl -s https://raw.githubusercontent.com/cryptongithub/init/main/logo.sh | bash 
echo -e '\e[40m\e[92mCrypton Academy is a unique cryptocurrency community. \nCommunity chat, early gems, calendar of events, Ambassador programs, nodes, testnets, personal assistant. \nJoin (TG): \e[95mt.me/CryptonLobbyBot\e[40m\e[92m.\e[0m\n'

function install_and_create {

    echo -e '\n\e[40m\e[92m1. Starting update...\e[0m'

    sudo apt update && sudo apt upgrade -y

    sudo apt install git make tar wget -y 
    
    source $HOME/.bash_profile
    if go version > /dev/null 2>&1
    then
        echo -e '\n\e[40m\e[92mSkipped Go installation\e[0m'
    else
        echo -e '\n\e[40m\e[92mStarting Go installation...\e[0m'
        cd $HOME && ver="1.17.2"
        wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
        sudo rm "go$ver.linux-amd64.tar.gz"
        echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
        echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profilesource
        source $HOME/.bash_profile
        go version
    fi

    echo -e '\n\e[40m\e[92m2. Starting Gno Installation...\e[0m'
    cd $HOME && git clone https://github.com/gnolang/gno/
    cd $HOME/gno && make
    echo -e '\n\e[40m\e[92mGenerating seed phrase...\e[0m'
    SEED_GNO=$(./build/gnokey generate)
    echo -e '\e[40m\e[92mSAVE your seed phrase:\e[40m\e[91m '$SEED_GNO' \e[0m' && sleep 2
    SEED_GNO=
    echo -e '\e[40m\e[92m' && read -p "Enter Wallet name: " GNO_WALLET && echo -e '\e[0m'
    echo 'export GNO_WALLET='${GNO_WALLET} >> $HOME/.bash_profile
    source $HOME/.bash_profile
    echo -e '\e[40m\e[92mRecovering wallet...\e[0m'
    echo -e '\e[40m\e[92mYou will need to type in and remember\e[40m\e[91m a passphrase\e[40m\e[92m (e.g. 1a3b5c7e) and then you will be asked to type in your \e[40m\e[91mseed phrase\e[40m\e[92m. \nYou can use any seed phrase not necessarily generated above.\e[0m' 
    ./build/gnokey add $GNO_WALLET --recover
    GNO_ADDRESS=$(./build/gnokey list | grep -Po '(?<=addr:\ ).*(?=\ pub:\ )')
    echo -e '\e[40m\e[92mSave your address:\e[40m\e[91m '$GNO_ADDRESS'\e[40m\e[92m and request test tokens on \e[40m\e[91mgno.land/faucet\e[40m\e[92m.\e[0m'
    echo 'export GNO_ADDRESS='${GNO_ADDRESS} >> $HOME/.bash_profile
    source $HOME/.bash_profile
    alias gnokey="cd $HOME/gno && ./build/gnokey"
}

function check_balance {
    source $HOME/.bash_profile
    cd $HOME/gno
    BALANCE=$(./build/gnokey query auth/accounts/$GNO_ADDRESS --remote gno.land:36657 | grep -Po '(?<="coins":\ ").*(?=",)')
    account_number=$(./build/gnokey query auth/accounts/$GNO_ADDRESS --remote gno.land:36657 | grep -Po '(?<="account_number":\ ").*(?=",)')
    sequence=$(./build/gnokey query auth/accounts/$GNO_ADDRESS --remote gno.land:36657 | grep -Po '(?<="sequence":\ ").*(?=")')
    echo -e '\e[40m\e[92mYour address:\e[0m '$GNO_ADDRESS
    echo -e '\e[40m\e[92mBalance:\e[0m '$BALANCE
    echo -e '\e[40m\e[92mAccount Number:\e[0m '$account_number
    echo -e '\e[40m\e[92mSequence:\e[0m '$sequence
}

function create_board {
    source $HOME/.bash_profile
    cd $HOME/gno
    rm -r $HOME/gno/createboard.unsigned.txt $HOME/gno/createboard.signed.txt
    echo -e '\n\e[40m\e[92m' && read -p "Enter board name (only a-z, 0-9): " GNO_BOARD_NAME && echo -e '\e[0m'
    ./build/gnokey maketx call $GNO_WALLET --pkgpath "gno.land/r/boards" --func CreateBoard --args $GNO_BOARD_NAME --gas-fee 1gnot --gas-wanted 2100000 > createboard.unsigned.txt
    ./build/gnokey sign $GNO_WALLET --txpath createboard.unsigned.txt --chainid "testchain" --number $(./build/gnokey query auth/accounts/$GNO_ADDRESS --remote gno.land:36657 | grep -Po '(?<="account_number":\ ").*(?=",)') --sequence $(./build/gnokey query auth/accounts/$GNO_ADDRESS --remote gno.land:36657 | grep -Po '(?<="sequence":\ ").*(?=")') > createboard.signed.txt
    ./build/gnokey broadcast createboard.signed.txt --remote gno.land:36657
    echo -e '\e[40m\e[92mIf you see something like: \e[2m\nOK! \nGAS WANTED: 2100000 \nGAS USED:   2008000\e[0m\e[40m\e[92m\na line above, your board was successfully created.\n\nNow go through \e[40m\e[91mgno.land/r/boards\e[40m\e[92m and find your board with name: \e[40m\e[91m'$GNO_BOARD_NAME'\e[40m\e[92m.\e[0m'
}

function cleanup {
      echo -e '\e[40m\e[91mAll previous data will be deleted. Triple check that you have saved all the necessary data.\e[0m' 
      read -p "Do you want to continue? Y/N: " -n 1 -r 
      if [[ $REPLY =~ ^[Yy]$ ]] 
        then
            sudo rm -rf $HOME/gno $HOME/.gno
            sed -i '/GNO_WALLET/d' $HOME/.bash_profile
            sed -i '/GNO_ADDRESS/d' $HOME/.bash_profile
            echo -e '\n\e[40m\e[92mAll previous data has been deleted.\e[0m'      
      elif [[ $REPLY =~ ^[Nn]$ ]] 
        then
            echo 
      else
            echo -e "\e[91mInvalid option $REPLY\e[0m"
      fi
}

echo -e '\e[40m\e[92mPlease enter your choice (input your option number and press Enter): \e[0m'
options=("Intall and create wallet" "Check balance (account_number, sequence)" "Create board" "Clean up!" "Quit")
select option in "${options[@]}"
do
    case $option in
        "Intall and create wallet")
            install_and_create
            break
            ;;
         "Check balance (account_number, sequence)")
            check_balance
            break
            ;;
         "Create board")
            create_board
            break
            ;;
         "Clean up!")
            cleanup
            break
            ;;
        "Quit")
            break
            ;;
        *) echo -e '\e[91mInvalid option $REPLY\e[0m';;
    esac
done
