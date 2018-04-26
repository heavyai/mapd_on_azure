#  Copyright 2018 MapD Technologies, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# Login using Azure CLI tools
# Install locally: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
# This is necessary to run locally, but not part of automated script
# az login

#To delete entire resource group cleanly
#
#az group delete --name MapDAzure --no-wait -y


# Create resource group
# Putting all resources in same group allows for deleting with single command later
#
az group create --name MapDAzure --location eastus

# Create network security group and open necessary ports
#
az network nsg create --resource-group MapDAzure --name NSGMapDAzure

az network nsg rule create --resource-group MapDAzure --nsg-name NSGMapDAzure --priority 100 --name SSH --destination-port-range 22
az network nsg rule create --resource-group MapDAzure --nsg-name NSGMapDAzure --priority 110 --name HTTP --destination-port-range 80
az network nsg rule create --resource-group MapDAzure --nsg-name NSGMapDAzure --priority 120 --name HTTPS --destination-port-range 443
az network nsg rule create --resource-group MapDAzure --nsg-name NSGMapDAzure --priority 200 --name mapd_ports --destination-port-range 9090-9093
az network nsg rule create --resource-group MapDAzure --nsg-name NSGMapDAzure --priority 210 --name jupyternotebook --destination-port-range 8888

# Create Public IP
#
az network public-ip create \
  --name PUBLICIPMapDAzure \
  --resource-group MapDAzure \
  --location "eastus" \
  --allocation-method Static

# Create virtual network
#
az network vnet create \
  --resource-group MapDAzure \
  --name VnetMapDAzure \
  --subnet-name default

# Create Network Interface Card
#
az network nic create \
  --resource-group MapDAzure \
  --name NICMapDAzure \
  --vnet-name VnetMapDAzure \
  --subnet default \
  --public-ip-address PUBLICIPMapDAzure \
  --network-security-group NSGMapDAzure

# Create VM
# Assumes you already have SSH key created at location ~/.ssh/id_rsa.pub
# Standard_NC6: 1 GPU, Standard_NC12: 2 GPUs, Standard_NC24: 4 GPUs
#
az vm create --resource-group MapDAzure \
  --name MapDCE \
  --location eastus \
  --size Standard_NC6 \
  --image UbuntuLTS \
  --os-disk-size-gb  1023 \
  --ssh-key-value ~/.ssh/id_rsa.pub \
  --nics NICMapDAzure \
  --admin-username mapdadmin \
  --storage-sku Standard_LRS \
  --verbose

# Add disks...by default, UbuntuLTS starts up as 30GB
# Two disks added here, can modify to size required for data
#
# az vm disk attach --resource-group MapDAzure \
#  --vm-name MapDCE \
#  --disk MapDAzure_disk1 \
#  --new \
#  --caching ReadWrite \
#  --size-gb 512 \
#  --sku Standard_LRS
#
#  az vm disk attach --resource-group MapDAzure \
#   --vm-name MapDCE \
#   --disk MapDAzure_disk2 \
#   --new \
#   --caching ReadWrite \
#   --size-gb 512 \
#   --sku Standard_LRS

pubip=$( az vm show --show-details --resource-group MapDAzure --name MapDCE --query publicIps -otsv )
echo "Congratulations! You have created an Azure VM with the public IP: $pubip"

# ssh into new instance to silently accept key into local known_users
#
ssh -o StrictHostKeyChecking=accept-new mapdadmin@$pubip pwd

# Copy MapD install and startup scripts to Azure VM
#
scp MapDinstall.sh mapdadmin@$pubip:/home/mapdadmin/
scp StartMapD.sh mapdadmin@$pubip:/home/mapdadmin/

# Put StartMapD into cron, to run after each reboot
#
ssh mapdadmin@$pubip << EOF
  crontab -l > mapd_start
  echo "@reboot bash /home/mapdadmin/StartMapD.sh &" >> mapd_start
  crontab mapd_start
  rm mapd_start
EOF

# Install MapD...will reboot after install
#
ssh mapdadmin@$pubip bash MapDinstall.sh
echo "After VM reboots, MapD Immerse can be accessed at $pubip:9092"
echo "Make take several minutes (<5m) for Immerse to be available after reboot"
