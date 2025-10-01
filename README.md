# E-commerce Microservices Application with CI/CD Pipeline

This project demonstrates a complete microservices e-commerce application with Continuous Integration and Continuous Deployment using GitHub Actions and Azure Container Registry.

## Architecture

The application consists of:

- **Customer Service** (FastAPI/Python) - Manages customer data
- **Product Service** (FastAPI/Python) - Manages products and inventory
- **Order Service** (FastAPI/Python) - Handles order processing with async messaging
- **Frontend** (HTML/JavaScript/Nginx) - User interface
- **PostgreSQL** - Database for each service
- **RabbitMQ** - Message broker for async communication

## CI/CD Pipeline Overview

### Stage 1: Continuous Integration (CI Pipeline)
- **Trigger**: Push to `testing` branch
- **Actions**:
  1. Run unit tests for all services
  2. Build Docker images
  3. Test Docker images locally
  4. Push images to Azure Container Registry (only if all tests pass)
  5. Trigger staging deployment

### Stage 2: Staging Deployment
- **Trigger**: Successful image push to ACR
- **Actions**:
  1. Create temporary staging infrastructure in Azure
  2. Deploy services to staging environment
  3. Run acceptance tests
  4. Clean up staging infrastructure

### Stage 3: Production Deployment
- **Trigger**: Merge to `main` branch
- **Actions**:
  1. Deploy to existing production environment
  2. Update containers with new images
  3. Verify deployment health

## Local Development Setup

### Prerequisites
- Docker and Docker Compose
- Python 3.11+
- Git

### Running Locally

1. **Clone the repository**:
   ```bash
   git clone <your-repo-url>
   cd task10_2d
   ```

2. **Start all services**:
   ```bash
   docker-compose up --build
   ```

3. **Access the application**:
   - Frontend: http://localhost:80
   - Customer Service: http://localhost:8002
   - Product Service: http://localhost:8001
   - Order Service: http://localhost:8003
   - RabbitMQ Management: http://localhost:15672 (guest/guest)

### Individual Service Development

To run individual services for development:

```bash
# Customer Service
cd backend/customer_service
pip install -r requirements-dev.txt
uvicorn app.main:app --host 0.0.0.0 --port 8002 --reload

# Product Service
cd backend/product_service
pip install -r requirements-dev.txt
uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload

# Order Service
cd backend/order_service
pip install -r requirements-dev.txt
uvicorn app.main:app --host 0.0.0.0 --port 8003 --reload
```

## Azure Setup

### Required Azure Resources

1. **Azure Container Registry (ACR)**
2. **Resource Groups** (production and staging)
3. **PostgreSQL Flexible Server** (production)
4. **Container Instances** (production and staging)
5. **Service Principal** for GitHub Actions

### GitHub Secrets Configuration

Configure the following secrets in your GitHub repository:

#### Azure Authentication
- `AZURE_CREDENTIALS` - Service principal credentials (JSON)

#### Container Registry
- `AZURE_CONTAINER_REGISTRY` - Your ACR login server URL
- `REGISTRY_USERNAME` - ACR username
- `REGISTRY_PASSWORD` - ACR password

#### Resource Groups
- `AZURE_RESOURCE_GROUP` - Production resource group name
- `STAGING_RESOURCE_GROUP` - Staging resource group name (will be created dynamically)
- `AZURE_SUBSCRIPTION_ID` - Your Azure subscription ID

#### Database Credentials
- `POSTGRES_PASSWORD` - PostgreSQL admin password

#### Production Environment Variables
- `PRODUCTION_DATABASE_URL_CUSTOMER` - Customer service database URL
- `PRODUCTION_DATABASE_URL_ORDER` - Order service database URL
- `PRODUCTION_DATABASE_URL_PRODUCT` - Product service database URL
- `PRODUCTION_CUSTOMER_SERVICE_URL` - Customer service URL in production
- `PRODUCTION_RABBITMQ_HOST` - RabbitMQ host in production
- `PRODUCTION_RABBITMQ_PORT` - RabbitMQ port in production
- `PRODUCTION_RABBITMQ_USER` - RabbitMQ username in production
- `PRODUCTION_RABBITMQ_PASS` - RabbitMQ password in production
- `PRODUCTION_AZURE_STORAGE_ACCOUNT_NAME` - Azure Storage account name
- `PRODUCTION_AZURE_STORAGE_ACCOUNT_KEY` - Azure Storage account key

