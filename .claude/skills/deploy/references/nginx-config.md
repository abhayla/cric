# Nginx Reverse Proxy Configuration

Template for CricApp API with WebSocket support.

```nginx
upstream cricapp_api {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name api.yourdomain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    # Cloudflare Origin Certificate (or Let's Encrypt)
    ssl_certificate /etc/nginx/ssl/origin.pem;
    ssl_certificate_key /etc/nginx/ssl/origin-key.pem;

    # API routes
    location /api/ {
        proxy_pass http://cricapp_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket upgrade for match rooms
    location /ws/ {
        proxy_pass http://cricapp_api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400;  # 24 hours for long-lived WS connections
    }

    # Health check (no auth required)
    location /health {
        proxy_pass http://cricapp_api;
    }
}
```

## Notes
- WebSocket `proxy_read_timeout` set to 24h for live match scoring sessions
- Cloudflare handles SSL termination; origin cert for Cloudflare ↔ Nginx
- If using Windows Server, use IIS with URL Rewrite + ARR instead of Nginx
