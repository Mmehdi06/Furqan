<p align="center">
  <img src="Furqan/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="120" height="120" style="border-radius: 22px;" alt="Furqan App Icon">
</p>

<h1 align="center">Furqan</h1>

<p align="center">
  <em>Mushaf-style Quran reader for iPhone</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS_18.2+-blue?style=flat-square&logo=apple" alt="Platform">
  <img src="https://img.shields.io/badge/UI-SwiftUI-orange?style=flat-square&logo=swift" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Widgets-WidgetKit-lightblue?style=flat-square" alt="WidgetKit">
  <img src="https://img.shields.io/badge/Data-Offline_SQLite-green?style=flat-square" alt="Offline SQLite">
  <img src="https://img.shields.io/badge/License-Private-lightgrey?style=flat-square" alt="License">
</p>

---

Furqan is an offline Quran reader for iPhone that presents the Quran in a Medina mushaf-style page layout. It uses Quran Printing Complex page fonts for the 604-page reading experience, supports tajweed color rendering, includes Arabic search, translations, tafsir, surah background information, saved ayahs with private notes, reading plans, reading statistics, and home-screen widgets.

## What The App Does

### Reading Experience

- Displays the Quran as 604 fixed mushaf pages.
- Uses one QPC page font per mushaf page from `Furqan/Resources/Fonts/QPC/`.
- Renders each page as 15 mushaf lines with page-specific Arabic typography.
- Supports ayah lines, basmallah lines, and surah header lines.
- Shows surah headers using `QCF_SurahHeader_COLOR-Regular.ttf`.
- Shows basmallah text using `UthmanicHafs_V22.ttf`.
- Opens to the last-read page using `UserDefaults` key `quran_last_page`.
- Uses right-to-left page swiping with `TabView`.
- Keeps a bottom toolbar with surah index, search, settings, saved ayahs, and current page/surah information.
- Highlights an ayah temporarily when opened from search, saved ayahs, or widget deep links.

### Ayah Context Menu

Long-pressing an ayah opens a native context menu. The app maps the press location back to the touched ayah using Core Text line hit testing.

Context menu actions:

- Open the selected ayah translation.
- Open Tafsir Ibn Kathir for the selected ayah.
- Open background information for the selected surah.
- Save or remove an ayah.
- Add or edit a private note for the ayah.

The context menu preview renders the full ayah across all lines it occupies on the current page and highlights it with the active theme's highlight color.

### Search

- Searches Arabic Quran text from `quranSearchText.db`.
- Supports exact Arabic text search.
- Supports normalized Arabic search by removing tashkeel, tatweel, Quran-specific marks, and normalizing alef variants and teh marbuta.
- Supports direct verse references such as `23:65`.
- Shows result cards with page number, surah name, reference, and verse text.
- Tapping a result jumps to the page and briefly highlights the ayah.
- Keeps up to 20 recent searches in `UserDefaults` key `quran_search_history`.

### Surah Index

- Lists all 114 surahs.
- Shows Arabic name, English/simple name, transliterated name, revelation place, verse count, and start page.
- Supports filtering by all, Makkah, or Madinah.
- Supports searchable navigation by Arabic name, simple name, transliterated name, or surah number.
- Tapping a surah jumps to its start page.

### Saved Ayahs And Notes

- Supports saved ayahs from the long-press context menu.
- Supports private notes attached to saved ayahs.
- Adding a note to an unsaved ayah creates a saved ayah.
- Removing a saved ayah also removes its note.
- Stores an Arabic verse text snapshot with each saved ayah.
- Separates notes and saved ayahs in the Saved Ayahs screen.
- Tapping a saved ayah jumps to its page and highlights the ayah.
- Saved ayahs are stored locally as JSON in `UserDefaults` key `saved_ayahs_v1`.
- The manager migrates old ayah bookmarks from `quran_bookmarks_v2` and ignores legacy page bookmarks in the v1 UI.

### Translations

