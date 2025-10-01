#!/bin/bash

# Azure Setup Script for E-commerce Microservices CI/CD Pipeline
# This script creates the necessary Azure resources for the CI/CD pipeline

set -e

# Configuration
RESOURCE_GROUP="ecommerce-production-rg"
ACR_NAME="ecommerceacr$(date +%s)"  # Unique name for ACR
LOCATION="eastus"
POSTGRES_SERVER_NAME="ecommerce-postgres-$(date +%s)"
POSTGRES_ADMIN_USER="postgres"
POSTGRES_ADMIN_PASSWORD="$(openssl rand -base64 32)"

echo "🚀 Setting up Azure resources for E-commerce CI/CD Pipeline"
echo "=========================================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo "❌ Please log in to Azure CLI first:"
    echo "az login"
    exit 1
fi

echo "✅ Azure CLI is ready"

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "📋 Subscription ID: $SUBSCRIPTION_ID"

# Create Resource Group
echo "🔨 Creating Resource Group: $RESOURCE_GROUP"
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --output table

# Create Azure Container Registry
echo "🐳 Creating Azure Container Registry: $ACR_NAME"
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Basic \
    --admin-enabled true \
    --output table

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query loginServer -o tsv)
echo "📝 ACR Login Server: $ACR_LOGIN_SERVER"

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query passwords[0].value -o tsv)

# Create PostgreSQL Flexible Server
echo "🗄️ Creating PostgreSQL Flexible Server: $POSTGRES_SERVER_NAME"
az postgres flexible-server create \
    --resource-group $RESOURCE_GROUP \
    --name $POSTGRES_SERVER_NAME \
    --location $LOCATION \
    --admin-user $POSTGRES_ADMIN_USER \
    --admin-password $POSTGRES_ADMIN_PASSWORD \
    --sku-name Standard_B1ms \
    --tier Burstable \
    --public-access 0.0.0.0 \
    --storage-size 32 \
    --output table

# Create databases
echo "📊 Creating databases..."
az postgres flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $POSTGRES_SERVER_NAME \
    --database-name customer_db

az postgres flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $POSTGRES_SERVER_NAME \
    --database-name order_db

az postgres flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $POSTGRES_SERVER_NAME \
    --database-name product_db

# Get PostgreSQL connection details
POSTGRES_HOST=$(az postgres flexible-server show --resource-group $RESOURCE_GROUP --name $POSTGRES_SERVER_NAME --query fullyQualifiedDomainName -o tsv)

# Create Service Principal for GitHub Actions
echo "🔑 Creating Service Principal for GitHub Actions"
SP_OUTPUT=$(az ad sp create-for-rbac \
    --name "github-actions-ecommerce" \
    --role contributor \
    --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
    --sdk-auth)

echo "✅ Azure resources created successfully!"
echo "========================================"
echo ""
echo "📋 GitHub Secrets Configuration:"
echo "================================="
echo "AZURE_CREDENTIALS: $SP_OUTPUT"
echo ""
echo "AZURE_CONTAINER_REGISTRY: $ACR_LOGIN_SERVER"
echo "REGISTRY_USERNAME: $ACR_USERNAME"
echo "REGISTRY_PASSWORD: $ACR_PASSWORD"
echo ""
echo "AZURE_RESOURCE_GROUP: $RESOURCE_GROUP"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "STAGING_RESOURCE_GROUP: ecommerce-staging-rg"
echo ""
echo "POSTGRES_PASSWORD: $POSTGRES_ADMIN_PASSWORD"
echo ""
echo "Production Database URLs:"
echo "PRODUCTION_DATABASE_URL_CUSTOMER: postgresql://$POSTGRES_ADMIN_USER:$POSTGRES_ADMIN_PASSWORD@$POSTGRES_HOST:5432/customer_db"
echo "PRODUCTION_DATABASE_URL_ORDER: postgresql://$POSTGRES_ADMIN_USER:$POSTGRES_ADMIN_PASSWORD@$POSTGRES_HOST:5432/order_db"
echo "PRODUCTION_DATABASE_URL_PRODUCT: postgresql://$POSTGRES_ADMIN_USER:$POSTGRES_ADMIN_PASSWORD@$POSTGRES_HOST:5432/product_db"
echo ""
echo "Production Service URLs (will be updated after first deployment):"
echo "PRODUCTION_CUSTOMER_SERVICE_URL: http://production-customer-service.eastus.azurecontainer.io:8002"
echo ""
echo "RabbitMQ (for production - you may want to create a managed instance):"
echo "PRODUCTION_RABBITMQ_HOST: localhost"
echo "PRODUCTION_RABBITMQ_PORT: 5672"
echo "PRODUCTION_RABBITMQ_USER: guest"
echo "PRODUCTION_RABBITMQ_PASS: guest"
echo ""
echo "Azure Storage (optional - for product images):"
echo "PRODUCTION_AZURE_STORAGE_ACCOUNT_NAME: your-storage-account"
echo "PRODUCTION_AZURE_STORAGE_ACCOUNT_KEY: your-storage-key"
echo ""
echo "🔧 Next Steps:"
echo "=============="
echo "1. Copy the above secrets to your GitHub repository settings"
echo "2. Create a 'testing' branch in your repository"
echo "3. Push code to the 'testing' branch to trigger CI pipeline"
echo "4. Monitor the GitHub Actions workflow execution"
echo ""
echo "📚 Documentation:"
echo "================="
echo "Frontend: http://localhost:80 (after local deployment)"
echo "Customer Service: http://localhost:8002"
echo "Product Service: http://localhost:8001"
echo "Order Service: http://localhost:8003"
echo "RabbitMQ Management: http://localhost:15672 (guest/guest)"
echo ""
echo "🎉 Setup complete! Your CI/CD pipeline is ready to use."
