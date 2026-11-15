# نصب آسان فلاتر

`fes` ابزار نصب و تعمیر فلاتر روی ویندوز، مک و لینوکس است.
آرشیو SDK را قبل از استخراج با SHA-256 بررسی می‌کند و پیش از تغییر PATH یا فایل راه‌انداز پوسته تأیید می‌گیرد.
داده‌ای به جایی ارسال نمی‌شود.

## نصب

فایل مناسب را از [آخرین انتشار](https://github.com/Ag1rin/flutter_easy_setup/releases/latest) بگیرید و با `SHA256SUMS` مقایسه کنید.

```bash
dart pub global activate flutter_easy_setup
fes --version
```

`install.ps1` و `install.sh` فایل را دانلود می‌کنند، جمع را بررسی می‌کنند و کپی می‌کنند. PATH را عوض نمی‌کنند.

## استفاده

اجرای `fes` بدون آرگومان منو را باز می‌کند. گزینه ۳ فلاتر را در `~/flutter` نصب می‌کند.

```bash
fes install --flutter-version 3.24.5 --channel stable --dry-run
fes doctor --json
fes path --undo
fes mirror list
fes mirror set china
fes use 3.24.5
fes create my_app --template state
```

`-v` نسخه خود `fes` را چاپ می‌کند. `--dry-run` چیزی نمی‌نویسد. `--yes` تغییر PATH، پذیرش مجوز و حذف را تأیید می‌کند.

منبع رسمی گوگل پیش‌فرض است. آینه‌های دیگر، از جمله `https://storage.flutter-io.cn`، فقط بعد از انتخاب شما استفاده می‌شوند. زبان منو با گزینه ۷ یا `--lang fa` عوض می‌شود.

## تفاوت با FVM و puro

FVM و puro نسخه فلاتر را داخل پروژه مشخص می‌کنند. `fes` ماشین را آماده می‌کند: SDK بررسی‌شده، PATH، JDK و ابزارهای خط فرمان اندروید. می‌توانید بعد از آماده‌سازی سیستم همچنان از FVM یا puro استفاده کنید.

## پرسش‌های doctor

اگر cmdline-tools نباشد، `fes doctor` بعد از تأیید ابزارهای خط فرمان اندروید را نصب می‌کند.

اگر مجوزهای اندروید پذیرفته نشده باشند، `fes` فقط بعد از تأیید دوباره به `sdkmanager --licenses` پاسخ `y` می‌دهد.

اگر قفل راه‌اندازی مانده باشد، فایل `~/flutter/bin/cache/lockfile` فقط بعد از تأیید حذف می‌شود.

## مستندات

- [English README](README.md)
- [مشارکت](CONTRIBUTING.md)
- [امنیت](SECURITY.md)
- [نقشه راه](ROADMAP.md)

نویسنده: Agirîn. مجوز: MIT.
