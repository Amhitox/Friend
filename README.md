# 🤝 Dostok - صاحبك الدري AI

<div dir="rtl">

**دوسطوك** - صاحبك لي كيدوي معاك بالدارجة المغربية! 🇲🇦

واش عيتي من الـ AI لي كيهضر غير بالإنجليزية وفرنسية؟ **دوسطوك** هنا باش يكون صاحبك لي كيتفهم معاك، كيدوي بلغتك، وكيشاركك نهارك.

</div>

---

<div align="center">

![Dostok Logo](screenshots/logo.png)

**Chat • Voice Calls • Daily Check-ins • Growing Friendship**

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=flat-square&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Android%20|%20iOS-purple?style=flat-square)

</div>

---

## 📖 علاش دوسطوك؟

<div dir="rtl">

**دوسطوك** هو تطبيق Flutter لي كيخليك تهضر مع AI بالدارجة المغربية. ماشي غير بوت عادي - هذا صاحب لي كيتعلم منك، كيكبر معاك، وكيعرف شنو كيعجبك.

كنستخدمو تقنيات الذكاء الاصطناعي المتقدمة باش نوفرو ليك تجربة حقيقية - كتحس بلي كتهضر مع صاحب حقيقي، ماشي مجرد ماكينة.

</div>

---

## ✨ المميزات

<div dir="rtl">

### 💬 الشات بالدارجة
- هضر مع **دوسطوك** بالدارجة المغربية ديالك بصح
- كيتفهم السياق وكيجاوب بطريقة طبيعية
- كيتعلم من أسلوبك في الهضرة مع الوقت

### 📞 المكالمات الصوتية
- عيط لـ **دوسطوك** ودوي معاه بالصوت
- تقنية Text-to-Speech بالدارجة
- كيسمع ليك وكيجاوبك كأنك كتهضر مع صاحب

### 🌅 Check-in يومي
- كل صباح كيسولك كيف صبحتي
- كيتبع مزاجك وكيشاركك النصائح
- تذكيرات باش تهضر معاه وما تنساهش

### 💚 صداقة كتكبر
- **دوسطوك** كيتعلم من كل محادثة
- مستوى الصداقة كيكبر مع الوقت
- كل ما هضرتي معاه، كل ما فهمك أكثر

### 🌙 الوضع الداكن (Dark Mode)
- تصميم عصري ومريح للعينين
- كيبدل بين الوضع العادي والداكن بسلاسة
- مثالي للهضرة بالليل

### 🇲🇦 الوعي الثقافي
- كيعرف بالعادات والتقاليد المغربية
- كيهضر بالدارجة الصحيحة
- كيحتارم القيم ديالنا وكيشاركك المناسبات

</div>

---

## 🚀 البداية

<div dir="rtl">

### المتطلبات

قبل ما تبدأ، تأكد عندك هاد الأشياء:

- **Flutter SDK** (3.0 أو أعلى)
- **Dart SDK** (3.0 أو أعلى)
- **Android Studio** أو **VS Code** مع إضافات Flutter
- حساب على **Google AI Studio** باش تاخذ API Key
- **Git** مثبت على جهازك

</div>

### التثبيت

```bash
# 1. استنسخ المشروع
git clone https://github.com/yourusername/dostok.git
cd dostok

# 2. نزل الـ dependencies
flutter pub get

# 3. ثبت Hive (للتخزين المحلي)
dart run build_runner build

# 4. شغّل التطبيق
flutter run
```

<div dir="rtl">

### إعداد الـ API

