#!/bin/bash
cd $HOME
sudo mkdir -p sui
cd sui
wget https://raw.githubusercontent.com/MystenLabs/sui/main/docker/fullnode/docker-compose.yaml
sed -i 's/fullnode-template.yaml/fullnode.yaml/' docker-compose.yaml
wget https://github.com/MystenLabs/sui/raw/main/crates/sui-config/data/fullnode-template.yaml
cp fullnode-template.yaml fullnode.yaml
sudo sed -i 's/127.0.0.1/0.0.0.0/' fullnode.yaml
wget https://github.com/MystenLabs/sui-genesis/raw/main/devnet/genesis.blob
docker network create sui-network
docker-compose up -d
