<div dir="rtl" align="center">

# 📘 راهنمای استفاده از SysAdminSuite

**مدیکس‌سوئیت — ابزار همه‌کاره مدیریت و تعمیر سیستم‌عامل**

<br>

---

</div>

<div dir="rtl">

## 🚀 شروع سریع

<br>

### گزینه A: اجرای مستقیم از گیت‌هاب (بدون دانلود)

**ویندوز (PowerShell):**
<div dir="ltr">

```powershell
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows%20os/SysAdminSuite.ps1 | iex
```
</div>

**ویندوز (CMD):**
<div dir="ltr">

```batch
@powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows%20os/SysAdminSuite.cmd | iex"
```
</div>

**لینوکس:**
<div dir="ltr">

```bash
bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/SysAdminSuite.sh)
```
</div>

<br>

### گزینه B: دانلود و اجرا

**مراحل ویندوز:**
1. کلید **Win + X** را بزنید و **Windows PowerShell (Admin)** را انتخاب کنید
2. دستور زیر را اجرا کنید:
<div dir="ltr">

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows%20os/SysAdminSuite.ps1" -OutFile "$env:USERPROFILE\Desktop\SysAdminSuite.ps1"
```
</div>
3. روی فایل `SysAdminSuite.ps1` راست‌کلیک کنید → **Run with PowerShell**

**مراحل لینوکس:**
<div dir="ltr">

```bash
curl -O https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/SysAdminSuite.sh
chmod +x SysAdminSuite.sh
sudo ./SysAdminSuite.sh
```
</div>

<br>

### گزینه C: استفاده از فایل‌های Batch

- فایل **`run.cmd`** را دوبار کلیک کنید (اجرای اسکریپت محلی)
- فایل **`run-online.cmd`** را دوبار کلیک کنید (اجرای مستقیم از گیت‌هاب)

<br>

---

## 📋 توضیح گزینه‌های منو (ویندوز)

<br>

### 🛡️ بخش تعمیر و دیاگنوستیک

**1. ایجاد نقطه بازیابی سیستم**
یک نقطه بازیابی ویندوز می‌سازد تا در صورت بروز مشکل بتوانید تغییرات را برگردانید.

**2. اجرای دیاگنوستیک کامل**
SFC، DISM، CHKDSK و Event Logs را اجرا کرده و گزارش جامعی از سلامت سیستم ارائه می‌دهد.

**3. تعمیر فایل‌های سیستم (SFC)**
همه فایل‌های محافظت شده سیستم را اسکن کرده و نسخه‌های خراب را با نسخه سالم جایگزین می‌کند.

**4. تعمیر ایمیج سیستم (DISM)**
ایمیج ویندوز را با استفاده از Windows Update تعمیر می‌کند.

**5. DISM با آپدیت آنلاین**
مانند گزینه ۴ اما با سورس آنلاین Windows Update برای دانلود فایل‌های سالم.

**6. بررسی دیسک (CHKDSK)**
درایو سیستم را برای خطاهای فایل سیستمی و سکتورهای بد اسکن می‌کند.

**7. تعمیر رکوردهای بوت**
MBR (Master Boot Record) و BCD (Boot Configuration Data) را تعمیر می‌کند.

**8. بازنشانی Windows Update**
سرویس‌های Windows Update را متوقف، کش را پاک و سرویس‌ها را مجدداً راه‌اندازی می‌کند.

<br>

### 🔌 بخش مدیریت درایور

**9. نمایش تمام درایورها**
لیست کاملی از تمام درایورهای نصب شده با وضعیت و نسخه نمایش می‌دهد.

**10. بروزرسانی درایورها**
از طریق Windows Update به‌روزرسانی درایورها را جستجو می‌کند.

**11. حذف درایورهای مشکل‌دار**
درایورهایی که وضعیت "OK" یا "Running" ندارند را شناسایی و حذف می‌کند.

**12. بکاپ درایورها**
تمامی درایورهای نصب شده را با دستور `Export-WindowsDriver` خروجی می‌گیرد.

**13. بازیابی درایورها**
درایورها را از بکاپ قبلی بازیابی می‌کند.

<br>

### 🧹 بخش پاکسازی و بهینه‌سازی

**14. پاکسازی کش سیستم**
فایل‌های موقت (Temp)، Prefetch، کش DNS و لاگ‌ها را پاک می‌کند.

**15. پاکسازی دیسک**
ابزار داخلی Disk Cleanup ویندوز را اجرا می‌کند.

**16. پاکسازی Prefetch**
فایل‌های Prefetch که باعث کاهش سرعت بوت می‌شوند را حذف می‌کند.

**17. بهینه‌سازی عملکرد**
تنظیمات زیر را اعمال می‌کند:
- غیرفعال کردن جلوه‌های بصری غیرضروری
- تنظیم Power Plan روی High Performance
- کاهش زمان تایم‌اوت سرویس‌ها
- غیرفعال کردن سرویس‌های Xbox

**18. بهینه‌سازی SSD**
دستور Optimize-Volume با پارامتر ReTrim را روی درایوهای SSD اجرا می‌کند.

<br>

### 💾 بخش بکاپ و ریستور

**19. بکاپ کامل سیستم**
بکاپ جامع از موارد زیر می‌گیرد:
- رجیستری (تمامی هایوها)
- درایورها
- BCD (Boot Configuration Data)
- Task Scheduler
- پروفایل‌های شبکه و WiFi
- فایل Hosts
- متغیرهای محیطی

**20. بکاپ رجیستری**
از هایوهای `HKLM\Software`، `HKCU\Software`، `HKLM\System`، `HKLM\SAM`، `HKLM\Security` خروجی می‌گیرد.

**21. بازیابی رجیستری**
رجیستری را از بکاپ انتخاب شده بازیابی می‌کند (با تایید امنیتی).

**22. نمایش نقاط بازیابی**
لیست تمام Restore Pointهای موجود در سیستم را نمایش می‌دهد.

<br>

### 🌐 بخش شبکه و امنیت

**23. دیاگنوستیک شبکه**
عملیات زیر را انجام می‌دهد:
- Ping به ۸.۸.۸.۸، ۱.۱.۱.۱، google.com و github.com
- DNS Lookup
- نمایش اینترفیس‌های شبکه فعال
- Traceroute

**24. بازنشانی شبکه**
کل استک شبکه را ریست می‌کند:
- `netsh int ip reset`
- `netsh winsock reset`
- `netsh advfirewall reset`
- `ipconfig /release` و `/renew`
- `ipconfig /flushdns`

**25. اسکن آنتی‌ویروس**
Windows Defender را با اسکن سریع (Quick Scan) اجرا می‌کند.

**26. وضعیت فایروال**
وضعیت پروفایل‌های فایروال و قوانین ورودی را نمایش می‌دهد.

<br>

### ⚙️ بخش ابزارهای سیستمی

**27. اطلاعات سیستم**
مشخصات کامل سخت‌افزاری و نرم‌افزاری: CPU، RAM، GPU، دیسک، سریال BIOS.

**28. سلامت سیستم**
وضعیت Activation ویندوز، uptime، بررسی pending reboot.

**29. مدیریت سرویس‌ها**
زیرمنوی ویژه برای: لیست سرویس‌ها، غیرفعال/فعال کردن، start/stop/restart.

**30. مدیریت Startup**
برنامه‌هایی که با ویندوز شروع می‌شوند را نمایش می‌دهد.

**31. گزارش باتری**
برای لپ‌تاپ‌ها: گزارش سلامت باتری با دستور `powercfg /batteryreport`.

**32. سلامت دیسک (SMART)**
وضعیت فیزیکی دیسک‌ها، خطاهای خوانده نشده و درصد فرسودگی (Wear) را نمایش می‌دهد.

**33. دیاگنوستیک رم**
ابزار Windows Memory Diagnostic را برای اجرا در بوت بعدی زمان‌بندی می‌کند.

<br>

### 📊 بخش عمومی

**34. تولید گزارش**
یک گزارش حرفه‌ای HTML و TXT از دیاگنوستیک‌های انجام شده تولید می‌کند.

**35. اجرای همه**
تمامی عملیات تعمیر و بهینه‌سازی را پشت سر هم اجرا می‌کند.
> **توصیه می‌شود:** اگر سیستم شما مشکل دارد، این گزینه را انتخاب کنید.

<br>

---

## 📍 محل ذخیره‌سازی گزارش‌ها

پس از اجرای دیاگنوستیک، گزارش‌ها در مسیر زیر ذخیره می‌شوند:

<div dir="ltr">

```
%USERPROFILE%\Desktop\MaddixSuite\Reports\MaddixSuite_Report_YYYYMMDD_HHmmss\
├── Report.txt
└── Report.html
```
</div>

فایل `Report.html` را در مرورگر باز کنید تا نتایج رنگی و فرمت‌بندی شده را مشاهده کنید.

<br>

---

## 📍 محل ذخیره‌سازی بکاپ‌ها

بکاپ‌ها در مسیر زیر ذخیره می‌شوند:

<div dir="ltr">

```
%USERPROFILE%\Desktop\MaddixSuite\Backups\Backup_YYYYMMDD_HHmmss\
├── Registry\        ← فایل‌های .reg
├── Drivers\         ← درایورهای خروجی گرفته شده
├── BCD.bak          ← بکاپ بوت
├── Tasks.xml        ← وظایف زمان‌بندی شده
├── network.txt      ← کانفیگ شبکه
├── WiFi\            ← پروفایل‌های وای‌فای
├── hosts.backup     ← فایل Hosts
├── EnvVars.xml      ← متغیرهای محیطی
└── checksums.md5    ← چک‌سام فایل‌ها
```
</div>

<br>

---

## ⚠️ نکات امنیتی

- **همیشه** اسکریپت را با دسترسی مدیر سیستم (Administrator) اجرا کنید
- قبل از اعمال تغییرات besar، **نقطه بازیابی** ایجاد کنید (گزینه ۱)
- در بازیابی رجیستری، از صحت بکاپ اطمینان حاصل کنید
- فایل‌های بکاپ را در یک مکان امن (خارج از سیستم) ذخیره کنید

<br>

---

## 🐧 نکات ویژه لینوکس

- اسکریپت لینوکس به طور خودکار توزیع شما را تشخیص می‌دهد
- برای بعضی عملیات نیاز به دسترسی `sudo` دارید
- توزیع‌های پشتیبانی شده: Debian, Ubuntu, Linux Mint, Fedora, RHEL, CentOS, Arch Linux, Manjaro, openSUSE
- برای Alpine Linux از `apk` پشتیبانی محدودی وجود دارد

<br>

---

<div align="center">

**برای گزارش مشکلات یا پیشنهادات، به [گیت‌هاب پروژه](https://github.com/mohammadmehrani/MaddixSuite) مراجعه کنید.**

</div>

</div>
