#!/bin/bash

# ==========================================
# ONE-SHOT MAC RANDOMIZER INSTALLER
# ==========================================

# 1. USER CONFIGURATION
#################### CHANGE THE TWO PARAMETERS BETWEEN THESE HASH MARKS ####################
IFACE=""           # Leave empty to auto-detect the default interface
MAC_PREFIX="02"    # '02' ensures a private/locally administered MAC
############################################################################################



############################# NOTHING BELOW HERE NEEDS EDITED ##############################
BIN_PATH="/usr/local/bin/randomize-mac.sh"
SERVICE_PATH="/etc/systemd/system/mac-randomizer.service"

# Check for root
if [[ $EUID -ne 0 ]]; then
   echo "[-] Error: Please run with sudo (e.g., sudo ./randomizer.sh)"
   exit 1
fi

echo "[*] Starting installation..."

# 2. CREATE THE SCRIPT
echo "[*] Creating script at $BIN_PATH"
cat << EOF > $BIN_PATH
#!/bin/bash
# Detected config
TARGET_IFACE="$IFACE"
[ -z "\$TARGET_IFACE" ] && TARGET_IFACE=\$(ip route | grep default | awk '{print \$5}' | head -n1)

OLD_MAC=\$(cat /sys/class/net/\$TARGET_IFACE/address)
NEW_MAC=\$(printf '${MAC_PREFIX}:%02x:%02x:%02x:%02x:%02x' \$((RANDOM%256)) \$((RANDOM%256)) \$((RANDOM%256)) \$((RANDOM%256)) \$((RANDOM%256)))

ip link set \$TARGET_IFACE down
ip link set \$TARGET_IFACE address \$NEW_MAC
ip link set \$TARGET_IFACE up

echo "[+] \$TARGET_IFACE: \$OLD_MAC -> \$NEW_MAC"
EOF

# Set permissions
chmod +x $BIN_PATH

# 3. CREATE SYSTEMD SERVICE
echo "[*] Creating systemd service at $SERVICE_PATH"
cat << EOF > $SERVICE_PATH
[Unit]
Description=Randomize MAC Address on Boot
Wants=network-pre.target
Before=network-pre.target
After=sys-subsystem-net-devices-$(echo $IFACE).device

[Service]
Type=oneshot
ExecStart=$BIN_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 4. ENABLE SERVICE
echo "[*] Reloading systemd and enabling service..."
systemctl daemon-reload
systemctl enable mac-randomizer.service

echo "-----------------------------------------------"
echo "[DONE] MAC Randomizer is installed and enabled."
echo "[!] It will run automatically on every boot."
echo "[!] To run it now: sudo systemctl start mac-randomizer"
echo "-----------------------------------------------"
