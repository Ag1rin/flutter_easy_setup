/// Persian user-facing strings. Plain Unicode, without bidi overrides.
const faMessages = <String, String>{
  'banner': 'ایزی ستاپ - نسخه {version}\nبه نصب آسان فلاتر خوش آمدید!',
  'opt1': '1. اجرای flutter doctor',
  'opt2': '2. بررسی Dart و Flutter و Android SDK',
  'opt3': '3. نصب بخش‌های جاافتاده یا راه‌اندازی کامل',
  'opt4': '4. بررسی و به‌روزرسانی',
  'opt5': '5. راهنمای نصب',
  'opt6': '6. درباره',
  'opt7': '7. Language / زبان',
  'opt0': '0. خروج',
  'select': 'یک گزینه انتخاب کنید (0-7):',
  'invalid': 'گزینه نامعتبر است. دوباره تلاش کنید.',
  'goodbye': 'خروج... خداحافظ!',
  'error': 'خطا: {message}. جزئیات در flutter_setup_log.txt است.',
  'doctorRunning': 'در حال اجرای flutter doctor...',
  'doctorDone': 'flutter doctor تمام شد.',
  'checking': 'در حال بررسی SDKها...',
  'flutterOk': 'Flutter نصب شده است.',
  'dartBundled': 'Dart همراه Flutter نصب شده است.',
  'flutterMissing': 'Flutter پیدا نشد.',
  'dartOk': 'Dart نصب شده است.',
  'dartMissing': 'Dart پیدا نشد.',
  'androidOk': 'ابزار Android SDK نصب شده است.',
  'androidMissing': 'ابزار Android SDK پیدا نشد.',
  'gitOk': 'Git نصب شده است.',
  'gitMissing': 'Git پیدا نشد. آن را از https://git-scm.com نصب کنید.',
  'skipDownload': 'Flutter از قبل نصب است. دانلود SDK رد شد.',
  'localFound': 'Flutter در {path} پیدا شد. دانلود رد شد.',
  'localOk': 'از نصب محلی Flutter استفاده می‌شود.',
  'localBroken':
      'پوشه Flutter هست ولی دستور flutter کار نمی‌کند. PATH را بررسی کنید.',
  'usingMirror': 'منبع Flutter: {url} (آینه: {id}).',
  'downloading': 'در حال دانلود Flutter {version} ({channel})...',
  'downloadDone': 'دانلود تمام شد!',
  'extracting': 'در حال استخراج Flutter...',
  'extracted': 'Flutter در {path} استخراج شد',
  'pathPrompt': 'Flutter برای همیشه به PATH اضافه شود؟',
  'pathWindows': r'متغیر PATH را این‌گونه به‌روز کنید: PATH += ;{path}',
  'pathUnix':
      'به ~/.zshrc یا ~/.bashrc اضافه کنید: export PATH="\$PATH:{path}"',
  'pathSource': 'سپس اجرا کنید: source ~/.zshrc یا source ~/.bashrc',
  'pathApplied': 'PATH به‌روز شد. یک ترمینال جدید باز کنید.',
  'pathUnchanged': 'Flutter از قبل در PATH است.',
  'pathUndo': 'نسخه پشتیبان PATH برای {target} برگردانده شد.',
  'setupDone': 'راه‌اندازی تمام شد. برای بررسی، گزینه 1 را بزنید.',
  'updateAsk': 'به‌روزرسانی بررسی شود؟ (Y/N)',
  'updating': 'در حال به‌روزرسانی Flutter و ابزارها...',
  'updateDone': 'به‌روزرسانی تمام شد!',
  'guideTitle': 'راهنمای نصب Flutter:',
  'guideBody':
      '1. Git را از https://git-scm.com نصب کنید\n'
      '2. این ابزار را اجرا کنید و گزینه 3 را بزنید\n'
      '3. flutter/bin را برای همیشه به PATH اضافه کنید\n'
      '4. flutter doctor را اجرا کنید\n'
      '5. مجوزهای اندروید فقط بعد از تایید شما پذیرفته می‌شوند\n'
      '6. برای iOS روی مک: Xcode و xcode-select --install\n'
      'راهنمای رسمی: https://docs.flutter.dev/get-started/install',
  'aboutTitle': 'درباره Flutter Easy Setup',
  'aboutVersion': 'نسخه: {version}',
  'aboutBody':
      'سازنده: Agirîn\n'
      'گیت‌هاب: https://github.com/Ag1rin/flutter_easy_setup\n'
      'این ابزار نصب Flutter و رفع خطاهای رایج را خودکار می‌کند.\n'
      'متن‌باز است و مشارکت شما خوشایند است.',
  'cliVersion': 'Flutter Easy Setup CLI {version}',
  'langSet': 'زبان روی {lang} تنظیم شد.',
  'dryRun': 'اجرای آزمایشی. این آدرس دانلود می‌شد: {url}',
  'confirm': '{prompt} (y/N)',
  'versionHeader': 'نسخه‌های نصب‌شده Flutter:',
  'versionNone': 'نسخه‌ای در {path} نیست.',
  'versionActive': '{version} (فعال) {path}',
  'versionItem': '{version} {path}',
  'removed': 'حذف شد: {path}',
  'removeRefused': 'نسخه فعال بدون --yes حذف نمی‌شود.',
  'useDone': 'حالا Flutter {version} فعال است.',
  'createDone': 'پروژه {name} با قالب {template} ساخته شد.',
  'createDry': 'اجرای آزمایشی. پروژه {name} با قالب {template} ساخته می‌شد.',
  'badName': 'نام پروژه باید مثل my_app باشد.',
  'selfSame': 'fes {version} آخرین نسخه است.',
  'selfAsk': 'fes {version} دانلود و جایگزین شود؟',
  'selfPub':
      'این نصب از pub است. اجرا کنید: dart pub global activate flutter_easy_setup',
  'selfStaged':
      'فایل در {path} ذخیره شد. fes را ببندید و جایگزین فایل فعلی کنید.',
  'selfDone': 'fes به {version} به‌روز شد.',
  'netOk': 'اتصال به {url} برقرار شد ({status}).',
  'netFail': 'اتصال به {url} ناموفق بود: {message}',
  'mirrorHeader': 'آینه‌ها (فعال: {id}):',
  'mirrorLine': '{mark} {id} storage={storage} pub={pub}',
  'mirrorSaved': 'آینه فعال شد: {id}. منبع: {storage}',
  'finding': '{id}: {summary}',
  'fixAsk': 'اصلاح {fix} انجام شود؟',
  'fixSkip': '{fix} رد شد.',
  'chromeHint': 'Chrome را از https://www.google.com/chrome/ نصب کنید.',
  'vsHint': 'Visual Studio را با workload توسعه دسکتاپ C++ نصب کنید.',
  'lockRemoved': 'قفل راه‌اندازی حذف شد.',
  'lockKept': 'قفل راه‌اندازی دست نخورده ماند.',
  'jdkDone': 'JDK در {path} نصب شد',
  'androidDone': 'Android SDK در {path} آماده است',
  'replaceAsk': 'SDK فلاتر در {path} جایگزین شود؟',
  'replaceSkipped': 'SDK فعلی دست نخورده ماند.',
  'envPrompt': 'این متغیرهای محیطی برای همیشه ذخیره شوند؟',
  'help':
      'کاربرد: fes [--version] [--lang en|fa] [--no-color] [--yes] [--dry-run]\n'
      '       fes install [--flutter-version x.y.z] [--channel stable|beta]\n'
      '       fes doctor [--json]\n'
      '       fes path [--undo]\n'
      '       fes mirror list|set <id>|reset\n'
      '       fes list | fes use <version> | fes remove <version>\n'
      '       fes create <name> [--template basic|state|clean]\n'
      '       fes update\n'
      '       fes net',
};
