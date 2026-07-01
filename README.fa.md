<div dir="rtl" align="center">

# 🛠️ مدیکس‌سوئیت (MaddixSuite)

**مجموعه‌ای قدرتمند از ابزارهای مدیریت، تعمیر و بهینه‌سازی سیستم‌عامل**  
_ساخته شده توسط **محمد مهرانی (Maddix)**_

---

[![مجوز: MIT](https://img.shields.io/badge/%D9%84%D8%A7%DB%8C%D8%B3%D9%86%D8%B3-MIT-2ea44f?style=for-the-badge&labelColor=1a1a2e)](LICENSE)
[![پاورشل](https://img.shields.io/badge/PowerShell-3%2B-5391FE?style=for-the-badge&logo=PowerShell&logoColor=white&labelColor=1a1a2e)]()
[![ویندوز](https://img.shields.io/badge/Windows-7%2F8%2F10%2F11-00a8e8?style=for-the-badge&logo=Windows&logoColor=white&labelColor=1a1a2e)]()
[![لینوکس](https://img.shields.io/badge/Linux-%DB%8C%D9%88%D9%86%DB%8C%D9%88%D8%B1%D8%B3%D8%A7%D9%84-E95420?style=for-the-badge&logo=Linux&logoColor=white&labelColor=1a1a2e)]()
[![گیت‌هاب](https://img.shields.io/badge/GitHub-mohammadmehrani-181717?style=for-the-badge&logo=GitHub&logoColor=white&labelColor=1a1a2e)](https://github.com/mohammadmehrani/MaddixSuite)

<br>

---

## ✨ معرفی

**مدیکس‌سوئیت** یک مجموعه ابزار کراس‌پلتفرم (چندسکویی) برای مدیریت، عیب‌یابی، تعمیر و بهینه‌سازی سیستم‌عامل است.  
این پروژه شامل اسکریپت‌های حرفه‌ای برای **ویندوز** (PowerShell و CMD) و **لینوکس** (Bash) می‌باشد.

<br>

---

## 📋 فهرست مطالب

- [🔧 اسکریپت‌های موجود](#-اسکریپت‌های-موجود)
- [🚀 اجرای یک‌خطی از گیت‌هاب](#-اجرای-یک‌خطی-از-گیت‌هاب)
- [📌 قابلیت‌های ویندوز (۳۵ گزینه)](#-قابلیت‌های-ویندوز-۳۵-گزینه)
- [🐧 قابلیت‌های لینوکس (۱۹ گزینه)](#-قابلیت‌های-لینوکس-۱۹-گزینه)
- [📦 ساختار پروژه](#-ساختار-پروژه)
- [⚙️ نیازمندی‌ها](#️-نیازمندی‌ها)
- [📜 مجوز](#-مجوز)

<br>

---

## 🔧 اسکریپت‌های موجود

<br>

<div align="center">

| اسکریپت | پلتفرم | توضیحات |
|:--------:|:------:|:---------|
| 🟦 `SysAdminSuite.ps1` | ویندوز (PowerShell) | ابزار همه‌کاره با **۳۵ قابلیت** — دیاگنوستیک، تعمیر، بکاپ، شبکه، امنیت، بهینه‌سازی |
| 🟨 `SysAdminSuite.cmd` | ویندوز (CMD/Batch) | نسخه سبک CMD با **۱۸ ابزار ضروری** |
| 🧩 `Backup-Restore.ps1` | ویندوز (PowerShell) | ابزار مستقل بکاپ و ریستور کامل از سیستم |
| 🐧 `SysAdminSuite.sh` | لینوکس (Bash) | ابزار جهانی لینوکس — تشخیص خودکار توزیع (دبیان، اوبونتو، آرچ، فدورا، openSUSE) |

</div>

<br>

---

## 🚀 اجرای یک‌خطی از گیت‌هاب

> بدون نیاز به دانلود! مستقیماً از گیت‌هاب اجرا کنید.

<br>

### 🟦 ویندوز — SysAdminSuite (PowerShell)

<div dir="ltr">

```powershell
# ابزار کامل با ۳۵ گزینه
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows%20os/SysAdminSuite.ps1 | iex

# ابزار بکاپ و ریستور
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows%20os/Backup-Restore.ps1 | iex
```

</div>

<br>

### 🟨 ویندوز — SysAdminSuite (CMD)

<div dir="ltr">

```batch
@powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows%20os/SysAdminSuite.cmd | iex"
```

</div>

<br>

### 🐧 لینوکس — SysAdminSuite

<div dir="ltr">

```bash
bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/SysAdminSuite.sh)
```

</div>

<br>

---

## 📌 قابلیت‌های ویندوز (۳۵ گزینه)

<br>

<div align="right">

### 🛡️ تعمیر و دیاگنوستیک
| # | عملیات | توضیح |
|:-:|:-------|:-------|
| ۱ | ایجاد نقطه بازیابی | یک نقطه بازیابی سیستم قبل از تغییرات می‌سازد |
| ۲ | دیاگنوستیک کامل | اجرای SFC + DISM + CHKDSK + بررسی Event Logs |
| ۳ | تعمیر فایل‌های سیستم (SFC) | اسکن و تعمیر فایل‌های سیستمی خراب |
| ۴ | تعمیر ایمیج سیستم (DISM) | بازگردانی سلامت ایمیج ویندوز |
| ۵ | DISM با آپدیت آنلاین | تعمیر با سورس Windows Update |
| ۶ | بررسی دیسک (CHKDSK) | اسکن خطاهای فایل سیستمی و سکتورهای بد |
| ۷ | تعمیر بوت (MBR/BCD) | رفع مشکلات بوت‌لودر و رکوردهای بوت |
| ۸ | ریست آپدیت ویندوز | بازنشانی کامل کامپوننت‌های Windows Update |

### 🔌 مدیریت درایور
| # | عملیات | توضیح |
|:-:|:-------|:-------|
| ۹ | لیست درایورها | نمایش تمام درایورهای نصب شده |
| ۱۰ | بروزرسانی درایورها | اسکن درایورها از Windows Update |
| ۱۱ | حذف درایورهای مشکل‌دار | پاک کردن درایورهای خراب و معیوب |
| ۱۲ | بکاپ درایورها | خروجی گرفتن از تمام درایورها |
| ۱۳ | Restore درایورها | بازیابی درایورها از بکاپ |

### 🧹 پاکسازی و بهینه‌سازی
| # | عملیات | توضیح |
|:-:|:-------|:-------|
| ۱۴ | پاکسازی کش | حذف Temp, Prefetch, DNS Cache |
| ۱۵ | پاکسازی دیسک | اجرای ابزار Disk Cleanup (cleanmgr) |
| ۱۶ | پاکسازی Prefetch | حذف فایل‌های Prefetch |
| ۱۷ | بهینه‌سازی عملکرد | تنظیمات power plan، سرویس‌ها، جلوه‌های بصری |
| ۱۸ | بهینه‌سازی SSD | اجرای ReTrim روی درایوهای SSD |

### 💾 بکاپ و ریستور
| # | عملیات | توضیح |
|:-:|:-------|:-------|
| ۱۹ | بکاپ کامل سیستم | بکاپ رجیستری، درایورها، BCD، تسک‌ها، شبکه |
| ۲۰ | بکاپ رجیستری | خروجی از تمام هایوهای رجیستری |
| ۲1 | Restore رجیستری | بازیابی رجیستری از بکاپ (با هشدار) |
| ۲۲ | نمایش نقاط بازیابی | لیست تمام Restore Pointهای موجود |

### 🌐 شبکه و امنیت
| # | عملیات | توضیح |
|:-:|:-------|:-------|
| ۲۳ | دیاگنوستیک شبکه | Ping, DNS Lookup, Traceroute |
| ۲۴ | بازنشانی شبکه | ریست Winsock, IP, Firewall |
| ۲۵ | اسکن آنتی‌ویروس | Windows Defender Quick Scan |
| ۲۶ | وضعیت فایروال | نمایش قوانین ورودی و وضعیت پروفایل‌ها |

### ⚙️ ابزارهای سیستمی
| # | عملیات | توضیح |
|:-:|:-------|:-------|
| ۲۷ | اطلاعات سیستم | CPU, RAM, GPU, Disk, Serial |
| ۲۸ | سلامت سیستم | وضعیت Activation, Uptime, Pending Reboot |
| ۲۹ | مدیریت سرویس‌ها | Start/Stop/Disable/Enable سرویس‌ها |
| ۳۰ | مدیریت Startup | نمایش برنامه‌های شروع‌شونده با سیستم |
| ۳۱ | گزارش باتری | تولید گزارش سلامت باتری (لپ‌تاپ) |
| ۳۲ | سلامت دیسک (SMART) | نمایش وضعیت فیزیکی دیسک‌ها |
| ۳۳ | دیاگنوستیک رم | زمان‌بندی Memory Diagnostic برای بوت بعدی |

### 📊 عمومی
| # | عملیات | توضیح |
|:-:|:-------|:-------|
| ۳۴ | گزارش دیاگنوستیک | تولید گزارش HTML و TXT |
| ۳۵ | اجرای همه | اجرای تمام تعمیرات و بهینه‌سازی‌ها |

</div>

<br>

---

## 🐧 قابلیت‌های لینوکس (۱۹ گزینه)

<br>

<div align="right">

| # | دسته | عملیات | توضیح |
|:-:|:----:|:--------|:-------|
| ۱ | 🔧 تعمیر | رفع Package Manager | تعمیر apt/dnf/pacman/zypper |
| ۲ | 🔧 تعمیر | رفع پکیج‌های خراب | نصب مجدد و رفع وابستگی‌های شکسته |
| ۳ | 🔧 تعمیر | رفع بوت‌لودر (GRUB) | به‌روزرسانی GRUB و بازسازی کانفیگ |
| ۴ | 🔧 تعمیر | بررسی فایل‌سیستم | زمان‌بندی fsck برای بوت بعدی |
| ۵ | 🔧 تعمیر | رفع Systemd Services | ریست و راه‌اندازی مجدد سرویس‌های failed |
| ۶ | 🌐 شبکه | دیاگنوستیک شبکه | نمایش اینترفیس‌ها، روتینگ، DNS |
| ۷ | 🌐 شبکه | دیاگنوستیک DNS | تست Ping به سرورهای DNS |
| ۸ | 🧹 پاکسازی | پاکسازی سیستم | پکیج‌های اضافی، تمپ، Journal |
| ۹ | 🧹 پاکسازی | پاکسازی Journal | خلاصه‌سازی لاگ‌های سیستم |
| ۱۰ | ⚡ بهینه‌سازی | تنظیم Swappiness | کاهش Swappiness به ۱۰ برای SSD |
| ۱۱ | ⚡ بهینه‌سازی | پارامترهای کرنل | تنظیمات TCP, Cache, Dirty Ratio |
| ۱۲ | 💾 بکاپ | بکاپ لیست پکیج‌ها | ذخیره لیست پکیج‌های نصب شده |
| ۱۳ | 💾 بکاپ | بکاپ کانفیگ‌ها | بکاپ etc, home, cron |
| ۱۴ | ♻️ Restore | بازیابی پکیج‌ها | نصب مجدد پکیج‌ها از بکاپ |
| ۱۵ | 🔒 امنیت | بررسی امنیتی | پورت‌های باز، SSH failed، آخرین لاگین‌ها |
| ۱۶ | ❤️ سلامت | سلامت سیستم | uptime, memory, disk, zombie processes |
| ۱۷ | ℹ️ اطلاعات | اطلاعات سیستم | کرنل، CPU، RAM، تعداد پکیج‌ها |
| ۱۸ | 📦 عمومی | اجرای همه | اجرای تمام تعمیرات |
| ۱۹ | ℹ️ عمومی | نسخه و بروزرسانی | نمایش ورژن و لینک آپدیت |

</div>

<br>

---

## 📦 ساختار پروژه

<br>

<div dir="ltr">

```
MaddixSuite/
│
├── 📄 README.md                 # مستندات انگلیسی
├── 📄 README.fa.md              # ← مستندات فارسی (همین فایل)
├── 📄 LICENSE                   # مجوز MIT
│
├── 🏃 run.cmd                   # لانچر محلی ویندوز
├── 🏃 run-online.cmd            # لانچر آنلاین ویندوز
│
├── 📂 windows os/               # ← ابزارهای ویندوز
│   ├── 🟦 SysAdminSuite.ps1    # ابزار اصلی (۳۵ گزینه)
│   ├── 🟨 SysAdminSuite.cmd    # نسخه CMD (۱۸ گزینه)
│   └── 🧩 Backup-Restore.ps1   # ابزار بکاپ مستقل
│
├── 📂 linux/                    # ← ابزارهای لینوکس
│   └── 🐧 SysAdminSuite.sh     # ابزار جهانی لینوکس
│
└── 📂 docs/                     # مستندات
    └── 📄 usage.md             # راهنمای استفاده
```

</div>

<br>

---

## ⚙️ نیازمندی‌ها

<br>

<div align="center">

| پلتفرم | نیازمندی‌ها |
|:-------|:------------|
| 🟦 **ویندوز** | PowerShell 3.0+ | ویندوز ۷/۸/۱۰/۱۱ یا سرور ۲۰۱۲+ | **اجرا با مدیر سیستم (Admin)** |
| 🐧 **لینوکس** | bash + curl | هر توزیع دبیان/اوبونتو/آرچ/فدورا/openSUSE | دسترسی sudo برای برخی عملیات |

</div>

<br>

---

## 📜 مجوز

این پروژه تحت مجوز **MIT** منتشر شده است — برای جزئیات بیشتر فایل [LICENSE](LICENSE) را مشاهده کنید.

<br>

---

<div align="center">

**ساخته شده با ❤️ توسط محمد مهرانی (Maddix)**

[![GitHub](https://img.shields.io/badge/GitHub-mohammadmehrani-181717?style=for-the-badge&logo=GitHub)](https://github.com/mohammadmehrani)

</div>

<br>

---

> **نکته:** برای مشاهده مستندات انگلیسی به [README.md](README.md) مراجعه کنید.

</div>
