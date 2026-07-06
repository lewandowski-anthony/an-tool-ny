# S3-Compatible Local Storage Environments

This repository provides Docker Compose configurations for setting up local, S3-compatible object storage engines. These setups are ideal for local development, testing pipelines, and replacing cloud-based AWS S3 buckets with a local equivalent.

Two options are provided:
1. **MinIO**: A feature-rich, high-performance object storage server with a built-in web console and auto-initialization.
2. **SeaweedFS**: A fast, distributed filesystem optimized for handling billions of small files efficiently with a native S3 API layer.

---

## MinIO Configuration

MinIO is a widely adopted cloud-native object storage server. This configuration includes an automated initialization container (`minio-init`) that provisions a default bucket and configures its access policies upon startup.

### Features
* **API Port**: `9000` (Used by applications and SDKs)
* **Console Port**: `9001` (Web-based user interface)
* **Automated Setup**: Automatically creates a bucket named `my-bucket` with a `download` (public-read) policy.
* **Persistence**: Data is persisted locally via the `minio_data` Docker volume.

### Usage

1. Start the MinIO services:
   ```bash
   docker compose -f minio-compose.yaml up -d
   ```

2. Access the MinIO Web Console by navigating to `http://localhost:9001` in your browser.
    * **Username**: `admin`
    * **Password**: `password123`

3. Connect your application or S3 client using the following credentials:
    * **Endpoint**: `http://localhost:9000`
    * **Access Key**: `admin`
    * **Secret Key**: `password123`
    * **Default Bucket**: `my-bucket`

---

## SeaweedFS Configuration

SeaweedFS is a highly scalable distributed filesystem. When started with the `-s3` flag, it enables an S3-compatible interface alongside its master and volume servers, running all components inside a single container for simplicity.

### Features
* **Filer / S3 Port**: `8333` (Handles S3 API requests)
* **Master Port**: `9333` (Manages volume assignment and cluster state)
* **Performance**: Optimized for fast write/read paths and low metadata overhead.
* **Persistence**: Data is persisted locally via the `seaweed_data` Docker volume.

### Usage

1. Start the SeaweedFS service:
   ```bash
   docker compose -f seaweed-compose.yaml up -d
   ```

2. Connect your application or S3 client using the following credentials:
    * **Endpoint**: `http://localhost:8333`
    * **Access Key**: *Not required / accepted by default configuration*
    * **Secret Key**: *Not required / accepted by default configuration*

*Note: SeaweedFS does not automatically create buckets via this compose file. You must create buckets programmatically using an S3 SDK or an external tool like AWS CLI or MinIO Client (`mc`).*

---

## Verifying the Setup with AWS CLI

You can test either environment using the standard AWS CLI by overriding the endpoint URL.

### Testing MinIO
```bash
# List buckets
aws --endpoint-url http://localhost:9000 s3 ls

# Upload a test file
aws --endpoint-url http://localhost:9000 s3 cp test.txt s3://my-bucket/
```

### Testing SeaweedFS
```bash
# Create a bucket
aws --endpoint-url http://localhost:8333 s3 mb s3://test-bucket

# List buckets
aws --endpoint-url http://localhost:8333 s3 ls
```

---

## Stopping the Services

To stop the containers and keep the data intact:
```bash
docker compose -f minio-compose.yaml down
# or
docker compose -f seaweed-compose.yaml down
```

To stop the containers and wipe all stored data/volumes:
```bash
docker compose -f minio-compose.yaml down -v
# or
docker compose -f seaweed-compose.yaml down -v
```