1. **خد API Key ديالك:**
   - سجل على [Google AI Studio](https://makersuite.google.com/app/apikey)
   - أنشئ API Key جديد

2. **configure الـ API Key:**

   إما بـ Environment Variable:
   ```bash
   export GEMINI_API_KEY="your_api_key_here"
   ```

   أو في ملف `.env`:
   ```
   GEMINI_API_KEY=your_api_key_here
   ```

3. **شغّل التطبيق** وتمتع بصاحبك الجديد! 🎉

</div>

---

## 🏗️ الهيكلة المعمارية (Architecture)

<div dir="rtl">

كنستخدمو نمط **Provider + Hive + Clean Architecture** باش نضمنو:

- **سهولة الصيانة** - الكود منظم وواضح
- **قابلية التوسع** - سهل نزيدو مميزات جداد
- **الأداء** - Hive للتخزين المحلي السريع
- **الفصل** - كل طبقة مسؤولة على شي حاجة

</div>

```
┌─────────────────────────────────────────────────────┐
│                   Presentation Layer                 │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │   Screens   │  │   Widgets    │  │   Themes   │ │
│  └──────┬──────┘  └──────┬───────┘  └─────┬──────┘ │
│         │                │                 │        │
│         └────────────────┼─────────────────┘        │
│                          │                           │
│                   ┌──────▼──────┐                    │
│                   │  Providers  │ (State Management) │
│                   └──────┬──────┘                    │
├──────────────────────────┼──────────────────────────┤
│                   Domain Layer                       │
│                   ┌──────▼──────┐                    │
│                   │   Models    │                    │
│                   │  Services   │                    │
│                   │ Repository  │                    │
│                   └──────┬──────┘                    │
├──────────────────────────┼──────────────────────────┤
│                    Data Layer                        │
│  ┌──────────────┐  ┌────▼─────┐  ┌───────────────┐ │
│  │  Hive (Local) │  │ API     │  │  Audio Service │ │
│  │  Storage      │  │ Service │  │  (TTS/STT)     │ │
│  └──────────────┘  └──────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────┘
```

---

## 📁 هيكلة المشروع (Project Structure)

```
darija_friend/
├── 📄 README.md
├── 📄 pubspec.yaml
├── 📄 .env.example
│
├── 📂 lib/
│   ├── 📄 main.dart                    # نقطة البداية
│   │
│   ├── 📂 config/
│   │   ├── 📄 app_theme.dart           # الثيمات (فاتح/داكن)
│   │   ├── 📄 constants.dart           # الثوابت
│   │   └── 📄 routes.dart              # التوجيه
│   │
│   ├── 📂 models/
│   │   ├── 📄 message.dart             # نموذج الرسالة
│   │   ├── 📄 conversation.dart        # نموذج المحادثة
│   │   ├── 📄 user_profile.dart        # نموذج المستخدم
│   │   └── 📄 friendship_level.dart    # مستوى الصداقة
│   │
│   ├── 📂 providers/
│   │   ├── 📄 chat_provider.dart       # إدارة حالة الشات
│   │   ├── 📄 theme_provider.dart      # إدارة الثيم
│   │   ├── 📄 friendship_provider.dart # إدارة الصداقة
│   │   └── 📄 settings_provider.dart   # الإعدادات
│   │
│   ├── 📂 services/
│   │   ├── 📄 gemini_service.dart      # خدمة Gemini API
│   │   ├── 📄 tts_service.dart         # Text-to-Speech
│   │   ├── 📄 stt_service.dart         # Speech-to-Text
│   │   ├── 📄 hive_service.dart        # التخزين المحلي
│   │   └── 📄 notification_service.dart # الإشعارات
│   │
│   ├── 📂 screens/
│   │   ├── 📄 chat_screen.dart         # شاشة الشات
│   │   ├── 📄 call_screen.dart         # شاشة المكالمات
│   │   ├── 📄 home_screen.dart         # الشاشة الرئيسية
│   │   ├── 📄 settings_screen.dart     # الإعدادات
│   │   └── 📄 onboarding_screen.dart   # البداية
│   │
│   ├── 📂 widgets/
│   │   ├── 📄 message_bubble.dart      # فقاعة الرسالة
│   │   ├── 📄 voice_button.dart        # زر الصوت
│   │   ├── 📄 friendship_indicator.dart # مؤشر الصداقة
│   │   ├── 📄 mood_emoji.dart          # إيموجي المزاج
│   │   └── 📄 daily_greeting.dart      # تحية يومية
│   │
│   └── 📂 utils/
│       ├── 📄 darija_prompts.dart      # Prompts بالدارجة
│       ├── 📄 helpers.dart             # دوال مساعدة
│       └── 📄 validators.dart          # التحقق
│
├── 📂 assets/
│   ├── 📂 images/
│   ├── 📂 animations/
│   └── 📂 sounds/
│
├── 📂 test/
│   ├── 📂 unit/
│   ├── 📂 widget/
│   └── 📂 integration/
│
└── 📂 screenshots/
    ├── 📄 chat_screen.png
    ├── 📄 voice_call.png
    ├── 📄 dark_mode.png
    └── 📄 friendship_level.png
```

---

## 📸 لقطات الشاشة (Screenshots)

<div dir="rtl">

> **ملاحظة:** هادو غير placeholders - غادي نحط الصور الحقيقية قريباً!

</div>

<div align="center">

### الشات بالدارجة
![Chat Screen](screenshots/chat_screen.png)

### المكالمات الصوتية
![Voice Call](screenshots/voice_call.png)

### الوضع الداكن
![Dark Mode](screenshots/dark_mode.png)

### مستوى الصداقة
![Friendship Level](screenshots/friendship_level.png)

</div>

---

## 🤝 المساهمة (Contributing)

<div dir="rtl">

كنرحب بأي مساعدة! إلا بغيتي تساهم، هاد الخطوات:

</div>

### كيفاش تساهم؟

1. **Fork** المشروع ديالنا
2. أنشئ **Branch** جديد لميزة لي بغيتي تزيد
   ```bash
   git checkout -b feature/ميزة-جديدة
   ```
3. دير **Commit** للتغييرات ديالك
   ```bash
   git commit -m "feat: زدت ميزة X بالدارجة"
   ```
4. **Push** للـ Branch ديالك
   ```bash
   git push origin feature/ميزة-جديدة
   ```
5. فتح **Pull Request** 🎉

<div dir="rtl">

### شنو نقدر نساهم فيه؟

- 🐛 **إصلاح bugs** - إلا لقيتي شي مشكل
- ✨ **ميزات جداد** - أفكار جديدة للتطبيق
- 🌍 **ترجمة** - زيد لغات أخرى أو حسّن الدارجة
- 📝 **توثيق** - حسّن الـ README أو أضف شروحات
- 🎨 **تصميم** - حسّن الـ UI/UX
- 🧪 **اختبارات** - زيد tests للتطبيق

### قواعد المساهمة:

- استعمل **الدارجة المغربية** فالتعليقات والمراجع
- تابع الـ **style guide** ديال المشروع
- تأكد بلي **كلشي خدام** قبل ما تدير PR
- اكتب **واصف واضح** للـ PR ديالك

</div>

---

## 📜 الرخصة (License)

<div dir="rtl">

هاد المشروع مرخص تحت رخصة **MIT**. يعني تقدر تستعملو، تعدلو، وتوزعو بحرية.

شوف ملف [LICENSE](LICENSE) للتفاصيل الكاملة.

</div>

```
MIT License

Copyright (c) 2024 Dostok Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 الشكر والتقدير

<div dir="rtl">

شكراً لكل لي ساهم فهاد المشروع:

- **Google Gemini** للذكاء الاصطناعي
- **Flutter** للفريمورك الرائع
- **المجتمع المغربي** للدعم والتشجيع
- **أنت** لأنك هنا وباغي تجرب **دوسطوك**! ❤️

</div>

---

<div align="center">

<div dir="rtl">

**دوسطوك - صاحبك لي كيتفهمك** 🤝🇲🇦

 Made with ❤️ in Morocco

</div>

[![Twitter](https://img.shields.io/badge/Twitter-@dostok-1DA1F2?style=flat-square&logo=twitter)](https://twitter.com/dostok)
[![Discord](https://img.shields.io/badge/Discord-Dostok%20Community-7289DA?style=flat-square&logo=discord)](https://discord.gg/dostok)

</div>