- Provides per-ayah translation sheets.
- Supports French and English translation databases.
- French uses Muhammad Hamidullah.
- English uses Sahih International.
- The selected translation language is stored in `UserDefaults` key `translation_language`.
- Translation data is loaded from `translation-fr.db` or `translation-en.db`.
- The translation service removes surrounding quotes, inline `[[...]]` footnotes, and English `<sup>...</sup>` footnote tags before display.

### Tafsir

- Provides Tafsir Ibn Kathir commentary for ayahs.
- Loads commentary from `tafsir.db`.
- Supports exact ayah keys and grouped ayah entries through `ayah_keys`.
- Strips HTML and common entities before display.

### Surah Information

- Provides background and overview information for surahs.
- Loads content from `surahInfo.db`.
- Displays a short overview and parsed HTML sections.
- Converts HTML headings and paragraphs into structured SwiftUI sections.

### Reading Stats

The app tracks reading activity locally:

- Pages read today.
- Current reading streak.
- Best reading streak.
- Today's reading time.
- Distinct pages read toward a full 604-page mushaf completion.
- Lifetime days read.
- Khatm count.
- Most active weekday.
- Seven-day chart data.
- Ninety-day reading heatmap.

Stats are managed by `ReadingStatsManager` and stored in `UserDefaults`. The stats screen also supports resetting all reading progress, streaks, and session data.

### Reading Plans

- Supports one active page-based plan.
- Supports a full mushaf plan for pages 1-604.
- Supports custom page ranges.
- Starts new plans fresh without backfilling existing stats.
- Marks a plan page complete after the user remains on it for three seconds.
- Shows active plan progress in the center page chip and opens the plan dashboard from that chip.
- Shows a one-time reading plan prompt after three distinct pages when no plan exists.
- Stores the active plan in `UserDefaults` key `reading_plan_active_v1`.

### Settings

The settings screen provides:

- Reading progress summary.
- Link to the detailed reading stats screen.
- Reading plan summary and plan dashboard entry.
- Translation language selector.
- Reading theme selector.

Available themes:

- Light
- Dark
- Sepia
- AMOLED

### Themes And Rendering

- The active reading theme is stored in `UserDefaults` key `reading_theme`.
- Each theme defines page background, text colors, secondary colors, highlight color, and preferred color scheme.
- Dark and AMOLED themes use CPAL color-table modification for QPC color fonts so near-black glyphs become white while tajweed colors remain intact.
- Modified dark fonts are generated into the app cache directory under `DarkFonts`.
- The app pre-registers page fonts and pre-generates dark font variants during the splash screen.
- The app supports iOS 26 Liquid Glass via guarded availability checks and falls back to material/card styling on earlier iOS versions.

### Onboarding And Splash

- Shows a splash screen while the app performs startup work.
- Enforces a minimum two-second splash duration.
- Loads Quran data, warms services, registers fonts, prepares dark fonts, warms search, and preloads the keyboard during startup.
- Shows an eight-page onboarding flow on first launch, including a reading habit page for plans and daily targets.
- Stores onboarding completion in `UserDefaults` key `hasSeenOnboarding`.

### Widgets

The project includes a WidgetKit extension with two widgets.

#### Daily Ayah Widget

- Shows a daily ayah selected deterministically from a curated list using the day of year.
- Loads Arabic verse text from `quranSearchText.db`.
- Loads surah names from `surahMetadata.db`.
- Refreshes at midnight.
- Supports system small, system medium, accessory inline, and accessory rectangular widget families.
- Uses `furqan://ayah?surah=<number>&ayah=<number>` widget URLs to open the app directly to the ayah.

#### Reading Progress Widget

- Shows pages read today, current streak, total pages read, and completion percentage.
- Shows active reading plan target and progress when a plan exists.
- Supports system small and system medium widget families.
- Refreshes every 30 minutes.
- Reads app data from the shared app group `group.com.mehdi.furqan`.

