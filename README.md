# คู่มือการติดตั้ง Jade DIY พร้อมระบบ Secure Boot
*(English version is available below)*

โปรเจกต์นี้มีสคริปต์อัตโนมัติสำหรับคอมไพล์และแฟลชเฟิร์มแวร์ [Blockstream Jade](https://github.com/Blockstream/Jade) ลงบนบอร์ด ESP32-S3 แบบ DIY โดยทำการ **เปิดใช้งาน Secure Boot V2 และ Flash Encryption**

การเปิดระบบความปลอดภัยเหล่านี้จะช่วยปกป้อง Hardware Wallet แบบ DIY ของคุณจากการถูกแฮ็กเชิงกายภาพ (Physical tampering) และป้องกันการแฟลชเฟิร์มแวร์ปลอมแปลงทับลงไป

## ⚠️ คำเตือนสำคัญมาก (อ่านก่อนใช้งาน)
1. **การเบิร์น eFuse ถาวร:** การเปิดบอร์ดครั้งแรกหลังจากแฟลชด้วยสคริปต์นี้ จะทำการเบิร์น eFuse ภายในชิป ESP32-S3 อย่างถาวร **(ไม่สามารถย้อนกลับหรือลบล้างได้)**
2. **ไฟล์กุญแจสำคัญ (Signing Key):** สคริปต์นี้จะสร้างไฟล์กุญแจชื่อ `secure_boot_signing_key.pem` ขึ้นมาในโฟลเดอร์ `keys/` **คุณต้องสำรองไฟล์นี้เก็บไว้ในที่ปลอดภัยทันที!** หากคุณทำไฟล์นี้หาย คุณจะ**ไม่สามารถอัปเดตเฟิร์มแวร์**ให้บอร์ดนี้ได้อีกตลอดกาล (ห้ามอัปโหลดไฟล์นี้ขึ้น GitHub เด็ดขาด)
3. **ห้ามขัดจังหวะการบูตครั้งแรก:** การบูตครั้งแรกชิปจะทำการเข้ารหัส Flash Memory ซึ่งใช้เวลาประมาณ 1-2 นาที (หน้าจอจะมืดสนิท) **ห้ามถอดสาย USB หรือกดปุ่มรีเซ็ตเด็ดขาด** ในระหว่างนี้ ไม่อย่างนั้นบอร์ดอาจจะพังถาวร (Bricked)

## สิ่งที่ต้องเตรียม
- ระบบปฏิบัติการ macOS หรือ Linux
- [Homebrew](https://brew.sh) (สำหรับ macOS)
- ติดตั้ง `cmake`, `ninja`, `python3`, `git`

## บอร์ดที่รองรับเบื้องต้น
สคริปต์นี้มีเมนูให้พิมพ์เลือกบอร์ดได้ทันที:
- Waveshare ESP32-S3 Touch LCD 2
- LILYGO T-Display S3
- M5Stack CoreS3
- *บอร์ดอื่นๆ (สามารถพิมพ์ชื่อไฟล์ Config ของบอร์ดนั้นๆ ได้เอง)*

## วิธีใช้งาน

### 1. โคลนโปรเจกต์นี้
```bash
git clone https://github.com/YOUR_USERNAME/jade-diy-secureboot.git
cd jade-diy-secureboot
```

### 2. รันสคริปต์สร้างเฟิร์มแวร์
```bash
bash setup_and_build.sh
```
ทำตามขั้นตอนบนหน้าจอเพื่อเลือกบอร์ดของคุณ จากนั้นสคริปต์จะทำการ:
- ดาวน์โหลด ESP-IDF v5.4 และ Source Code ของ Blockstream Jade
- สร้างกุญแจ Secure Boot RSA-3072 เฉพาะตัวของคุณ (ถ้ายังไม่มี)
- แก้ไข Partition Table อัตโนมัติ เพื่อรองรับ Bootloader ที่ขนาดใหญ่ขึ้น
- คอมไพล์เฟิร์มแวร์

### 3. สำรองไฟล์ Key
เมื่อคอมไพล์เสร็จ ให้ก๊อปปี้ไฟล์ `keys/secure_boot_signing_key.pem` ไปเก็บไว้ใน USB Drive หรือที่ปลอดภัยออฟไลน์

### 4. แฟลชเฟิร์มแวร์ลงบอร์ด
นำบอร์ดเข้าสู่ **Download Mode** (กดปุ่ม `BOOT` ค้างไว้, กดปุ่ม `RESET` 1 ครั้ง, ปล่อยปุ่ม `BOOT`) จากนั้นรันคำสั่งต่อไปนี้:

**ขั้นตอน 4.1: บังคับแฟลช Bootloader**
*เนื่องจากเราเปิด Secure Boot ระบบของ ESP-IDF จะไม่ยอมแฟลช Bootloader ให้อัตโนมัติ เราต้องสั่งเอง*
```bash
cd Jade
source ../esp/esp-idf/export.sh
idf.py -p /dev/cu.usbmodemXXXX bootloader-flash
```
*(เปลี่ยน `/dev/cu.usbmodemXXXX` เป็นชื่อพอร์ต USB ของคุณ สามารถเช็คได้โดยพิมพ์ `ls /dev/cu.*`)*

**ขั้นตอน 4.2: แฟลช Application หลัก**
```bash
idf.py -p /dev/cu.usbmodemXXXX flash
```

### 5. การบูตครั้งแรก (กระบวนการเข้ารหัส)
หลังจากแฟลชเสร็จ บอร์ดจะไม่รีสตาร์ทเอง
- ให้กดปุ่ม `RESET` บนบอร์ด 1 ครั้ง
- หน้าจอจะ **มืดสนิท** เป็นเวลาประมาณ 1 ถึง 2 นาทีเพื่อเข้ารหัสข้อมูล **ห้ามถอดสาย USB เด็ดขาด**
- เมื่อเสร็จสิ้น โลโก้ Jade จะสว่างขึ้นมา

## คำถามที่พบบ่อย (FAQ)
**Q: มุมซ้ายล่างของจอขึ้นว่า `Uninitialized` ต้องทำยังไง?**
A: แปลว่าบอร์ดนี้ยังไม่มีกระเป๋าเงิน (Wallet) ให้โหลดแอป Blockstream Green บนมือถือหรือคอม แล้วเชื่อมต่อบอร์ดเพื่อทำการสร้างกระเป๋าหรือกู้คืนคำ 12/24 คำครับ

**Q: มุมขวาบนขึ้นเวอร์ชัน `1.0.40-dirty` ปลอดภัยไหม?**
A: ปลอดภัย 100% ครับ คำว่า `-dirty` แค่แปลว่าเรามีการไปดัดแปลง Source Code ก่อนคอมไพล์ (ในที่นี้คือเราสั่งสคริปต์แก้ Partition Table ให้รองรับความปลอดภัย) เป็นเรื่องปกติของบอร์ด DIY ครับ

---
---

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
