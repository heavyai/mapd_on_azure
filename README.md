# Installing MapD Community Edition on Microsoft Azure

This repository contains scripts that can be used to install [MapD Community Edition](https://www.mapd.com/platform/download-community/) on Microsoft Azure.

## Getting Started

Installation instructions assume you have already signed up for a [Microsoft Azure account](https://azure.microsoft.com/en-us/free/search/) with sufficient access to create resources.

### Azure CLI Tools

Although the scripts in this repository can be used manually to install MapD Community Edition on an Azure VM via the [Azure Portal](https://portal.azure.com), for more automated installation you need to install [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).

Once the Azure CLI tools are installed, you'll need to authenticate using the following command:
`az login`

You only need to authenticate once over many days, re-authenticating only when the Azure CLI tells you that your token has expired (or, if you switch computers).

### Installation: Creating an Azure Instance and Docker

The script [AzureVMcreate.sh](https://github.com/mapd/mapd_on_azure/blob/master/AzureVMcreate.sh) is the entry-point for creating an Azure instance. In this script, the values are hard-coded to create a GPU-enabled instance with the following characteristics:

| Resource Type  | Description|
| ------------- | ------------- |
| GPU  | 1/2 NVIDIA Tesla K80  |
| RAM  | 56GB |
| SSD      | ~1TB     |

These values are just a suggestion to get started with; adding more GPUs/RAM/SSD will depend on desired performance and the size of datasets you plan to analyze.

To kickoff an instance, clone this repo, then run the following command: `bash AzureVMcreate.sh`. This main script will create the VM instance on Azure, [install Docker/nvidia-docker](https://github.com/mapd/mapd_on_azure/blob/master/MapDinstall.sh), then [start the MapD instance](https://github.com/mapd/mapd_on_azure/blob/master/StartMapD.sh) with the [MapD Immerse interface](https://www.mapd.com/platform/).
