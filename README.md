# Jade DIY Secure Boot Setup

This repository provides an automated script to build and flash the [Blockstream Jade](https://github.com/Blockstream/Jade) firmware for DIY ESP32-S3 boards, **with Secure Boot V2 and Flash Encryption enabled.**

Enabling Secure Boot V2 and Flash Encryption ensures that your DIY hardware wallet is protected against physical tampering and unauthorized firmware replacements.

## ⚠️ CRITICAL WARNING (READ BEFORE USE)
1. **PERMANENT eFUSE BURN:** The first time your board boots after flashing with this script, it will permanently burn the eFuses inside the ESP32-S3 chip. This process is **IRREVERSIBLE**.
2. **SECURE SIGNING KEY:** This script generates a unique `secure_boot_signing_key.pem` in the `keys/` directory. **YOU MUST BACK UP THIS FILE.** If you lose this key, you will **NEVER** be able to update the firmware on your board again. Do NOT commit this key to GitHub.
3. **DO NOT INTERRUPT INITIAL BOOT:** The first boot process performs flash encryption which takes about 1-2 minutes. The screen will remain black. Do NOT unplug the USB cable or press reset during this time, or your board may be permanently bricked.

## Prerequisites
- macOS or Linux
- [Homebrew](https://brew.sh) (macOS)
- `cmake`, `ninja`, `python3`, `git`

## Supported Boards
This script currently has built-in menu options for:
- Waveshare ESP32-S3 Touch LCD 2
- LILYGO T-Display S3
- M5Stack CoreS3
- *Custom boards (you can manually specify the Jade SDK config)*

## How to Use

### 1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/jade-diy-secureboot.git
cd jade-diy-secureboot
```

### 2. Run the build script
```bash
bash setup_and_build.sh
```
Follow the on-screen prompts to select your board. The script will automatically:
- Download ESP-IDF v5.4 and Blockstream Jade source code.
- Generate a unique Secure Boot RSA-3072 key (if it doesn't exist).
- Patch the partition table to accommodate the larger secure bootloader.
- Compile the firmware.

### 3. Backup your Key
Once the build is complete, copy the `keys/secure_boot_signing_key.pem` file to a secure offline backup (like a USB drive).

### 4. Flash the Firmware
Put your board into **Download Mode** (Hold `BOOT`, press `RESET`, release `BOOT`). Then run the following commands:

**Step 4.1: Flash the Bootloader explicitly**
*Because Secure Boot is enabled, ESP-IDF will not flash the bootloader automatically.*
```bash
cd Jade
source ../esp/esp-idf/export.sh
idf.py -p /dev/cu.usbmodemXXXX bootloader-flash
```

**Step 4.2: Flash the Application**
```bash
idf.py -p /dev/cu.usbmodemXXXX flash
```

### 5. The First Boot (Encryption)
After flashing is complete, the board will not reboot automatically.
- Press the `RESET` button on your board.
- The screen will be **BLACK** for 1 to 2 minutes while it encrypts the flash memory. **DO NOT UNPLUG IT.**
- Once finished, the Jade logo will appear.

## FAQ
**Q: The bottom left of the screen says `Uninitialized`. What do I do?**
A: This means your Jade does not have a wallet (seed phrase) set up yet. Connect it to the Blockstream Green app via Bluetooth or USB to initialize your wallet.

**Q: The top right says version `1.0.40-dirty`. Is this safe?**
A: Yes. The `-dirty` suffix simply means that we modified the source code (the partition table and configuration files) before building. This is completely normal and safe for this DIY Secure Boot process.
