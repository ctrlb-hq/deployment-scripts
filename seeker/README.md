# CtrlB Seeker Service Deployment Script

A comprehensive, production-ready shell script for deploying the CtrlB Seeker binary as a systemd service on Linux systems with automatic backup, safe upgrades, and robust error handling.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration Files](#configuration-files)
- [Service Management](#service-management)
- [Upgrade & Updates](#upgrade--updates)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Uninstallation](#uninstallation)
- [Examples](#examples)

## 🎯 Overview

This deployment script automates the installation and management of the Seeker binary as a systemd service. It provides a safe, idempotent deployment process with automatic backups and rollback capabilities.

## ✨ Features

### Core Functionality
- ✅ **Automated Installation** - One-command deployment with validation
- ✅ **Service User Management** - Creates dedicated `ctrlb` system user
- ✅ **Directory Structure** - Sets up organized file hierarchy
- ✅ **Binary Deployment** - Installs and manages executable
- ✅ **Configuration Management** - Handles .env and cryptographic keys
- ✅ **Systemd Integration** - Full service lifecycle management

### Safety & Reliability
- 🛡️ **Automatic Backups** - Timestamped backups before any overwrites
- 🛡️ **Safe Upgrades** - Stops service before binary replacement
- 🛡️ **Flexible Config Modes** - Skip, overwrite, or backup existing configs
- 🛡️ **Error Handling** - Robust error checking and validation
- 🛡️ **Idempotent Operations** - Safe to run multiple times

### Security
- 🔒 **Non-root Execution** - Service runs as dedicated user
- 🔒 **Secure Permissions** - Proper file and directory permissions
- 🔒 **Private Key Protection** - 600 permissions on sensitive files
- 🔒 **No Shell Access** - Service user has no login capability

## 📦 Prerequisites

### System Requirements

- **Operating System**: Linux with systemd (Ubuntu, Debian, CentOS, RHEL, etc.)
- **Privileges**: Root access (sudo)
- **Dependencies**: 
  - `systemctl` (systemd)
  - `useradd` (user management)
  - `getent` (user verification)

### Required Files

Before running the script, ensure you have these files in the same directory:

```
deploy-seeker/
├── deploy-seeker.sh       # Deployment script (required)
├── seeker                 # The seeker binary (required)
├── ctrlb-seeker.service   # Systemd service file (required)
├── .env                   # Environment configuration (optional)
├── .env.example           # Example configuration template
├── keys/
│   ├── public.key         # Public key (optional)
│   └── private.key        # Private key (optional)
└── README.md              # This documentation
```

**Note:** Copy `.env.example` to `.env` and customize with your values before installation.

## 📁 Project Structure

After installation, the following structure is created:

```
/opt/ctrlb/seeker/                    # Service working directory
├── ctrlb-seeker                      # Installed binary
├── .env                              # Environment variables (if provided)
├── keys/
│   ├── public.key                    # Public key (if provided)
│   └── private.key                   # Private key (if provided)
└── *.backup.YYYYMMDD_HHMMSS          # Automatic backups (timestamped)

/var/log/ctrlb/                       # Log directory (systemd journal)

/etc/systemd/system/
└── ctrlb-seeker.service              # Systemd service file
```

### Backup Files

When updating existing installations, backups are automatically created:

```
/opt/ctrlb/seeker/
├── ctrlb-seeker.backup.20251003_143022
├── .env.backup.20251003_143022
└── keys/
    └── private.key.backup.20251003_143022
```

## 🚀 Quick Start

### First Time Installation

```bash
# 1. Navigate to deployment directory
cd /path/to/deploy-seeker

# 2. Configure environment variables
cp .env.example .env
nano .env  # Edit with your values

# 3. Make script executable
chmod +x deploy-seeker.sh

# 4. Install and start the service
sudo ./deploy-seeker.sh install-enable

# 5. Verify it's running
sudo ./deploy-seeker.sh status
```

## 📥 Installation

### Step-by-Step Installation

1. **Prepare Configuration Files**

   Copy the example environment file and customize:
   ```bash
   cp .env.example .env
   ```

   Edit `.env` with your configuration:
   ```bash
   nano .env
   ```

   Essential variables to configure:
   ```bash
   CTRLB_API_URL=https://api.ctrlb.io
   CTRLB_API_KEY=your_api_key_here
   SEEKER_NODE_ID=node-01
   SEEKER_REGION=us-east-1
   LOG_LEVEL=info
   ```

2. **Prepare Cryptographic Keys** (Optional)

   If using key-based authentication:
   ```bash
   mkdir -p keys
   cp /path/to/your/public.key keys/
   cp /path/to/your/private.key keys/
   chmod 600 keys/private.key
   ```

3. **Make Script Executable**
   ```bash
   chmod +x deploy-seeker.sh
   ```

4. **Run Installation**

   Choose one of two installation modes:

   **Option A: Install only (service set up but not started)**
   ```bash
   sudo ./deploy-seeker.sh install
   ```

   **Option B: Install and enable (service set up and started)**
   ```bash
   sudo ./deploy-seeker.sh install-enable
   ```

   Both commands will:
   - ✓ Validate prerequisites
   - ✓ Create service user (`ctrlb`)
   - ✓ Create directory structure
   - ✓ Stop existing service (if running)
   - ✓ Install binary with backup
   - ✓ Deploy configuration files
   - ✓ Install systemd service

   The `install-enable` command additionally:
   - ✓ Enable and start service

### Verification

Check if the service is running:
```bash
sudo ./deploy-seeker.sh status
```

Or use systemctl directly:
```bash
sudo systemctl status ctrlb-seeker
```

Expected output:
```
● ctrlb-seeker.service - CtrlB Seeker Service
     Loaded: loaded (/etc/systemd/system/ctrlb-seeker.service; enabled)
     Active: active (running) since ...
```

## 📖 Usage

### Available Commands

```bash
sudo ./deploy-seeker.sh [OPTIONS] <command>
```

| Command | Description |
|---------|-------------|
| `install` | Install binary and setup service (don't start) |
| `install-enable` | Install binary, setup service, and enable/start it |
| `install-binary` | Update only the binary (with backup) |
| `install-config` | Update only configuration files (.env, keys) |
| `start` | Start the ctrlb-seeker service |
| `stop` | Stop the ctrlb-seeker service |
| `restart` | Restart the ctrlb-seeker service |
| `status` | Show service status and recent logs |
| `uninstall` | Remove the service (preserves user and directories) |
| `help` | Display help message |

### When to Use Each Install Command

**Use `install` when:**
- 🔧 You want to set up the service but configure it before starting
- 🔧 You're deploying to multiple servers and want to start them together
- 🔧 You need to verify configuration before the service starts
- 🔧 You're doing a maintenance deployment during scheduled downtime

**Use `install-enable` when:**
- 🚀 You want immediate deployment and startup (most common)
- 🚀 You're confident in your configuration
- 🚀 You want the service running right after installation
- 🚀 You're doing a fresh installation or update

**Use `install-binary` when:**
- ⚡ You only need to update the executable (new version)
- ⚡ Configuration and service setup are already correct
- ⚡ You want the fastest possible update (binary only)
- ⚡ You're doing frequent binary updates during development

### Available Options

| Option | Values | Description |
|--------|--------|-------------|
| `--force=MODE` | `skip`, `overwrite`, `backup` | Config file handling mode (default: `skip`) |
| `-f MODE` | `skip`, `overwrite`, `backup` | Short form of --force |
| `--help`, `-h` | - | Display help message |

### Common Operations

**Install the service (without starting):**
```bash
sudo ./deploy-seeker.sh install
```

**Install and start the service immediately:**
```bash
sudo ./deploy-seeker.sh install-enable
```

**Update only the binary (creates automatic backup):**
```bash
sudo ./deploy-seeker.sh install-binary
sudo ./deploy-seeker.sh restart
```

**Update configuration without reinstalling:**
```bash
sudo ./deploy-seeker.sh install-config
sudo ./deploy-seeker.sh restart
```

**Check service status:**
```bash
sudo ./deploy-seeker.sh status
```

**View live logs:**
```bash
sudo journalctl -u ctrlb-seeker -f
```

**Restart the service:**
```bash
sudo ./deploy-seeker.sh restart
```

## ⚙️ Configuration Files

### 1. Environment File (`.env`)

The `.env` file contains environment variables for your seeker instance. Start with the provided example:

```bash
# Copy the example file
cp .env.example .env

# Edit with your values
nano .env
```

**Essential Variables:**

| Variable | Description | Example |
|----------|-------------|---------|
| `CTRLB_API_URL` | CtrlB API endpoint | `https://api.ctrlb.io` |
| `CTRLB_API_KEY` | Authentication key | `sk_live_abc123...` |
| `SEEKER_NODE_ID` | Unique node identifier | `prod-node-01` |
| `SEEKER_REGION` | Deployment region | `us-east-1` |
| `LOG_LEVEL` | Logging verbosity | `info`, `debug`, `warn` |

See `.env.example` for complete list of available configuration options.

**Security:**
- **Permissions:** `600` (owner read/write only)
- **Never commit** `.env` to version control
- **Rotate credentials** regularly

### 2. Public Key (`keys/public.key`)

Your public key file for cryptographic operations and signature verification.

**Location:** `keys/public.key` (relative to script directory)  
**Permissions:** `644` (owner read/write, others read)

### 3. Private Key (`keys/private.key`)

Your private key file for signing and encryption operations.

**Location:** `keys/private.key` (relative to script directory)  
**Permissions:** `600` (owner read/write only - **highly sensitive**)

**⚠️ Security Warning:**
- Never share or commit private keys to version control
- Store backups in secure, encrypted storage
- Rotate keys periodically according to your security policy

### Configuration File Handling

When updating configuration files, you can control how existing files are handled using the `--force` flag.

#### **Modes:**

| Mode | Behavior | Use Case |
|------|----------|----------|
| **`skip`** (default) | Leaves existing files unchanged | Safe production updates, preserve running config |
| **`backup`** | Creates timestamped backup before replacing | Update configs with safety net |
| **`overwrite`** | Replaces without creating backup | Force update, no backup needed |

#### **Examples:**

```bash
# Default: Skip existing files (safest for production)
sudo ./deploy-seeker.sh install-config

# Backup before replacing (recommended for updates)
sudo ./deploy-seeker.sh --force=backup install-config

# Overwrite without backup (use with caution!)
sudo ./deploy-seeker.sh --force=overwrite install-config

# Short form syntax
sudo ./deploy-seeker.sh -f backup install-config

# Works with both install commands too
sudo ./deploy-seeker.sh --force=skip install
sudo ./deploy-seeker.sh --force=skip install-enable
```

#### **Backup Files:**

When using `backup` mode, backups are created with timestamp suffix:

```bash
# Example backup files
/opt/ctrlb/seeker/.env.backup.20251003_143022
/opt/ctrlb/seeker/keys/private.key.backup.20251003_143022
/opt/ctrlb/seeker/keys/public.key.backup.20251003_143022
```

#### **Configuration Update Workflow:**

1. **Edit local config files:**
   ```bash
   nano .env
   # or update keys in keys/ directory
   ```

2. **Deploy configuration updates:**
   ```bash
   sudo ./deploy-seeker.sh --force=backup install-config
   ```

3. **Restart service to apply:**
   ```bash
   sudo ./deploy-seeker.sh restart
   ```

4. **Verify changes:**
   ```bash
   sudo ./deploy-seeker.sh status
   ```

## � Upgrade & Updates

### Upgrading the Binary

When a new version of the seeker binary is available:

1. **Replace local binary:**
   ```bash
   # Backup your current deployment directory first
   cp seeker seeker.old
   
   # Download or copy new binary
   cp /path/to/new/seeker .
   chmod +x seeker
   ```

2. **Run installation (automatic backup & service stop):**
   ```bash
   sudo ./deploy-seeker.sh install
   ```

   The script automatically:
   - ✓ Stops the running service
   - ✓ Backs up the old binary with timestamp
   - ✓ Installs the new binary
   - ✓ Restarts the service

3. **Verify upgrade:**
   ```bash
   sudo ./deploy-seeker.sh status
   ```

### Updating Configuration Only

To update `.env` or key files without touching the binary:

```bash
# Edit configuration
nano .env

# Deploy config only
sudo ./deploy-seeker.sh --force=backup install-config

# Restart to apply
sudo ./deploy-seeker.sh restart
```

### Rollback

If the new version has issues, rollback to the previous binary:

```bash
# Stop the service
sudo ./deploy-seeker.sh stop

# Find the backup (list backups by timestamp)
ls -la /opt/ctrlb/seeker/*.backup.*

# Restore from backup
sudo cp /opt/ctrlb/seeker/ctrlb-seeker.backup.20251003_143022 \
        /opt/ctrlb/seeker/ctrlb-seeker

# Start the service
sudo ./deploy-seeker.sh start

# Verify
sudo ./deploy-seeker.sh status
```

## �🛠️ Service Management

### Systemd Service File

The service is configured with the following settings:

```ini
[Unit]
Description=CtrlB Seeker Service
After=network.target

[Service]
Type=simple
User=ctrlb
WorkingDirectory=/opt/ctrlb/seeker
ExecStart=/opt/ctrlb/seeker/ctrlb-seeker
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### Service Details

- **Service Name:** `ctrlb-seeker`
- **User:** `ctrlb` (dedicated system user, no shell access)
- **Working Directory:** `/opt/ctrlb/seeker`
- **Auto-restart:** Yes (on failure, 5-second delay)
- **Start on boot:** Yes (enabled by default)
- **Logging:** systemd journal (journalctl)

### Manual Service Control

You can also control the service directly with systemctl:

```bash
# Start service
sudo systemctl start ctrlb-seeker

# Stop service
sudo systemctl stop ctrlb-seeker

# Restart service
sudo systemctl restart ctrlb-seeker

# Reload service file changes
sudo systemctl daemon-reload
sudo systemctl restart ctrlb-seeker

# Check status
sudo systemctl status ctrlb-seeker

# Enable auto-start on boot
sudo systemctl enable ctrlb-seeker

# Disable auto-start
sudo systemctl disable ctrlb-seeker

# Check if service is running
sudo systemctl is-active ctrlb-seeker

# Check if service is enabled
sudo systemctl is-enabled ctrlb-seeker

# View logs
sudo journalctl -u ctrlb-seeker
sudo journalctl -u ctrlb-seeker -f              # Follow logs in real-time
sudo journalctl -u ctrlb-seeker -n 100          # Last 100 lines
sudo journalctl -u ctrlb-seeker --since today   # Today's logs
sudo journalctl -u ctrlb-seeker --since "1 hour ago"  # Last hour
```

## 🔍 Troubleshooting

### Service Won't Start

**Check the status:**
```bash
sudo ./deploy-seeker.sh status
```

**Check detailed logs:**
```bash
sudo journalctl -u ctrlb-seeker -n 50 --no-pager
```

**Common issues:**

1. **Binary not executable:**
   ```bash
   sudo chmod +x /opt/ctrlb/seeker/ctrlb-seeker
   ```

2. **Missing shared libraries:**
   ```bash
   ldd /opt/ctrlb/seeker/ctrlb-seeker
   ```

3. **Port already in use:**
   ```bash
   sudo ss -tlnp | grep :8080  # Replace with your port
   ```

4. **Permission issues:**
   ```bash
   ls -la /opt/ctrlb/seeker
   sudo chown -R ctrlb:ctrlb /opt/ctrlb/seeker
   ```

5. **Configuration file errors:**
   ```bash
   # Verify .env file exists and is readable
   sudo -u ctrlb cat /opt/ctrlb/seeker/.env
   ```

### Permission Denied Errors

```bash
# Fix ownership
sudo chown -R ctrlb:ctrlb /opt/ctrlb/seeker

# Fix permissions
sudo chmod 750 /opt/ctrlb/seeker
sudo chmod +x /opt/ctrlb/seeker/ctrlb-seeker
sudo chmod 600 /opt/ctrlb/seeker/.env
sudo chmod 600 /opt/ctrlb/seeker/private.key
```

### Configuration Not Loading

1. **Verify file exists and is readable:**
   ```bash
   sudo ls -la /opt/ctrlb/seeker/.env
   ```

2. **Check file ownership:**
   ```bash
   sudo chown ctrlb:ctrlb /opt/ctrlb/seeker/.env
   sudo chmod 600 /opt/ctrlb/seeker/.env
   ```

3. **Verify the binary can read the file:**
   ```bash
   sudo -u ctrlb cat /opt/ctrlb/seeker/.env
   ```

4. **Check for syntax errors in .env:**
   ```bash
   # .env should not have spaces around = signs
   # Correct:   KEY=value
   # Incorrect: KEY = value
   ```

5. **Restart after config changes:**
   ```bash
   sudo ./deploy-seeker.sh restart
   ```

### Service User Issues

If the `ctrlb` user doesn't exist:
```bash
sudo useradd --system \
             --home-dir /opt/ctrlb/seeker \
             --shell /usr/sbin/nologin \
             --comment "CtrlB Seeker service user" \
             ctrlb
```

## 🔒 Security

### File Permissions Overview

| Path | Permissions | Owner | Description |
|------|-------------|-------|-------------|
| `/opt/ctrlb/seeker/` | `750` | `ctrlb:ctrlb` | Working directory |
| `/opt/ctrlb/seeker/keys/` | `750` | `ctrlb:ctrlb` | Keys directory |
| `/opt/ctrlb/seeker/ctrlb-seeker` | `755` | `ctrlb:ctrlb` | Binary (executable) |
| `/opt/ctrlb/seeker/.env` | `600` | `ctrlb:ctrlb` | Environment (secrets) |
| `/opt/ctrlb/seeker/keys/private.key` | `600` | `ctrlb:ctrlb` | Private key (secure) |
| `/opt/ctrlb/seeker/keys/public.key` | `644` | `ctrlb:ctrlb` | Public key |
| `/var/log/ctrlb/` | `755` | `ctrlb:ctrlb` | Log directory |
| `/etc/systemd/system/ctrlb-seeker.service` | `644` | `root:root` | Service file |

### Security Best Practices

✅ **Service runs as non-root user** (`ctrlb`)  
✅ **Sensitive files protected** (600 permissions)  
✅ **System user with no login shell** (`/usr/sbin/nologin`)  
✅ **Minimal privileges** (principle of least privilege)  
✅ **Automatic restarts** (service resilience)  

### Important Security Notes

- **Never run the service as root** in production
- **Protect private keys** - They have `600` permissions (owner only)
- **Rotate credentials regularly** - Update `.env` and keys periodically
- **Monitor logs** - Check `/var/log/ctrlb/` and `journalctl` regularly
- **Keep binary updated** - Redeploy when updates are available

## 🗑️ Uninstallation

### Automated Uninstall

```bash
sudo ./deploy-seeker.sh uninstall
```

This will:
- ✅ Stop the service
- ✅ Disable auto-start
- ✅ Remove service file
- ✅ Remove binary
- ✅ Reload systemd

**Note:** The service user (`ctrlb`) and directories are **preserved** for safety.

### Complete Manual Removal

If you want to completely remove everything:

```bash
# 1. Run the uninstall command
sudo ./deploy-seeker.sh uninstall

# 2. Remove the service user
sudo userdel ctrlb

# 3. Remove directories
sudo rm -rf /opt/ctrlb/seeker
sudo rm -rf /var/log/ctrlb

# 4. Verify cleanup
sudo systemctl status seeker  # Should show "not found"
```

## 📝 Examples

### Example 1: Fresh Installation

```bash
# Navigate to deployment directory
cd /path/to/deploy-seeker

# Make script executable
chmod +x deploy-seeker.sh

# Install and start service immediately
sudo ./deploy-seeker.sh install-enable

# Check status
sudo ./deploy-seeker.sh status
```

### Example 2: Update Binary Only

```bash
# Replace with newer binary version (creates backup automatically)
sudo ./deploy-seeker.sh install-binary

# Restart to use new binary
sudo ./deploy-seeker.sh restart

# Verify new version is running
sudo ./deploy-seeker.sh status
```

### Example 3: Update Configuration

```bash
# Edit your .env file
nano .env

# Deploy updated configuration
sudo ./deploy-seeker.sh install-config

# Restart to apply changes
sudo ./deploy-seeker.sh restart

# Verify changes took effect
sudo ./deploy-seeker.sh status
```

### Example 3: Monitoring Logs

```bash
# View recent logs
sudo journalctl -u ctrlb-seeker -n 100

# Follow logs in real-time
sudo journalctl -u ctrlb-seeker -f

# View logs since last boot
sudo journalctl -u ctrlb-seeker -b

# View logs with timestamps
sudo journalctl -u ctrlb-seeker -o short-iso

# Filter by priority (error and above)
sudo journalctl -u ctrlb-seeker -p err

# Export logs to file
sudo journalctl -u ctrlb-seeker > seeker-logs.txt
```

### Example 4: Debugging Issues

```bash
# Check if service is running
sudo systemctl is-active ctrlb-seeker

# Check if service is enabled
sudo systemctl is-enabled ctrlb-seeker

# View full status with extended info
sudo ./deploy-seeker.sh status

# Check file permissions
ls -laR /opt/ctrlb/seeker/

# Verify binary dependencies
ldd /opt/ctrlb/seeker/ctrlb-seeker

# Test binary manually as service user
sudo -u ctrlb /opt/ctrlb/seeker/ctrlb-seeker --version

# Check environment variables
sudo -u ctrlb env -i bash -c 'cd /opt/ctrlb/seeker && cat .env'
```

### Example 5: Safe Production Deployment

```bash
# First deployment to production
cd /path/to/deploy-seeker
cp .env.example .env
nano .env  # Configure for production

# Install without overwriting any existing configs
sudo ./deploy-seeker.sh --force=skip install

# Verify service is healthy
sudo ./deploy-seeker.sh status
sudo journalctl -u ctrlb-seeker -n 50

# Monitor for first 5 minutes
sudo journalctl -u ctrlb-seeker -f
```

### Example 6: Upgrade Existing Installation

```bash
# Download new binary version
cp /path/to/new/seeker .
chmod +x seeker

# Backup current state
sudo tar -czf /tmp/seeker-backup-$(date +%Y%m%d).tar.gz \
    /opt/ctrlb/seeker/

# Perform upgrade (automatic backup + service restart)
sudo ./deploy-seeker.sh install

# Verify new version is running
sudo ./deploy-seeker.sh status

# If issues occur, rollback
sudo ./deploy-seeker.sh stop
sudo cp /opt/ctrlb/seeker/ctrlb-seeker.backup.* \
        /opt/ctrlb/seeker/ctrlb-seeker
sudo ./deploy-seeker.sh start
```

## 🤝 Support

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review logs: `sudo journalctl -u seeker -n 100`
3. Verify all [prerequisites](#prerequisites) are met
4. Check file permissions and ownership

## 📄 License

This deployment script is part of the CtrlB Seeker project.

---

## 🔧 Advanced Usage

### Environment Variables via Command Line

Override configuration without editing .env:

```bash
# Set CONFIG_MODE via environment variable
CONFIG_MODE=backup sudo ./deploy-seeker.sh install-config

# Override in systemd service (edit service file)
sudo systemctl edit ctrlb-seeker
```

### Running in Different Environments

```bash
# Development
LOG_LEVEL=debug sudo ./deploy-seeker.sh restart

# Production with strict config handling
sudo ./deploy-seeker.sh --force=skip install

# Staging environment
SEEKER_REGION=staging sudo ./deploy-seeker.sh install
```

### Backup Management

```bash
# List all backups
ls -lht /opt/ctrlb/seeker/*.backup.* | head -10

# Clean old backups (keep last 5)
cd /opt/ctrlb/seeker
ls -t *.backup.* | tail -n +6 | xargs sudo rm -f

# Archive backups before cleanup
sudo tar -czf backups-$(date +%Y%m%d).tar.gz *.backup.*
```

## 🤝 Contributing

Improvements and bug reports are welcome! When reporting issues, please include:

- Script version (`head -n 6 deploy-seeker.sh | grep Version`)
- OS and systemd version (`systemctl --version`)
- Relevant logs (`journalctl -u ctrlb-seeker -n 50`)
- Steps to reproduce

## 📋 Changelog

### Version 1.1.0 (2025-10-03)
- ✨ Added automatic backup for binaries and service files
- ✨ Safe upgrade process with automatic service stop
- ✨ Improved error handling and validation
- ✨ Added configuration mode validation
- ✨ Enhanced user checks in install-config-only
- 🐛 Fixed color variable definition order
- 🐛 Fixed indentation issues
- 📝 Comprehensive documentation updates

### Version 1.0.0 (Initial Release)
- Initial deployment script with basic functionality

---

**Last Updated:** 3 October 2025  
**Script Version:** 1.1.0  
**Maintained by:** CtrlB Team