### Creating Azure Service Principal

```bash
# Create service principal
az ad sp create-for-rbac --name "github-actions-sp" --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --sdk-auth

# The output should be saved as AZURE_CREDENTIALS secret
```

## Testing the Pipeline

### 1. Testing Branch Workflow
1. Create a `testing` branch
2. Make changes to the code
3. Push to `testing` branch
4. Watch the CI pipeline execute:
   - Tests will run
   - Images will be built and tested
   - Images will be pushed to ACR (if tests pass)
   - Staging deployment will be triggered

### 2. Production Deployment
1. Create a pull request from `testing` to `main`
2. Merge the pull request
3. Production deployment pipeline will execute
4. Services will be updated in production environment

## API Documentation

### Customer Service
- Base URL: `http://localhost:8002`
- Endpoints:
  - `GET /` - Welcome message
  - `GET /health` - Health check
  - `POST /customers/` - Create customer
  - `GET /customers/` - List customers
  - `GET /customers/{id}` - Get customer by ID
  - `PUT /customers/{id}` - Update customer
  - `DELETE /customers/{id}` - Delete customer

### Product Service
- Base URL: `http://localhost:8001`
- Endpoints:
  - `GET /` - Welcome message
  - `GET /health` - Health check
  - `POST /products/` - Create product
  - `GET /products/` - List products
  - `GET /products/{id}` - Get product by ID
  - `PUT /products/{id}` - Update product
  - `DELETE /products/{id}` - Delete product
  - `POST /products/{id}/upload-image` - Upload product image

### Order Service
- Base URL: `http://localhost:8003`
- Endpoints:
  - `GET /` - Welcome message
  - `GET /health` - Health check
  - `POST /orders/` - Create order
  - `GET /orders/` - List orders
  - `GET /orders/{id}` - Get order by ID
  - `PATCH /orders/{id}/status` - Update order status
  - `DELETE /orders/{id}` - Delete order

## Monitoring and Logging

- All services include comprehensive logging
- Health check endpoints for monitoring
- RabbitMQ management interface for message monitoring
- Azure Container Instances provide built-in logging

## Troubleshooting

### Common Issues

1. **Database Connection Issues**
   - Ensure PostgreSQL containers are running
   - Check database URLs in environment variables

2. **RabbitMQ Connection Issues**
   - Verify RabbitMQ container is running
   - Check RabbitMQ credentials and host configuration

3. **Service Communication Issues**
   - Ensure all services are on the same Docker network
   - Check service URLs and ports

4. **Pipeline Failures**
   - Check GitHub Actions logs
   - Verify all required secrets are configured
   - Ensure Azure resources exist and are accessible

### Debugging Commands

```bash
# Check running containers
docker-compose ps

# View logs
docker-compose logs [service-name]

# Test service health
curl http://localhost:8001/health  # Product Service
curl http://localhost:8002/health  # Customer Service
curl http://localhost:8003/health  # Order Service
```

## Project Structure

```
task10_2d/
├── .github/
│   └── workflows/
│       ├── ci-pipeline.yml           # CI pipeline for testing branch
│       ├── staging-deployment.yml    # Staging deployment pipeline
│       └── production-deployment.yml # Production deployment pipeline
├── backend/
│   ├── customer_service/             # Customer microservice
│   ├── order_service/               # Order microservice
│   └── product_service/             # Product microservice
├── frontend/                        # Frontend application
├── docker-compose.yml              # Local development setup
└── README.md                       # This file
```

## Contributing

1. Create a feature branch from `testing`
2. Make your changes
3. Run tests locally: `docker-compose up --build`
4. Push to your feature branch
5. Create a pull request to `testing` branch
6. After testing, merge to `main` for production deployment

