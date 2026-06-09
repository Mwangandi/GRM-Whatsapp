# GRM-WhatsApp Quick Reference

## On Your Development Machine

### First Time Setup
```bash
cd /home/pantech-support/Desktop/GRM-whatsapp
chmod +x build.sh
./build.sh build
```

### Development
```bash
cp .env.template .env
nano .env  # Add your Twilio credentials
./build.sh start
```

### Check Status
```bash
./build.sh status
./build.sh logs
```

---

## On Your VPS (server1)

### One-Time Setup
```bash
# SSH into your server
ssh frappe@server1

# Run deployment setup
cd /home/frappe/GRM/GRM-Whatsapp
sudo bash deploy-vps.sh
```

### After Setup: Configure Credentials
```bash
# As frappe user
cp .env.template .env
nano .env  # Add Twilio credentials

# Run build
./build.sh build
```

### Start the Service
```bash
# Option 1: Using build script
./build.sh start

# Option 2: Using systemd (recommended)
sudo systemctl start grm-whatsapp
```

### Check Service Status
```bash
# Option 1: Build script
./build.sh status

# Option 2: Systemd
sudo systemctl status grm-whatsapp

# Option 3: View logs
sudo journalctl -u grm-whatsapp -f
```

### Manage Service
```bash
# Start
sudo systemctl start grm-whatsapp

# Stop
sudo systemctl stop grm-whatsapp

# Restart
sudo systemctl restart grm-whatsapp

# Enable auto-start
sudo systemctl enable grm-whatsapp

# Disable auto-start
sudo systemctl disable grm-whatsapp
```

---

## Testing

### Local Testing
```bash
curl http://127.0.0.1:8090/dashboard
```

### VPS Testing
```bash
# Direct access
curl http://127.0.0.1:8090/dashboard

# Via Apache proxy
curl http://203.161.56.134:8002/dashboard

# Via domain (if configured)
curl http://edatuzen.com/
```

---

## Logs

### Development
```bash
./build.sh logs
```

### VPS - Systemd
```bash
# Live logs
sudo journalctl -u grm-whatsapp -f

# Last 50 lines
sudo journalctl -u grm-whatsapp -n 50

# Today's logs
sudo journalctl -u grm-whatsapp --since today
```

### VPS - Apache
```bash
tail -f /var/log/httpd/mwatate-grm-error.log
tail -f /var/log/httpd/mwatate-grm-access.log
```

---

## Troubleshooting

### Port Already in Use
```bash
# Find what's using the port
lsof -i :8090

# Kill the process
kill -9 <PID>
```

### Permission Denied
```bash
chmod +x build.sh
# Or for service issues:
sudo systemctl restart grm-whatsapp
```

### Cannot Connect to Database
```bash
# Reset database (data will be lost!)
rm grm.db
./build.sh start
```

### Service Won't Start
```bash
# Check what's wrong
sudo systemctl status grm-whatsapp

# Check logs
sudo journalctl -u grm-whatsapp -n 100

# Check configuration
cat /home/frappe/GRM/GRM-Whatsapp/.env
```

---

## Updating

### Pull Latest Changes
```bash
cd /home/frappe/GRM/GRM-Whatsapp
git pull origin main
npm install  # If dependencies changed
sudo systemctl restart grm-whatsapp
```

### Backup Database Before Update
```bash
cp grm.db grm.db.backup.$(date +%Y%m%d_%H%M%S)
```

---

## Architecture

Your setup:

```
User/Browser
    ↓
Apache (port 80/443)
    ↓
Apache Proxy (port 8002)
    ↓
Node.js App (port 8090)
    ↓
SQLite Database (grm.db)
```

- **Incoming**: Browser → Apache (8002) → Node.js (8090)
- **Whatsapp Webhooks**: Twilio → Node.js (8090)
- **Database**: Local SQLite in `grm.db`
- **Logs**: `/var/log/grm-whatsapp/` and Apache logs

---

## Key Files

| File | Purpose |
|------|---------|
| `build.sh` | Build and management script |
| `grm-whatsapp.service` | Systemd service definition |
| `deploy-vps.sh` | VPS setup automation |
| `.env` | Configuration (don't commit) |
| `grm.db` | SQLite database |
| `index.js` | Main application |
| `public/dashboard.html` | Web dashboard |

---

## Contacts & Resources

- **Apache Config**: `/etc/apache2/conf.d/includes/post_virtualhost_global.conf`
- **Systemd Service**: `/etc/systemd/system/grm-whatsapp.service`
- **App Directory**: `/home/frappe/GRM/GRM-Whatsapp`
- **Logs**: `/var/log/grm-whatsapp/` (systemd) or `./logs/` (build script)
- **Database**: `./grm.db` in app directory
