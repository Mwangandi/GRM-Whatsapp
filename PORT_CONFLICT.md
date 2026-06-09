# Port 8090 Already in Use - Solutions

## Option 1: Use a Different Port for GRM-WhatsApp (Recommended)

### Change GRM-WhatsApp to Use Port 8091

**On your VPS:**

```bash
# Edit the .env file
nano /home/frappe/GRM/GRM-Whatsapp/.env

# Change PORT from 8090 to 8091
PORT=8091
```

**Update Apache proxy to point to 8091:**

```bash
# SSH as root or with sudo
sudo nano /etc/apache2/conf.d/includes/post_virtualhost_global.conf

# Find the Mwatate Municipality GRM section and change:
# FROM:
ProxyPass       http://127.0.0.1:8090/
ProxyPassReverse http://127.0.0.1:8090/

# TO:
ProxyPass       http://127.0.0.1:8091/
ProxyPassReverse http://127.0.0.1:8091/
```

**Restart services:**

```bash
# Restart GRM-WhatsApp
sudo systemctl restart grm-whatsapp

# Reload Apache
sudo systemctl reload apache2

# Verify
curl http://127.0.0.1:8091/health
curl http://203.161.56.134:8002/health
```

---

## Option 2: Stop the Other Project

If the other project on 8090 is not needed:

```bash
# Find what's using port 8090
lsof -i :8090

# Stop it (if it's a systemd service)
sudo systemctl stop <service-name>

# Or kill the process
kill -9 <PID>

# Now restart GRM-WhatsApp
sudo systemctl restart grm-whatsapp
```

---

## Option 3: Run Both on Different Ports

Keep both projects running but on different ports:

- **GRM-WhatsApp**: Port 8091 (via Apache port 8002)
- **Other Project**: Port 8090 (keep as is)

Then update Apache configuration as shown in Option 1.

---

## What's Using Port 8090?

Run this on VPS to find out:

```bash
lsof -i :8090
# or
netstat -tulpn | grep 8090
# or
ss -tulpn | grep 8090
```

---

## Recommended Approach

1. Check what's on port 8090
2. If it's important: Use Option 1 (change GRM to 8091)
3. If not needed: Use Option 2 (stop the other project)
4. Update Apache accordingly

The Apache proxy (port 8002) will still work either way - it just proxies to whichever port you choose.
