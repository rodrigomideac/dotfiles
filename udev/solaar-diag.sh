#!/bin/bash
# Solaar Permission Diagnostic Script

echo "=================================="
echo "Solaar Permission Diagnostic Tool"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}[WARNING]${NC} Don't run this script as root/sudo"
    echo ""
fi

# 1. Check udev rule exists
echo "=== 1. Checking udev rule ==="
UDEV_RULE="/etc/udev/rules.d/42-logitech-unify-permissions.rules"
if [ -f "$UDEV_RULE" ]; then
    echo -e "${GREEN}[OK]${NC} Udev rule exists: $UDEV_RULE"
    echo ""
    echo "Rule content:"
    grep -v "^#" "$UDEV_RULE" | grep -v "^$"
else
    echo -e "${RED}[ERROR]${NC} Udev rule not found: $UDEV_RULE"
    echo "Run: sudo pacman -S solaar"
fi
echo ""

# 2. Check for Logitech devices
echo "=== 2. Detecting Logitech HID devices ==="
LOGITECH_FOUND=0
for device in /dev/hidraw*; do
    if [ -e "$device" ]; then
        VENDOR=$(udevadm info $device 2>/dev/null | grep "ID_VENDOR_ID=" | cut -d'=' -f2)
        MODEL=$(udevadm info $device 2>/dev/null | grep "ID_MODEL_ID=" | cut -d'=' -f2)
        PRODUCT=$(udevadm info $device 2>/dev/null | grep "ID_MODEL=" | cut -d'=' -f2 | head -1)
        
        if [ "$VENDOR" = "046d" ] || [ "$VENDOR" = "17ef" ]; then
            LOGITECH_FOUND=1
            echo -e "${GREEN}[FOUND]${NC} $device"
            echo "  Vendor: $VENDOR"
            echo "  Model: $MODEL"
            echo "  Product: $PRODUCT"
            
            # Check permissions
            PERMS=$(ls -l "$device")
            echo "  Permissions: $PERMS"
            
            # Check ACLs
            if command -v getfacl &> /dev/null; then
                USER_ACL=$(getfacl "$device" 2>/dev/null | grep "user:$USER:")
                if [ -n "$USER_ACL" ]; then
                    echo -e "  ACL: ${GREEN}[OK]${NC} $USER_ACL"
                else
                    echo -e "  ACL: ${RED}[MISSING]${NC} No ACL for user $USER"
                fi
            fi
            
            # Test if we can open it
            if [ -r "$device" ] && [ -w "$device" ]; then
                echo -e "  Access: ${GREEN}[OK]${NC} Read/Write available"
            else
                echo -e "  Access: ${RED}[DENIED]${NC} Cannot read/write"
            fi
            echo ""
        fi
    fi
done

if [ $LOGITECH_FOUND -eq 0 ]; then
    echo -e "${YELLOW}[INFO]${NC} No Logitech devices found. Is your receiver plugged in?"
fi
echo ""

# 3. Check user groups
echo "=== 3. Checking user groups ==="
if groups | grep -q "plugdev"; then
    echo -e "${GREEN}[OK]${NC} User is in 'plugdev' group"
else
    echo -e "${YELLOW}[INFO]${NC} User is NOT in 'plugdev' group"
    echo "  This is OK if using uaccess method"
fi

if groups | grep -q "input"; then
    echo -e "${GREEN}[OK]${NC} User is in 'input' group"
else
    echo -e "${YELLOW}[INFO]${NC} User is NOT in 'input' group"
    echo "  Run: sudo usermod -a -G input $USER"
fi
echo ""

# 4. Check logind session
echo "=== 4. Checking logind session ==="
if command -v loginctl &> /dev/null; then
    SESSION=$(loginctl | grep "$USER" | awk '{print $1}' | head -1)
    if [ -n "$SESSION" ]; then
        SESSION_TYPE=$(loginctl show-session "$SESSION" 2>/dev/null | grep "Type=" | cut -d'=' -f2)
        echo -e "${GREEN}[OK]${NC} Session: $SESSION"
        echo "  Type: $SESSION_TYPE"
        
        if [ "$SESSION_TYPE" = "unspecified" ]; then
            echo -e "  ${YELLOW}[WARNING]${NC} Session type is unspecified, uaccess may not work properly"
        fi
    else
        echo -e "${RED}[ERROR]${NC} No active session found for $USER"
    fi
else
    echo -e "${YELLOW}[INFO]${NC} loginctl not available"
fi
echo ""

# 5. Check if Solaar is running
echo "=== 5. Checking Solaar process ==="
if pgrep -x "solaar" > /dev/null; then
    echo -e "${GREEN}[RUNNING]${NC} Solaar is running"
    echo "PIDs: $(pgrep -x solaar | tr '\n' ' ')"
else
    echo -e "${YELLOW}[INFO]${NC} Solaar is not running"
fi
echo ""

# 6. Recommendations
echo "=== 6. Recommendations ==="
ISSUES_FOUND=0

for device in /dev/hidraw*; do
    if [ -e "$device" ]; then
        VENDOR=$(udevadm info $device 2>/dev/null | grep "ID_VENDOR_ID=" | cut -d'=' -f2)
        if [ "$VENDOR" = "046d" ] || [ "$VENDOR" = "17ef" ]; then
            if ! [ -r "$device" ] || ! [ -w "$device" ]; then
                ISSUES_FOUND=1
                echo -e "${RED}[ACTION NEEDED]${NC} $device has permission issues"
                echo ""
                echo "Try these steps:"
                echo "1. Reload udev rules:"
                echo "   sudo udevadm control --reload-rules"
                echo "   sudo udevadm trigger --subsystem-match=hidraw"
                echo ""
                echo "2. If still not working, edit $UDEV_RULE and use plugdev method:"
                echo "   Uncomment: MODE=\"0660\", GROUP=\"plugdev\""
                echo "   Comment out: TAG+=\"uaccess\""
                echo "   Then run: sudo groupadd -f plugdev && sudo usermod -a -G plugdev $USER"
                echo ""
                echo "3. Log out and log back in (or reboot)"
                echo ""
                echo "4. Or simply unplug and replug your Logitech receiver"
                break
            fi
        fi
    fi
done

if [ $ISSUES_FOUND -eq 0 ] && [ $LOGITECH_FOUND -eq 1 ]; then
    echo -e "${GREEN}[OK]${NC} All Logitech devices have proper permissions!"
    echo "If Solaar still doesn't work, try:"
    echo "  killall solaar && /usr/bin/solaar -ddd"
fi

echo ""
echo "==================================="
echo "Diagnostic complete"
echo "==================================="
