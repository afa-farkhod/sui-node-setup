#!/bin/bash
echo -e "\033[0;33m"
echo "==========================================================================================================================="
echo " "
echo "  ██████╗ ██████╗ ███╗   ██╗████████╗██████╗ ██╗██████╗ ██╗   ██╗████████╗██╗ ██████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ";
echo " ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██║██╔══██╗██║   ██║╚══██╔══╝██║██╔═══██╗████╗  ██║██╔══██╗██╔══██╗██╔═══██╗";
echo " ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║██████╔╝██║   ██║   ██║   ██║██║   ██║██╔██╗ ██║██║  ██║███████║██║   ██║";
echo " ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║██╔══██╗██║   ██║   ██║   ██║██║   ██║██║╚██╗██║██║  ██║██╔══██║██║   ██║";
echo " ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║██║██████╔╝╚██████╔╝   ██║   ██║╚██████╔╝██║ ╚████║██████╔╝██║  ██║╚██████╔╝";
echo "  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝    ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ";
                                                                                                                                                                                                 
echo -e "\033[0;33m"
echo "==========================================================================================================================="                                                                                    
sleep 1

echo -e "\e[1m\e[32m1. Updating packages \e[0m" && sleep 1
sudo apt update && sudo apt upgrade -y


echo -e "\e[1m\e[32m2. Install dependencies \e[0m" && sleep 1
sudo apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends tzdata git ca-certificates curl build-essential libssl-dev pkg-config libclang-dev cmake jq
sudo apt install libprotobuf-dev protobuf-compiler
wget http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb


echo -e "\e[1m\e[32m3. Install Rust \e[0m" && sleep 1
sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env


echo -e "\e[1m\e[32m4. Download Sui Main GitHub Repository \e[0m" && sleep 1
cd $HOME
rm -rf sui
git clone https://github.com/MystenLabs/sui.git
cd sui
git remote add upstream https://github.com/MystenLabs/sui
git fetch upstream
git checkout -B testnet --track upstream/testnet

echo -e "\e[1m\e[32m4. Building binaries: sui-node, sui, sui-tool \e[0m" && sleep 1
cargo build -p sui-node -p sui -p sui-tool --release
mv ~/sui/target/release/sui-node /usr/local/bin/
mv ~/sui/target/release/sui /usr/local/bin/
mv ~/sui/target/release/sui-tool /usr/local/bin/





echo -e "\e[1m\e[32m3. Update Configs \e[0m" && sleep 1
mkdir -p $HOME/.sui/
cd $HOME/.sui/
wget -O genesis.blob https://github.com/MystenLabs/sui-genesis/raw/main/testnet/genesis.blob
cp $HOME/sui/crates/sui-config/data/fullnode-template.yaml $HOME/.sui/fullnode.yaml
sed -i 's/127.0.0.1/0.0.0.0/'  $HOME/.sui/fullnode.yaml
sed -i "s|db-path:.*|db-path: $HOME/.sui/db|g" $HOME/.sui/fullnode.yaml
sed -i "s|genesis-file-location:.*|genesis-file-location: $HOME/.sui/genesis.blob|g" $HOME/.sui/fullnode.yaml

sudo tee -a $HOME/.sui/fullnode.yaml  >/dev/null <<EOF

p2p-config:
  seed-peers:
   - address: "/dns/sui-rpc-pt.testnet-pride.com/udp/8084"
     peer-id: 0b10182585ae4a305721b1823ea5a9c3ce7d6ac4b4a8ce35fe96d9914c8fcb73
   - address: "/dns/sui-rpc-pt2.testnet-pride.com/udp/8084"
     peer-id: bf45f2bd2bbc4c2d53d10c05c96085d4ef18688af04649d6e65e1ebad1716804
   - address: "/dns/sui-rpc-testnet.bartestnet.com/udp/8084"
   - address: "/ip4/38.242.197.20/udp/8080"
   - address: "/ip4/178.18.250.62/udp/8080"
   - address: "/ip4/162.55.84.47/udp/8084"
   - address: "/dns/wave-3.testnet.n1stake.com/udp/8084"
   - address: "/ip4/46.4.119.19/udp/8084"
   - address: "/ip4/89.58.5.19/udp/8084"
   - address: "/dns/sui-testnet.fort.software/udp/8080"
   - address: "/ip4/207.180.201.73/udp/8084"
   - address: "/ip4/65.109.108.186/udp/8084"
EOF

# Reference:
# https://docs.sui.io/guides/operator/snapshots
echo -e "\e[1m\e[32m3. Download Snapshot \e[0m" && sleep 1
echo "Snapshot: 1 ~ 2 TB disk space is required"
sui-tool download-db-snapshot --latest --path $HOME/.sui/db --network testnet --num-parallel-downloads 25 --no-sign-request



echo -e "\e[1m\e[32m5. Make Sui Service \e[0m" && sleep 1
sudo tee /etc/systemd/system/suid.service > /dev/null <<EOF
[Unit]
Description=Sui node
After=network-online.target

[Service]
User=$USER
ExecStart=/usr/local/bin/sui-node --config-path $HOME/.sui/fullnode.yaml
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF


sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF




sudo systemctl daemon-reload
sudo systemctl enable suid
sudo systemctl restart suid



echo "==========================================================================================================================="    

echo -e '\e[32mCheck your sui status\e[39m' && sleep 1
if [[ `service suid status | grep active` =~ "running" ]]; then
  echo -e "Your Sui node \e[32minstalled and running normally\e[39m!"
else
  echo -e "Your Sui node \e[31mwas failed installed\e[39m, Please Re-install."
fi

echo " "
echo -e "\e[1m\e[34mYour Sui Version : $(sui -V)\e[0m" && sleep 1
echo " "
echo " "
echo " "
echo -e "\e[1m\e[32m6. Usefull commands \e[0m" && sleep 1
echo -e "Check your node logs: \e[1m\e[32m journalctl -fu suid -o cat \e[0m"
echo -e "Check your node status: \e[1m\e[32m sudo service suid status \e[0m"
echo -e "Restart your node: \e[1m\e[32m sudo systemctl restart suid \e[0m"
echo -e "Stop your node: \e[1m\e[32m sudo systemctl stop suid \e[0m"
echo -e "Start your node: \e[1m\e[32m sudo systemctl start suid \e[0m"
