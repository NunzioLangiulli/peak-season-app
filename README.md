# Peak Season – Seasonal Fruit & Vegetable App

**Peak Season** tells you what is in season **in your area, this month**, when a product is at its **peak**, how to choose it, how to store it and what its environmental footprint is. The app works **fully offline**, in **English or Italian**, and is built on the *Peak Season – Seasonal Fruit & Vegetable Database* ([peak-season-database](https://github.com/NunzioLangiulli/peak-season-database)): 153 products, 46 official sources, no invented data.

Flutter app for Android and iPhone (iPhone via sideloading, see below). **Current version: 1.1.0.** Versions follow semantic versioning (MAJOR.MINOR.PATCH).

---

## Features

### Home: what is in season right now

- **Month selector**, starting from today, with a quick summary ("12 at peak season · 38 in season").
- **Three views:**
  - **Grid** with photos and seasonal state;
  - compact **List**, with climacteric/non-climacteric badges and carbon and water footprint;
  - **12-Month Calendar**: every product at a glance, with the selected month in the middle.
- **Search** by name (Italian, English, synonyms).
- Multi-select **categories**: All, Fruit, Vegetables, Other (herbs and spices, mushrooms, cereals).
- **Advanced filters:** seasonal state in the selected month, PDO/PGI only, favourites only, shopping list only, hidden products.
- **Sorted by seasonality**: peak first, then in season, early season, end of season.

### Seven seasonal states, with growth icons

| State | Meaning |
|---|---|
| **Early Season** | start of the season, first harvests |
| **In Season** | regular availability |
| **Peak Season** | the central months on which all sources agree |
| **End of Season** | last harvests or naturally stored produce |
| **Out of Season** | heated greenhouse or long-distance import |
| **Not Grown Here** | exotic fruit with no production in the area |
| **No Data Available** (grey, "?") | no source covers your area: it does **not** mean out of season |

When your area has no data, the app can show the **estimate from the neighbouring climate zone**, marked with **≈**. The estimate comes from the database, not from the app, and can be turned off in Settings.

### Your area

- **Italian area (local, "Km 0"):** North, Centre (including Abruzzo), South and Islands, or the generic Mediterranean zone.
- **European climate zone (EUFIC):** Mediterranean, Continental, Atlantic, Boreal, Alpine, Pannonian, with the EEA **biogeographical regions map** and the list of countries in each zone.
- If you pick a zone with no calendar of its own, the app tells you which **reference calendar** it is using.

### Product page

A complete product page, split into blocks that you can **reorder, collapse or hide** from Settings:

- **Gallery** with several photo types (main photo, plant in the field, botanical plate, cross-section), including full screen, with author and licence.
- **Seasonal calendar** of the year for your area, with a legend and an explanation of *how seasonality was computed* for that product.
- **Varieties and territories:** notable varieties, **PDO/PGI** verified against the EU register, Traditional Agri-food Products by region, Slow Food Presidia.
- **Buying, ripening and storage:**
  - how to choose it;
  - **climacteric / non-climacteric**, i.e. whether it keeps ripening after harvest;
  - how to ripen it and how to slow down spoilage;
  - **where to store it** (fridge, room temperature, pantry…) and **how long it lasts** at room temperature, in the fridge and in the freezer;
  - **perishability** on 6 levels;
  - **what to keep it away from** (ethylene-producing products).
- **Nutrition facts** per 100 g, **vitamins and minerals as % NRV**, **EU nutrition claims** grouped and colour-coded according to Regulation (EC) 1924/2006, allergens and portions.
- **Sustainability:** carbon and water footprint, compared with beef.
- **Garden calendar:** sowing, transplanting and harvest for Northern, Central and Southern Italy.
- **More information:** benefits, curiosities, anti-waste tips.
- **Sources and useful links:** every source with its acronym or logo and a direct link to the page used.
- **Botanical family:** other products of the same family, sorted by seasonality.
- **"?"** buttons with a glossary and explanations of technical terms.

### Your lists

- **❤️ Favourites**, **🚫 I Don't Eat It** (hidden from Home, but recoverable) and **📋 Shopping list**.
- The **Shopping list** shows whether each product is in season this month.

### Notifications (Android; on iPhone, alerts only)

- **Shopping mode:** a persistent notification, visible on the lock screen too, with what is in season. If you have a shopping list, the notification highlights your items or shows only those.
- **After-shopping tips:** when you close shopping mode, a notification arrives, immediately or after a 0–60 minute delay, and opens **storage tips** for what you bought.
- **"Peak Season" alerts:** on the first of every month at 9 a.m., what is entering its peak. Choose between no alerts, favourites only, or everything except what you don't eat.

### More Sustainable Diet

A page explaining, with EUFIC's key points, why eating seasonally matters and when it is not enough, for example with heated greenhouses, air freight or long cold storage.

### Personalisation

- **Language:** English or Italian. The whole app, data included, switches to the chosen language.
- **Theme:** light, dark (AMOLED black) or system.
- Adjustable **frosted-glass effect** and **background tints** (Green, Green & Teal, Green & Amber, None).
- **Order and visibility** of the product page blocks (long-press and drag).

---

## Installing on Android

1. Download the `.apk` file from the latest version in the **Releases** section of this repository.
2. Open it on your phone. If Android asks, allow installs from this source.
3. In Settings, choose your language and area (Northern Italy is the default).

The app does not need an internet connection, except to open the source links.

---

## Installing on iPhone (sideloading, free)

The app is not on the App Store. Each release also includes an **unsigned** `.ipa` file, built automatically by GitHub Actions. You sign it with **your own free Apple ID** while installing it.

1. Download `PeakSeason-<version>-unsigned.ipa` from the latest version in the **Releases** section.
2. Install it with one of these tools:
   - **[Sideloadly](https://sideloadly.io/)** (Windows or macOS): connect the iPhone with a cable, drag the `.ipa` into Sideloadly, enter your Apple ID and press *Start*.
   - **[AltStore](https://altstore.io/)** or **[SideStore](https://sidestore.io/)**: install it once, then open the `.ipa` from the iPhone.
3. On the iPhone:
   - trust your Apple ID under *Settings → General → VPN & Device Management*;
   - turn on *Settings → Privacy & Security → Developer Mode* (iOS 16 and later) and restart.

**Limits of a free Apple ID** (Apple rules, not app rules):

- the app **expires after 7 days** and must be signed again. AltStore and SideStore can refresh it automatically; with Sideloadly, install it again. Your favourites, lists and settings are kept;
- at most **3 sideloaded apps** can be active at the same time.

On iPhone, the persistent shopping-mode notification is not available, because iOS does not support it. Peak Season alerts and storage tips work as normal notifications.

---

## For developers

### Requirements

- Flutter 3.47 (Dart 3.13), Android SDK with licences accepted (`flutter doctor --android-licenses`)

### Commands

```bash
flutter pub get
flutter analyze
flutter test              # tests on the real database, resolver, filters, texts and icons
flutter run               # connected phone or emulator
flutter run -d chrome     # quick browser preview (no notifications)
flutter build apk --release
```

The iOS build needs macOS and Xcode. The `.github/workflows/ios.yml` workflow builds it on a free GitHub macOS runner with `flutter build ios --release --no-codesign`, then packages it as an unsigned `.ipa`. It runs by hand from the **Actions** tab, where the `.ipa` is kept as a workflow artifact, and every time a release is published, when the `.ipa` is attached to the release.

### Architecture

```
lib/
  main.dart                startup, providers, theme
  models/                  FoodItem (null-safe JSON parsing), SeasonState, zone and area enums, claims, glossary
  data/                    FoodRepository (loads the database in an isolate and resolves the shared corpus),
                           SeasonalityResolver (exact data → ≈ estimate if enabled → not grown → unknown)
  providers/               settings, favourites/lists, Home, product page layout, notifications, navigation
  screens/                 Home, product page, family, shopping list, storage tips,
                           More Sustainable Diet, settings
  widgets/                 cards, calendars, zone map, filters, gallery, source badges…
  notifications/           notification content and scheduling
  l10n/                    CopyService + S facade: every text comes from assets/data/ui_copy.json
  theme/                   Material 3 theme, state palette, IconService (icons from ui_config.json)
assets/
  data/                    database.json (minified), ui_copy.json, ui_config.json
  images/thumb, full       WebP photos (600 px for cards, 1080 px for the gallery)
  icons/, maps/, sources/  state icons, maps, source logos
```

**Principles:**

- **The app does not invent data.** Every display rule (colours, thresholds, calendar order, claim rules, storage order) comes from the database `metadata`.
- **No hard-coded text.** All texts live in `assets/data/ui_copy.json` (IT/EN) and all icons in `assets/data/ui_config.json`. They can be edited without coding through the Admin Studio in the database repository; tests check that the keys match.
- **Assets are generated from the database.** After every change to the database or photos, run `scripts/build_app_assets.py` in the database repository, which updates `assets/data/` and the WebP images.

### Credits

- Data: see the sources listed in the database (CREA, BDA-IEO, EUFIC, UC Davis, USDA, SU-EATABLE LIFE and others).
- Photos: Wikimedia Commons, USDA ARS, Unsplash, Pixabay, iNaturalist. Author and licence of every photo are shown in the app.
- Zone map: EEA Biogeographical Regions 2016 (CC BY 4.0) and Natural Earth.

### Licence (open source)

- **App code:** [MIT](LICENSE).
- **Data** (`assets/data/database.json`): CC BY 4.0, as in the database repository, with each source's own terms for third-party values.
- **Photos** (`assets/images/`): each photo carries its author's licence (public domain, CC0, CC BY, CC BY-SA, Unsplash, Pixabay), shown in the app and in the database repository.
- **Source logos** (`assets/sources/`): owned by the respective organisations and used only to identify the source.

Non-commercial project. This information is for general educational purposes and is not a substitute for advice from a doctor or nutritionist.
