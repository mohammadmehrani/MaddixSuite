<div dir="rtl" align="center">

# 🛠️ مدیکس‌سوئیت (MaddixSuite)

**ساخته شده توسط محمد مهرانی (Maddix)**

[![مجوز: MIT](https://img.shields.io/badge/مجوز-MIT-2ea44f?style=flat-square)](LICENSE)
[![پاورشل](https://img.shields.io/badge/Windows-PowerShell%203%2B-5391FE?style=flat-square&logo=PowerShell)]()
[![لینوکس](https://img.shields.io/badge/Linux-%DB%8C%D9%88%D9%86%DB%8C%D9%88%D8%B1%D8%B3%D8%A7%D9%84-E95420?style=flat-square&logo=Linux)]()
[![English](https://img.shields.io/badge/🇬🇧-English-blue?style=flat-square)](README.md)

> مجموعه‌ای کراس‌پلتفرم از ابزارهای مدیریت، تعمیر، پشتیبان‌گیری، امنیت و بهینه‌سازی سیستم‌عامل
> 📖 [**ویکی و راهنمای کاربر** ←](wiki/Home.md)

<br>

---

## 🚀 اجرای یک‌خطی

<br>

**🟦 ویندوز (PowerShell):**
<div dir="ltr">

```powershell
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/SysAdminSuite.ps1 | iex
```
</div>

**🐧 لینوکس (Bash):**
<div dir="ltr">

```bash
bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/SysAdminSuite.sh)
```
</div>

<br>

---

## 📦 فهرست اسکریپت‌ها

<br>

### 🪟 ویندوز (۸ اسکریپت)

| دسته | اسکریپت | قابلیت‌ها |
|:----:|:---------|:-----------|
| **اصلی** | `SysAdminSuite.ps1` | ۳۵ گزینه: دیاگنوستیک، تعمیر، بکاپ، شبکه، امنیت، بهینه‌سازی |
| **CMD** | `SysAdminSuite.cmd` | ۱۸ ابزار در خط فرمان |
| **بکاپ** | `Backup-Restore.ps1` | بکاپ کامل رجیستری، درایور، BCD، شبکه |
| **رجیستری** | `Maddix-RegistryTool.ps1` | بکاپ، بازیابی، پاکسازی، جستجو، بهینه‌سازی رجیستری |
| **شبکه** | `Maddix-NetworkPro.ps1` | دیاگنوستیک، WiFi، DNS، سرعت‌سنج |
| **پاکساز** | `Maddix-SystemCleaner.ps1` | پاکسازی عمیق: کش، لاگ، مرورگر، فایل تکراری |
| **امنیت** | `Maddix-SecurityAudit.ps1` | اسکن پورت، فایروال، کاربران، وضعیت آنتی‌ویروس |
| **BSOD Fix** | `BSOD-Fix.ps1` | تعمیر خودکار خطای 0xD1 ناشی از iaStorAC.sys در هایبرنیت - تشخیص هوشمند، ۳ راه حل پیشنهادی |
| **بهینه‌سازی** | `Maddix-PerformanceTuner.ps1` | CPU، RAM، دیسک، GPU، استارتاپ، پاور، شبکه |
| **داکر** | `Maddix-DockerSetup.ps1` | نصب و مدیریت Docker Desktop + WSL2 |

### 🐧 لینوکس (۵ اسکریپت)

| دسته | اسکریپت | قابلیت‌ها |
|:----:|:---------|:-----------|
| **اصلی** | `SysAdminSuite.sh` | ۱۹ گزینه: تعمیر، شبکه، پاکساز، بکاپ، امنیت |
| **فایروال** | `maddix-iptables.sh` | پروفایل کلاینت/سرور، NAT، rate limit، مسدودسازی IP |
| **توسعه** | `maddix-devsetup.sh` | نصب ویرایشگر، زبان، دیتابیس، داکر، ابری |
| **داکر** | `maddix-docker.sh` | نصب، مدیریت کانتینر، ایمیج، compose |
| **امنیت** | `maddix-hardener.sh` | هاردن SSH، کرنل، فایروال، اسکن بدافزار |

<br>

---

## 📁 ساختار پروژه

<div dir="ltr">

```
MaddixSuite/
├── windows/          🪟
│   ├── SysAdminSuite.ps1
│   ├── Registry/        Maddix-RegistryTool.ps1
│   ├── Network/         Maddix-NetworkPro.ps1
│   ├── Cleaner/         Maddix-SystemCleaner.ps1
│   ├── Security/        Maddix-SecurityAudit.ps1
│   ├── Optimization/    Maddix-PerformanceTuner.ps1
│   └── Docker/          Maddix-DockerSetup.ps1
└── linux/               🐧
    ├── SysAdminSuite.sh
    ├── firewall/        maddix-iptables.sh
    ├── devtools/        maddix-devsetup.sh
    ├── docker/          maddix-docker.sh
    └── security/        maddix-hardener.sh
```

</div>

<br>

---

## ⚙️ نیازمندی‌ها

| پلتفرم | نیازمندی‌ها |
|:------:|:------------|
| 🟦 **ویندوز** | PowerShell 3+ · ویندوز ۷/۸/۱۰/۱۱/Server · **اجرا با مدیر سیستم** |
| 🐧 **لینوکس** | bash · curl · دسترسی sudo · هر توزیع محبوب |

<br>

---

## 📜 مجوز

پروژه تحت مجوز **MIT** منتشر شده است. فایل [LICENSE](LICENSE) را ببینید.

<br>

<hr>

<br>

<p align="center"><strong>github.com/mohammadmehrani/MaddixSuite</strong></p>

</div>
