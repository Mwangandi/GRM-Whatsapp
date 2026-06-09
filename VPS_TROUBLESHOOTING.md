# VPS Startup Troubleshooting Guide

## Quick Diagnostics on Your VPS

SSH into your VPS and run this:

```bash
cd /home/frappe/GRM/GRM-Whatsapp

# Make script executable (from local machine first)
chmod +x diagnose-vps.sh

# Run diagnostic
bash diagnose-vps.sh
```

This will show you:
- ✓ Node.js/npm versions
- ✓ Dependencies installed
- ✓ Configuration (.env) status
- ✓ Database status
- ✓ Port availability
- ✓ Error messages from startup attempt
- ✓ Recent logs

---

## Common Startup Issues & Fixes

### 1. Missing Dependencies
**Error**: `Cannot find module 'express'` or `better-sqlite3`

**Fix**:
```bash
cd /home/frappe/GRM/GRM-Whatsapp
npm install
```

### 2. Missing .env Configuration
**Error**: `Missing Twilio credentials`

**Fix**:
```bash
cp .env.template .env
nano .env  # Add your Twilio credentials
```

**Required in .env**:
```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_WHATSAPP_NUMBER=+254XXXXXXXXX
```

### 3. Port Already in Use
**Error**: `bind EADDRINUSE :::8090`

**Fix**:
```bash
# Find what's using port 8090
lsof -i :8090

# Kill the process
pkill -f "node index.js"

# Or force kill by PID
kill -9 <PID>

# Wait a moment, then restart
./build.sh start
```

### 4. Database Corruption
**Error**: `database disk image malformed`

**Fix**:
```bash
# Backup old database
cp grm.db grm.db.backup

# Remove corrupted database
rm grm.db

# App will create new one on startup
./build.sh start
```

### 5. Node Version Issues
**Error**: Compile errors in better-sqlite3

**Check Node version**:
```bash
node -v
# Should be v24.x or compatible version
```

**If old version**:
```bash
# Update Node.js
curl -sL https://deb.nodesource.com/setup_24.x | sudo bash -
sudo apt-get update
sudo apt-get install -y nodejs

# Rebuild dependencies
cd /home/frappe/GRM/GRM-Whatsapp
rm -rf node_modules package-lock.json
npm install
```

### 6. Permission Issues
**Error**: `Permission denied`

**Fix**:
```bash
# Ensure frappe owns the directory
sudo chown -R frappe:frappe /home/frappe/GRM/GRM-Whatsapp

# Ensure scripts are executable
chmod +x /home/frappe/GRM/GRM-Whatsapp/build.sh
chmod +x /home/frappe/GRM/GRM-Whatsapp/git.sh
```

---

## Step-by-Step VPS Troubleshooting

### Step 1: Check Status
```bash
sudo systemctl status grm-whatsapp
```

### Step 2: View Recent Logs
```bash
sudo journalctl -u grm-whatsapp -n 50
```

### Step 3: Stop Service
```bash
sudo systemctl stop grm-whatsapp
```

### Step 4: Run Diagnostic
```bash
cd /home/frappe/GRM/GRM-Whatsapp
bash diagnose-vps.sh
```

### Step 5: Try Manual Start (for better error messages)
```bash
cd /home/frappe/GRM/GRM-Whatsapp
NODE_ENV=production PORT=8090 node index.js
```

This will show the ACTUAL error message (instead of "Failed to start application")

### Step 6: Fix Based on Error
Look at the error message from Step 5 and apply the appropriate fix above.

### Step 7: Restart Service
```bash
sudo systemctl start grm-whatsapp
sudo systemctl status grm-whatsapp
```

---

## Verify It's Working

### Check Service Status
```bash
sudo systemctl status grm-whatsapp
```

### Check Logs
```bash
sudo journalctl -u grm-whatsapp -f  # Live logs
```

### Test Health Endpoint
```bash
curl http://127.0.0.1:8090/health
```

Should return:
```json
{"status":"ok","timestamp":"...","service":"GRM WhatsApp Bot"}
```

### Test via Apache Proxy
```bash
curl http://203.161.56.134:8002/health
```

---

## Helpful Commands

```bash
# SSH into VPS
ssh frappe@server1

# Go to project
cd /home/frappe/GRM/GRM-Whatsapp

# View logs
tail -50 logs/grm-whatsapp.log

# Check port
lsof -i :8090

# Check processes
ps aux | grep node

# Restart everything
./build.sh stop
./build.sh start

# Or with systemd
sudo systemctl restart grm-whatsapp
```

---

## Full Reset (if everything is broken)

```bash
cd /home/frappe/GRM/GRM-Whatsapp

# Stop service
sudo systemctl stop grm-whatsapp

# Clean everything
rm -rf node_modules package-lock.json logs/*

# Pull latest from GitHub
git pull origin master

# Reinstall
npm install

# Rebuild
./build.sh build

# Restart
sudo systemctl start grm-whatsapp

# Check status
sudo systemctl status grm-whatsapp
```

---

## Send Error Details

If you're still stuck, SSH into the VPS and run this to get detailed error info:

```bash
cd /home/frappe/GRM/GRM-Whatsapp
NODE_ENV=production PORT=8090 timeout 10 node index.js 2>&1 | tee error.log
cat error.log
```

Copy the output and share it so I can see the EXACT error.
