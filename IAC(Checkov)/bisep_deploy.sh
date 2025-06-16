#!/bin/bash
# Deployment script for the vulnerable Bicep file
# DO NOT USE IN PRODUCTION - FOR TESTING PURPOSES ONLY

# Set variables
RESOURCE_GROUP="rg-vulnerable-test"
LOCATION="eastus"

# Create resource group
echo "Creating resource group $RESOURCE_GROUP..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Deploy the Bicep template
echo "Deploying vulnerable infrastructure..."
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file vulnerable_infrastructure.bicep \
  --parameters environmentName=dev \
  --parameters adminUsername=adminuser \
  --parameters adminPassword=Password123!

echo "Deployment complete. Do not leave these resources running in production!"