# GRM-WhatsApp Deployment Guide

## Quick Start

### 1. Initial Build and Setup

```bash
cd /home/frappe/GRM/GRM-Whatsapp
chmod +x build.sh
./build.sh build
```

This will:
- Check Node.js installation
- Create log directories
- Generate `.env.template`
- Install npm dependencies
- Verify the database

### 2. Configure Environment

```bash
cp .env.template .env
nano .env
```

Required configuration:
```env
PORT=8090
NODE_ENV=production
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=your_whatsapp_number
DATABASE_PATH=./grm.db
API_URL=https://edatuzen.com
```

### 3. Start the Application

**Option A: Using the build script**
```bash
./build.sh start
```

**Option B: Using systemd (recommended for production)**

```bash
# Copy the service file
sudo cp grm-whatsapp.service /etc/systemd/system/

# Create log directory
sudo mkdir -p /var/log/grm-whatsapp
sudo chown frappe:frappe /var/log/grm-whatsapp

# Reload systemd
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable grm-whatsapp
sudo systemctl start grm-whatsapp
```

## Build Script Commands

### Full Build Setup
```bash
./build.sh build
```
Runs: dependency installation, environment setup, database verification

### Start the Application
```bash
./build.sh start
```
Starts the Node.js service on port 8090, runs as background process

### Stop the Application
```bash
./build.sh stop
```
Gracefully stops the running service

### Restart the Application
```bash
./build.sh restart
```
Stops and restarts the service

### Check Status
```bash
./build.sh status
```
Shows if the application is running and listening on port 8090

### View Logs
```bash
./build.sh logs
```
Displays the last 50 lines of application logs

## Managing with Systemd (Recommended)

### Start Service
```bash
sudo systemctl start grm-whatsapp
```

### Stop Service
```bash
sudo systemctl stop grm-whatsapp
```

### Restart Service
```bash
sudo systemctl restart grm-whatsapp
```

### Check Status
```bash
sudo systemctl status grm-whatsapp
```

### View Logs
```bash
sudo journalctl -u grm-whatsapp -f
```

### Enable Auto-Start on Boot
```bash
sudo systemctl enable grm-whatsapp
```

### Disable Auto-Start
```bash
sudo systemctl disable grm-whatsapp
```

## Apache Configuration

Your Apache config at `/etc/apache2/conf.d/includes/post_virtualhost_global.conf` already has:

```apache
# Mwatate Municipality GRM
Listen 8002
<VirtualHost 203.161.56.134:8002>
    ServerName 203.161.56.134
    ProxyPreserveHost On
    ProxyRequests Off
    <Location />
        ProxyPass       http://127.0.0.1:8090/
        ProxyPassReverse http://127.0.0.1:8090/
    </Location>
    ErrorLog /var/log/httpd/mwatate-grm-error.log
    CustomLog /var/log/httpd/mwatate-grm-access.log combined
</VirtualHost>
```

This proxies requests from Apache port 8002 to your Node.js app on port 8090.

### Access Points
- **Internal**: `http://127.0.0.1:8090/`
- **Via Apache**: `http://203.161.56.134:8002/`
- **Dashboard**: `http://203.161.56.134:8002/dashboard`

## Troubleshooting

### Application won't start
```bash
# Check if port is already in use
lsof -i :8090

# Check logs
./build.sh logs

# Check .env configuration
cat .env
```

### Port already in use
```bash
# Kill the process using the port
lsof -ti:8090 | xargs kill -9

# Or use different port
PORT=8091 ./build.sh start
```

### Permission issues
```bash
# Ensure frappe user owns the directory
sudo chown -R frappe:frappe /home/frappe/GRM/GRM-Whatsapp

# Ensure execute permission on build script
chmod +x build.sh
```

### Database issues
```bash
# Remove old database if corrupted
rm grm.db

# Application will recreate it on next start
./build.sh start
```

### Check if service is running correctly
```bash
# Via systemd
sudo systemctl status grm-whatsapp

# Check port
sudo netstat -tulpn | grep 8090

# Check process
ps aux | grep "node index.js"
```

## Deployment Checklist

- [ ] Clone repository into `/home/frappe/GRM/GRM-Whatsapp`
- [ ] Run `./build.sh build`
- [ ] Configure `.env` with Twilio credentials
- [ ] Test with `./build.sh start`
- [ ] Verify logs: `./build.sh logs`
- [ ] Copy `grm-whatsapp.service` to `/etc/systemd/system/`
- [ ] Create log directory: `sudo mkdir -p /var/log/grm-whatsapp`
- [ ] Enable service: `sudo systemctl enable grm-whatsapp`
- [ ] Start service: `sudo systemctl start grm-whatsapp`
- [ ] Verify service: `sudo systemctl status grm-whatsapp`
- [ ] Test dashboard: `curl http://127.0.0.1:8090/dashboard`
- [ ] Verify Apache proxy: `curl http://203.161.56.134:8002/dashboard`

## Performance Monitoring

### Monitor in Real-time
```bash
# Watch logs live
sudo journalctl -u grm-whatsapp -f

# Or using build script
watch -n 5 './build.sh status'
```

### Resource Usage
```bash
# Check memory/CPU
ps aux | grep "node index.js"

# Check open files
lsof -p $(pgrep -f "node index.js")
```

### Apache Logs
```bash
# GRM specific logs
tail -f /var/log/httpd/mwatate-grm-error.log
tail -f /var/log/httpd/mwatate-grm-access.log
```

## Updating the Application

```bash
# Stop the service
./build.sh stop

# Pull latest changes
git pull origin main

# Reinstall dependencies if needed
npm install

# Start the service
./build.sh start

# Or with systemd
sudo systemctl restart grm-whatsapp
```

## Security Notes

1. **Environment Variables**: Keep `.env` file secure and don't commit to git
2. **Logs**: Check logs regularly for errors
3. **Firewall**: Only port 8002 (via Apache) should be externally accessible
4. **Updates**: Keep Node.js and dependencies updated
5. **Database**: Backup `grm.db` regularly

```bash
# Backup database
cp grm.db grm.db.backup.$(date +%Y%m%d)
```