### Deep Links

The app registers the custom URL scheme `furqan`.

Supported deep link:

```text
furqan://ayah?surah=2&ayah=255
```

When opened, the app:

- Parses the surah and ayah.
- Finds the corresponding page through `QuranSearchService`.
- Navigates to the page.
- Temporarily highlights the ayah.

### Privacy

- No account system.
- No analytics.
- No tracking.
- No ads.
- Quran data, saved ayahs, notes, reading plans, settings, search history, and reading stats stay local on device.
- The only shared storage is the local app group used by the app and its widget extension.

## Technical Overview

### Platform

- iOS deployment target: `18.2`
- Device family: iPhone
- Orientation: portrait
- UI framework: SwiftUI
- Widget framework: WidgetKit
- Data access: SQLite through `SQLite3`
- Project type: Xcode project at `Furqan.xcodeproj`
- Swift language version build setting: `5.0`
- Main bundle identifier: `com.mehdi.furqan`
- Widget bundle identifier: `com.mehdi.furqan.widget`
- App group: `group.com.mehdi.furqan`
- Custom URL scheme: `furqan`

### Application Flow

1. `FurqanApp` registers static fonts.
2. The splash screen appears.
3. Startup work runs:
   - Load Quran page data and surah metadata.
   - Initialize saved ayahs and migrate old ayah bookmarks.
   - Warm tafsir, surah info, and translation databases.
   - Generate/register QPC fonts.
   - Warm the search database.
   - Prepare the keyboard.
4. If onboarding has not been completed, `OnboardingView` is shown.
5. Otherwise, `MushafPagerView` becomes the main app experience.
6. `MushafPagerView` coordinates reading, search, surah index, saved ayahs, settings, context-menu actions, deep links, reading plans, and reading stats.

### Architecture

```text
Furqan/
├── FurqanApp.swift
├── Models/
│   ├── QuranModels.swift
│   ├── ReadingTheme.swift
│   └── TranslationLanguage.swift
├── Services/
│   ├── BookmarkManager.swift
│   ├── QuranDataService.swift
│   ├── QuranSearchService.swift
│   ├── ReadingStatsManager.swift
│   └── TafsirService.swift
├── Views/
│   ├── AdaptiveGlass.swift
│   ├── BookmarksView.swift
│   ├── MushafLineView.swift
│   ├── MushafPageView.swift
│   ├── MushafPagerView.swift
│   ├── OnboardingView.swift
│   ├── ReadingStatsView.swift
│   ├── SearchView.swift
│   ├── SettingsView.swift
│   ├── SurahIndexView.swift
│   ├── SurahInfoView.swift
│   ├── TafsirView.swift
│   └── TranslationView.swift
├── Extensions/
│   ├── Font+Quran.swift
│   └── View+Conditional.swift
└── Resources/
    ├── Data/
    └── Fonts/

FurqanWidget/
├── FurqanWidgetBundle.swift
├── DailyAyahWidget.swift
├── ReadingProgressWidget.swift
└── Resources/
```

### Key Components

| Component | Responsibility |
|---|---|
| `FurqanApp` | App lifecycle, splash, onboarding routing, startup warm-up, deep-link capture |
| `MushafPagerView` | Main reader, page persistence, toolbar, sheets, stats tracking, ayah highlighting |
| `MushafPageView` | Fixed 15-line page layout |
| `MushafLineView` | Surah headers, basmallah, QPC text rendering, ayah context menu |
| `QPCLabel` | UIKit/Core Text label for hit testing and context menu previews |
| `QuranDataService` | Loads page layout, words, and surah metadata from SQLite |
| `QuranSearchService` | Arabic search, verse reference lookup, page lookup |
| `TafsirService` | Tafsir, translation, and surah info database access |
| `BookmarkManager` | Saved ayah and note persistence with legacy bookmark migration |
| `ReadingStatsManager` | Reading history, streaks, time tracking, progress, widget sync |
| `ReadingPlanManager` | Active reading plan persistence, page completion, widget sync |
| `ThemeManager` | Reading theme persistence and environment value |
| `TranslationManager` | Translation language persistence |
| `AdaptiveGlass` | iOS 26 Liquid Glass wrapper and fallback material styles |
| `DailyAyahWidget` | Daily ayah WidgetKit timeline and deep link |
| `ReadingProgressWidget` | WidgetKit reading progress and plan summary |

