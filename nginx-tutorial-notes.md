# NGINX Complete Tutorial Notes

## Table of Contents
1. [Introduction](#introduction)
2. [What is NGINX?](#what-is-nginx)
3. [NGINX Core Features](#nginx-core-features)
4. [NGINX Configuration](#nginx-configuration)
5. [Demo Project Walkthrough](#demo-project-walkthrough)
6. [NGINX vs Apache](#nginx-vs-apache)
7. [Kubernetes Integration](#kubernetes-integration)
8. [Configuration Examples](#configuration-examples)
9. [Best Practices](#best-practices)

## Introduction

NGINX is a powerful, high-performance web server and reverse proxy server that has become one of the most popular solutions for handling web traffic. This tutorial covers everything from basic web server setup to advanced reverse proxy configuration with SSL/TLS encryption.

## What is NGINX?

### Historical Context

**Early Web Days:**
- Browser → Single Web Server
- Simple request-response model
- Limited traffic handling capability

**Modern Web Requirements:**
- Millions of requests per website
- Need for multiple servers
- Load distribution requirements
- Security concerns
- Performance optimization

### NGINX Evolution

NGINX started as a web server but evolved into a multi-purpose tool:

1. **Web Server** - Serves static files (HTML, CSS, JS, images)
2. **Reverse Proxy** - Acts as intermediary between clients and backend servers
3. **Load Balancer** - Distributes requests across multiple servers
4. **API Gateway** - Handles API routing and management

## NGINX Core Features

### 1. Load Balancing

**Purpose:** Distribute incoming requests across multiple backend servers

**Benefits:**
- Prevents server overload
- Improves response times
- Provides redundancy
- Scales horizontally

**Real-world Example:** Netflix uses NGINX to handle millions of video streaming requests by distributing them across multiple backend servers.

### 2. Caching

**Purpose:** Store frequently requested content to reduce backend load

**Example Scenario:**
- New York Times article gets millions of views
- Instead of assembling the article from database every time
- NGINX caches the final HTML and serves it directly

**Benefits:**
- Faster response times
- Reduced database load
- Lower bandwidth usage

### 3. Security Layer

**Purpose:** Act as a shield between public internet and backend servers

**Security Features:**
- SSL/TLS termination
- Request filtering
- Rate limiting
- DDoS protection

**Real-world Example:**
- Instead of exposing 100 backend servers to the internet
- Only NGINX proxy is publicly accessible
- Reduces attack surface significantly

### 4. SSL/TLS Encryption

**Purpose:** Encrypt communication between clients and server

**Configuration:**
- SSL certificate management
- HTTPS enforcement
- HTTP to HTTPS redirection

### 5. Compression

**Purpose:** Reduce bandwidth usage and improve load times

**Example:**
- Large video files or images compressed before transmission
- Chunked transfer for streaming content
- Gzip compression for text content

## NGINX Configuration

### Configuration Structure

NGINX configuration uses **directives** (key-value pairs) organized in **contexts** (blocks).

### Basic Configuration Elements

```nginx
# Global context
worker_processes 1;

# Events context
events {
    worker_connections 1024;
}

# HTTP context
http {
    # Server context
    server {
        listen 80;
        server_name example.com;
        
        # Location context
        location / {
            # Directives
        }
    }
}
```

### Key Directives Explained

**worker_processes:** Number of worker processes to handle requests
- `1` - Single process (development)
- `auto` - Automatic based on CPU cores (recommended for production)

**worker_connections:** Maximum simultaneous connections per worker process
- Higher values = more concurrent connections
- Higher values = more memory usage

## Demo Project Walkthrough

### Project Overview

**Goal:** Create a Node.js application with NGINX reverse proxy and load balancing

### Step 1: Simple Web Application

**Files Created:**
- `index.html` - Static webpage with images
- `server.js` - Node.js Express server
- `package.json` - Dependencies configuration

**server.js Example:**
```javascript
const express = require('express');
const app = express();
const port = 3000;

// Serve static files
app.use(express.static('.'));

app.get('/', (req, res) => {
    console.log(`Request served by ${process.env.APP_NAME || 'node app'}`);
    res.sendFile(__dirname + '/index.html');
});

app.listen(port, () => {
    console.log(`${process.env.APP_NAME || 'Node app'} is listening on port ${port}`);
});
```

### Step 2: Dockerization

**Dockerfile:**
```dockerfile
FROM node:alpine
WORKDIR /app
COPY server.js .
COPY index.html .
COPY images/ images/
COPY package.json .
RUN npm install
EXPOSE 3000
CMD ["node", "server.js"]
```

### Step 3: Multiple Instances with Docker Compose

**docker-compose.yml:**
```yaml
version: '3'
services:
  app1:
    build: .
    ports:
      - "3001:3000"
    environment:
      - APP_NAME=app1
  
  app2:
    build: .
    ports:
      - "3002:3000"
    environment:
      - APP_NAME=app2
  
  app3:
    build: .
    ports:
      - "3003:3000"
    environment:
      - APP_NAME=app3
```

**Commands:**
```bash
# Build and start all containers
docker-compose up --build -d

# Check running containers
docker ps

# View logs
docker-compose logs app1
```

### Step 4: NGINX Installation and Configuration

**Installation (macOS):**
```bash
brew install nginx
```

**Installation (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install nginx
```

**Find Configuration File:**
```bash
nginx -V 2>&1 | grep -o '\-\-conf-path=\S*'
# or
whereis nginx
```

### Step 5: NGINX Reverse Proxy Configuration

**Complete nginx.conf:**
```nginx
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    include mime.types;
    
    upstream nodejs_cluster {
        # Load balancing algorithm (optional)
        least_conn;
        
        server 127.0.0.1:3001;
        server 127.0.0.1:3002;
        server 127.0.0.1:3003;
    }
    
    server {
        listen 8080;
        server_name localhost;
        
        location / {
            proxy_pass http://nodejs_cluster;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

**Start NGINX:**
```bash
# Start NGINX
nginx

# Test configuration
nginx -t

# Reload configuration
nginx -s reload

# Stop NGINX
nginx -s stop
```

### Step 6: HTTPS Configuration

**Generate Self-signed Certificate:**
```bash
# Create directory for certificates
mkdir /usr/local/etc/nginx/ssl

# Generate private key and certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /usr/local/etc/nginx/ssl/nginx.key \
  -out /usr/local/etc/nginx/ssl/nginx.crt
```

**HTTPS Server Configuration:**
```nginx
http {
    # ... upstream configuration ...
    
    # HTTP to HTTPS redirect
    server {
        listen 80;
        server_name localhost;
        return 301 https://$server_name$request_uri;
    }
    
    # HTTPS server
    server {
        listen 443 ssl;
        server_name localhost;
        
        ssl_certificate /usr/local/etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /usr/local/etc/nginx/ssl/nginx.key;
        
        location / {
            proxy_pass http://nodejs_cluster;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

## NGINX vs Apache

### Performance Comparison

| Feature | NGINX | Apache |
|---------|--------|--------|
| **Architecture** | Event-driven, asynchronous | Process/thread-based |
| **Memory Usage** | Lower | Higher |
| **Static File Serving** | Faster | Slower |
| **Configuration** | Simple, readable | More complex |
| **Modules** | Built-in modules | Dynamic module loading |
| **Market Share** | Growing rapidly | Historically dominant |

### When to Choose NGINX

**NGINX is better for:**
- High-traffic websites
- Serving static content
- Reverse proxy setups
- Microservices architectures
- Container environments

**Apache is better for:**
- .htaccess file requirements
- Shared hosting environments
- Complex mod_rewrite rules
- Legacy applications

## Kubernetes Integration

### NGINX Ingress Controller

NGINX can act as an Ingress Controller in Kubernetes:

**Benefits:**
- Advanced load balancing for K8s services
- SSL termination
- Path-based routing
- Host-based routing

**Architecture:**
```
Internet → Cloud Load Balancer → NGINX Ingress Controller → K8s Services → Pods
```

**Example Ingress Configuration:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

## Configuration Examples

### 1. Basic Web Server

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, no-transform";
    }
}
```

### 2. Reverse Proxy with Caching

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=10g 
                 inactive=60m use_temp_path=off;

server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_cache my_cache;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid 404 1m;
        
        proxy_pass http://backend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 3. Load Balancing Algorithms

```nginx
# Round Robin (default)
upstream backend_round_robin {
    server backend1.example.com;
    server backend2.example.com;
    server backend3.example.com;
}

# Least Connections
upstream backend_least_conn {
    least_conn;
    server backend1.example.com;
    server backend2.example.com;
    server backend3.example.com;
}

# Weighted Round Robin
upstream backend_weighted {
    server backend1.example.com weight=3;
    server backend2.example.com weight=2;
    server backend3.example.com weight=1;
}

# IP Hash (sticky sessions)
upstream backend_ip_hash {
    ip_hash;
    server backend1.example.com;
    server backend2.example.com;
    server backend3.example.com;
}
```

### 4. Security Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name secure.example.com;
    
    # SSL Configuration
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:DHE+CHACHA20:!aNULL:!MD5:!DSS;
    
    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://api_servers;
    }
}
```

## Best Practices

### 1. Performance Optimization

```nginx
# Optimize worker processes
worker_processes auto;
worker_connections 1024;

# Enable gzip compression
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

# Enable HTTP/2
listen 443 ssl http2;
```

### 2. Security Best Practices

- Always use HTTPS in production
- Implement rate limiting
- Hide NGINX version: `server_tokens off;`
- Use security headers
- Regular security updates

### 3. Monitoring and Logging

```nginx
# Custom log format
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                '$status $body_bytes_sent "$http_referer" '
                '"$http_user_agent" "$http_x_forwarded_for"';

access_log /var/log/nginx/access.log main;
error_log /var/log/nginx/error.log warn;

# Status monitoring
location /nginx_status {
    stub_status on;
    allow 127.0.0.1;
    deny all;
}
```

### 4. Common Commands

```bash
# Test configuration
nginx -t

# Reload configuration (zero downtime)
nginx -s reload

# Check configuration syntax
nginx -T

# View running processes
ps aux | grep nginx

# Check listening ports
netstat -tlnp | grep nginx
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Check file permissions
   - Verify NGINX user has access to files

2. **Port Already in Use**
   - Check for other services using the port
   - Kill conflicting processes

3. **SSL Certificate Issues**
   - Verify certificate and key files exist
   - Check certificate validity

4. **502 Bad Gateway**
   - Backend servers not running
   - Incorrect upstream configuration
   - Network connectivity issues

### Useful Commands

```bash
# Check NGINX status
systemctl status nginx

# View error logs
tail -f /var/log/nginx/error.log

# Test upstream connectivity
curl -I http://backend-server:port

# Check configuration file location
nginx -V 2>&1 | grep -o '\-\-conf-path=\S*'
```

## Conclusion

NGINX is a powerful and versatile web server that excels as a reverse proxy and load balancer. Its event-driven architecture makes it highly efficient for handling concurrent connections, while its flexible configuration system allows for complex routing and security setups.

Key takeaways:
- NGINX can serve multiple roles: web server, reverse proxy, load balancer
- Configuration is straightforward with directives and contexts
- Essential for modern web applications requiring scalability and security
- Perfect for microservices architectures and container environments
- Integrates well with Kubernetes as an Ingress Controller

The demo project showed how to progress from a simple Node.js application to a fully configured NGINX reverse proxy with SSL/TLS encryption, demonstrating real-world implementation patterns that are widely used in production environments.

---

*Note: This tutorial is based on the comprehensive NGINX crash course by TechWorld with Nana. For the complete hands-on experience, refer to the original video and associated GitLab repository.*