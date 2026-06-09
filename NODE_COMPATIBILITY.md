# Node.js Compatibility Fix - better-sqlite3

## Problem
`better-sqlite3` v9.x is incompatible with Node.js v24.x

**Error**: V8 API compile errors (no member named 'row', 'value', etc.)

## Solution
Upgrade `better-sqlite3` to v11.x which supports Node.js 24.x

---

## On Your Development Machine

### Local Testing (Recommended First)
```bash
cd /home/pantech-support/Desktop/GRM-whatsapp

# Clear old installation
rm -rf node_modules package-lock.json

# Install with new version
npm install

# Test if it works
npm start
```

### Push to GitHub
```bash
./git.sh acp . "Upgrade better-sqlite3 to v11 for Node.js 24 compatibility"
./git.sh push
```

---

## On Your VPS Server

### Fix the VPS Installation
```bash
cd /home/frappe/GRM/GRM-Whatsapp

# Stop the service
sudo systemctl stop grm-whatsapp

# Remove old dependencies
rm -rf node_modules package-lock.json

# Pull latest changes from GitHub
git pull origin master

# Install updated dependencies
npm install

# Rebuild the app
./build.sh build

# Start the service
sudo systemctl start grm-whatsapp

# Verify it's running
sudo systemctl status grm-whatsapp
```

---

## What Changed

| Aspect | Old | New |
|--------|-----|-----|
| better-sqlite3 | 9.2.2 | 11.x |
| Node.js | ≥18.0.0 | ≥18.0.0 (supports 24.x) |
| Compatibility | Node 18, 20, 22 | Node 18, 20, 22, 24 |

---

## Verification

### Check Version
```bash
npm list better-sqlite3
```

Should show: `better-sqlite3@11.x.x` or similar

### Check if App Starts
```bash
npm start
# Should show:
# ✓ GRM WhatsApp Bot starting...
# 🚀 Server running on port 8090
```

### Check Logs (if using systemd)
```bash
sudo journalctl -u grm-whatsapp -n 20
```

---

## Troubleshooting

### Still Getting Compile Errors?
```bash
# Clear npm cache
npm cache clean --force

# Remove node_modules and lock file
rm -rf node_modules package-lock.json

# Reinstall
npm install
```

### Port Already in Use?
```bash
# Kill existing process
pkill -f "node index.js"

# Or force-kill
lsof -ti:8090 | xargs kill -9

# Restart
npm start
```

### npm install is Very Slow?
This is normal for `better-sqlite3` as it compiles C++ code. Wait for it to complete. It may take 2-5 minutes.

---

## Version History

- **v9.2.2** - Old version (Node 18-20 only)
- **v11.0.0+** - New version (Node 18-24+)
- **v12.x** - Latest (if v11 has issues)

If v11.x still has issues, try v12.x:
```bash
npm install better-sqlite3@^12.0.0
npm install  # Reinstall everything
```

---

## Notes

✅ This update is safe - no code changes needed  
✅ API compatibility is maintained  
✅ Database migration is NOT required  
✅ Your grm.db file will work as-is  

Just install and run!