### Data Files

| File | Used By | Purpose |
|---|---|---|
| `qpc-v4.db` | `QuranDataService` | Quran words, locations, surah/ayah/word positions, QPC text |
| `quran-data.db` | Bundled resource | Additional Quran data bundled with the app; not directly referenced by the current Swift services |
| `mushafLayout.db` | `QuranDataService` | Page number, line number, line type, word ranges, surah headers |
| `surahMetadata.db` | App and widget | 114 surah names, revelation metadata, verse counts |
| `quranSearchText.db` | App and widget | Verse text, normalized text, word-to-page lookup |
| `tafsir.db` | `TafsirService` | Tafsir Ibn Kathir content |
| `surahInfo.db` | `TafsirService` | Surah background/overview HTML |
| `translation-fr.db` | `TafsirService` | French ayah translations |
| `translation-en.db` | `TafsirService` | English ayah translations |

### Font Files

| Resource | Purpose |
|---|---|
| `Resources/Fonts/QPC/p1.ttf` ... `p604.ttf` | One QPC color font per mushaf page |
| `QCF_SurahHeader_COLOR-Regular.ttf` | Decorative surah title glyphs |
| `UthmanicHafs_V22.ttf` | Basmallah and supporting Arabic text |
| `Oi-Regular.ttf` | Furqan logo text |

### Persistence

| Key / Store | Owner | Data |
|---|---|---|
| `hasSeenOnboarding` | `FurqanApp` | First-launch onboarding state |
| `quran_last_page` | `MushafPagerView` | Last opened mushaf page |
| `reading_theme` | `ThemeManager` | Selected reading theme |
| `translation_language` | `TranslationManager` | Selected translation language |
| `saved_ayahs_v1` | `BookmarkManager` | JSON-encoded saved ayahs and notes |
| `quran_bookmarks_v2` | `BookmarkManager` | Legacy bookmark migration source |
| `quran_search_history` | `SearchHistoryManager` | Recent search queries |
| `reading_stats_*` | `ReadingStatsManager` | Reading progress, streaks, lifetime stats, heatmap data |
| `reading_plan_active_v1` | `ReadingPlanManager` | Active reading plan |
| `reading_plan_prompt_dismissed_v1` | `ReadingPlanManager` | One-time plan prompt dismissal |
| `reading_session_<yyyy-MM-dd>` | `ReadingStatsManager` | Daily reading time |
| `group.com.mehdi.furqan` | App + widget | Widget-facing stats snapshot |

## Build And Run

1. Open `Furqan.xcodeproj` in Xcode.
2. Select the `Furqan` scheme.
3. Select an iPhone simulator or device running iOS 18.2 or newer.
4. Ensure the app and widget extension use the same app group entitlement: `group.com.mehdi.furqan`.
5. Build and run.

The app is designed to run fully offline after installation because its Quran text, layout, translations, tafsir, metadata, fonts, and widget resources are bundled locally.

## Repository Notes

- The project currently has no external package manager dependencies.
- The app target and widget extension both use generated Info.plist settings.
- Widget resources duplicate the databases needed by the extension because widgets run in their own bundle.
- Dark-theme QPC font variants are generated at runtime and cached, not committed as static resources.
- The app uses availability guards for iOS 26 Liquid Glass APIs while retaining fallback styling for earlier supported iOS versions.

## License

Private. No public license is currently declared.

---

<p align="center">
  <strong>No ads. No subscriptions. No data collection. Just the Quran.</strong>
</p>
