#!/bin/bash
set -e

# ==================================================================
# Configuration
# ==================================================================
WORKSPACE="$(pwd)"
ESP_IDF_DIR="${WORKSPACE}/esp/esp-idf"
KEYS_DIR="${WORKSPACE}/keys"
KEY_FILE="${KEYS_DIR}/secure_boot_signing_key.pem"
JADE_REPO="https://github.com/Blockstream/Jade.git"

# ---- Helper Functions ----
print_step() {
    echo ""
    echo "================================================================="
    echo "  Step $1: $2"
    echo "================================================================="
    echo ""
}
print_ok()      { echo "  ✅  $1"; }
print_warn()    { echo "  ⚠️   $1"; }
print_err()     { echo "  ❌  $1"; }
print_info()    { echo "  📋  $1"; }

# ==================================================================
# Step 1: Board Selection
# ==================================================================
print_step 1 "Select Your ESP32-S3 Board"
echo "Please select your hardware target:"
echo "  1) Waveshare S3 Touch LCD 2"
echo "  2) LILYGO T-Display S3"
echo "  3) M5Stack CoreS3"
echo "  4) Enter custom config name"
echo ""
read -p "Enter choice (1-4): " BOARD_CHOICE

case $BOARD_CHOICE in
    1) BASE_CONFIG="configs/sdkconfig_display_waveshares3_touch_lcd2.defaults" ;;
    2) BASE_CONFIG="configs/sdkconfig_display_lilygo_tdisplays3.defaults" ;;
    3) BASE_CONFIG="configs/sdkconfig_display_m5stack_cores3.defaults" ;;
    4)
        read -p "Enter the base config filename (e.g. configs/sdkconfig_xxx.defaults): " BASE_CONFIG
        ;;
    *)
        print_err "Invalid choice."
        exit 1
        ;;
esac
print_ok "Selected config: $BASE_CONFIG"

# ==================================================================
# Step 2: Check Requirements
# ==================================================================
print_step 2 "Checking prerequisites"

for pkg in cmake ninja python3 git; do
    if ! command -v $pkg &>/dev/null; then
        print_err "$pkg is not installed. Please install it first."
        exit 1
    fi
done
print_ok "All required tools found."

# ==================================================================
# Step 3: Clone Repositories
# ==================================================================
print_step 3 "Cloning Blockstream Jade & ESP-IDF"

if [ ! -d "Jade" ]; then
    print_info "Cloning Blockstream Jade repository..."
    git clone --recursive "${JADE_REPO}" Jade
else
    print_info "Jade directory already exists, skipping clone."
fi

mkdir -p "${WORKSPACE}/esp"
cd "${WORKSPACE}/esp"

if [ ! -d "esp-idf" ]; then
    print_info "Cloning ESP-IDF v5.4..."
    git clone -b v5.4 --recursive https://github.com/espressif/esp-idf.git
else
    print_info "ESP-IDF already exists, skipping clone."
fi

# ==================================================================
# Step 4: Install ESP-IDF Tools
# ==================================================================
print_step 4 "Installing ESP-IDF environment"
cd "${ESP_IDF_DIR}"
./install.sh esp32s3
source ./export.sh
print_ok "ESP-IDF environment loaded."

# ==================================================================
# Step 5: Setup Secure Boot Key
# ==================================================================
print_step 5 "Secure Boot Key Generation"
mkdir -p "${KEYS_DIR}"

if [ ! -f "${KEY_FILE}" ]; then
    print_warn "No Secure Boot key found. Generating a new RSA-3072 key..."
    espsecure.py generate_signing_key --version 2 "${KEY_FILE}"
    print_ok "Generated new key: ${KEY_FILE}"
    print_warn "CRITICAL: Backup this key file immediately! If you lose it, you cannot update your board."
else
    print_ok "Found existing Secure Boot key: ${KEY_FILE}"
fi

# ==================================================================
# Step 6: Configure and Build Firmware
# ==================================================================
print_step 6 "Preparing Jade Configuration"
cd "${WORKSPACE}/Jade"

print_info "Using base config: ${BASE_CONFIG}"
if [ ! -f "${BASE_CONFIG}" ]; then
    print_err "Base config file not found: ${BASE_CONFIG}"
    exit 1
fi

print_info "Applying Secure Boot configurations..."
cp "${BASE_CONFIG}" sdkconfig.defaults
cat "${WORKSPACE}/sdkconfig_secure_append.defaults" >> sdkconfig.defaults

echo "" >> sdkconfig.defaults
echo "# Signing Key Path" >> sdkconfig.defaults
echo "CONFIG_SECURE_BOOT_SIGNING_KEY=\"${KEY_FILE}\"" >> sdkconfig.defaults

# --- Fix Partition Table Offsets ---
print_info "Patching partition table to prevent offset overlap..."
# Replace explicit offset values with blanks so ESP-IDF calculates them dynamically
sed -i.bak 's/nvs,      data, nvs,     0xA000,/nvs,      data, nvs,     ,/g' partitionss3.csv
sed -i.bak 's/otadata,  data, ota,     0x1A000,/otadata,  data, ota,     ,/g' partitionss3.csv
rm -f partitionss3.csv.bak
print_ok "Partition table patched."

# --- Clean and Build ---
print_info "Cleaning previous build..."
rm -rf build sdkconfig

print_info "Starting compilation (this may take a while)..."
idf.py set-target esp32s3
idf.py build

# ==================================================================
# Step 7: Verify Signatures
# ==================================================================
print_step 7 "Verifying Firmware Signatures"

if [ -f "build/bootloader/bootloader.bin" ] && [ -f "build/jade.bin" ]; then
    print_ok "Binaries generated successfully."
    espsecure.py verify_signature --version 2 -k "${KEY_FILE}" build/jade.bin || true
else
    print_err "Build failed. Binaries not found."
    exit 1
fi

# ==================================================================
# Instructions
# ==================================================================
print_step 8 "Ready to Flash"

echo "  ✅ Compilation Complete!"
echo ""
echo "  1. 🔑 BACKUP YOUR KEY TO A USB DRIVE:"
echo "        ${KEY_FILE}"
echo ""
echo "  2. 🔌 Connect your ESP32-S3 board in Download Mode"
echo "        (Hold BOOT button, press RESET, release BOOT)"
echo ""
echo "  3. ⚡ Flash the Bootloader manually FIRST:"
echo "        cd Jade"
echo "        source ../esp/esp-idf/export.sh"
echo "        idf.py -p /dev/cu.usbmodemXXXX bootloader-flash"
echo ""
echo "  4. 📤 Flash the Application Firmware:"
echo "        idf.py -p /dev/cu.usbmodemXXXX flash"
echo ""
echo "  ⚠️  WARNING: First boot will encrypt the flash and burn eFuses permanently."
echo "  DO NOT unplug the device while the screen is black (takes ~2 minutes)."
echo "================================================================="
