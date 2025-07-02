
# MinIO with Nginx Proxy and Optional Fail2Ban Protection

This repo provides a Docker Compose setup for running MinIO with:

* **Nginx proxy** for MinIO Console access on port `8803`
* **MinIO object storage** with API access on port `9000` and console on `9001`
* Optional **Fail2Ban integration** to protect MinIO console from brute-force attacks

---

## Features

* MinIO server with persistent data volume
* MinIO Console proxied by Nginx (console available at `http://localhost:8803`)
* Custom Nginx configuration supporting WebSocket proxying and detailed logging
* Environment variable support for MinIO root user and password via `.env`
* Optional Fail2Ban setup for security against unauthorized access attempts
* Scripts for easy install and destroy of the environment

---

## Quick Start

1. **Clone the repo**

   ```bash
   git clone <repo-url>
   cd <repo-directory>
   ```

2. **Create `.env` file**

   If not present, the install script will prompt for MinIO credentials:

   ```
   MINIO_ROOT_USER=minio99
   MINIO_ROOT_PASSWORD=minio123
   ```

3. **Run the installation**

   ```bash
   chmod +x ./bin/install
   ./bin/install [--fail2ban]
   ```

   * `--fail2ban` option enables fail2ban setup for MinIO console protection.
   * This will start all containers in detached mode.

4. **Access MinIO**

   * MinIO API: `http://localhost:9000`
   * MinIO Console (via Nginx): `http://localhost:8803`

5. **Set host nginx proxy and certbot certs**

   ```bash
   ./bin/setproxy
   ```
6. **Stop and clean up**

   ```bash
   ./bin/destroy
   ```

---

## Project Structure

```
.
├── bin
│   ├── destroy      # Script to stop and remove containers and volumes
│   ├── install      # Script to setup env, optionally configure Fail2Ban, and start containers
│   └── setproxy     # Script to setup certificates with certbot and proxy with host level nginx
├── conf
│   ├── entrypoint.sh  # MinIO container entrypoint for readiness check
│   └── nginx.conf     # Nginx configuration proxying MinIO console
├── .env              # User environment variables (credentials)
├── .example.env      # Example environment file
├── .gitignore
├── docker-compose.yml
└── README.md
```

---

## Fail2Ban Integration

* Protects MinIO Console (`port 9001`) by monitoring Nginx access logs.
* Automatically installs and configures fail2ban jail and filter for MinIO.
* Bans IPs after 5 failed login attempts within 5 minutes for 30 minutes.

Use `--fail2ban` flag with `./bin/install` to enable.

---

## Environment Variables

Set in `.env` or exported in the shell:

* `MINIO_ROOT_USER` (default: `minio99`)
* `MINIO_ROOT_PASSWORD` (default: `minio123`)
* `HOST_NAME` (example: `mystorage.mydomain.com`)

---

## Notes

* MinIO data is persisted in Docker volume `minio_data`.
* Nginx logs are saved to volume `nginx_logs`.
* The entrypoint script waits for MinIO to be ready before fully starting.
* Nginx proxies MinIO console traffic and supports WebSockets.

---

## License

This project is licensed under the **MIT License**.
MinIO is used as a containerized service and is licensed under the **GNU AGPL v3**.
See [MinIO License](https://github.com/minio/minio/blob/master/LICENSE) for details.

