# VEGA AI - JARVIS-Inspired Android Voice Assistant

VEGA AI is a JARVIS-inspired Android voice assistant built with Flutter, Dart, and Kotlin. It combines **offline on-device rules and small language models** for sub-100ms device automation with **online Gemini Cloud AI** for deep conversational intelligence.

---

## 🎨 Design Theme
- **Primary Pink**: `#F73B9A` (Core energetic accent, active listening wave, orb glow)
- **Lavender**: `#D9C6FD` (Secondary orbital rings, passive glow, soft highlights)
- **Deep Slate/Dark Surfaces**: `#0F0B18` / `#181326` (Immersive holographic sci-fi dark mode)
- **Subtle Light Neutral**: `#FAF7FD` / `#FFFFFF` (High-contrast, clean day mode)

---

## 🏗️ Architecture & Project Organization

VEGA AI employs a **feature-based Clean Architecture**:

```
lib/
├── app/                  # Application lifecycle, routing, and environment config
├── core/
│   ├── constants/        # Colors, strings, metrics
│   ├── errors/           # Typed Failure definitions
│   ├── models/           # Domain models: VoiceCommand, CommandIntent, ExecutionResult
│   ├── platform/         # Android MethodChannel constants and bridge
│   └── utils/            # Safe logging & utilities
├── features/
│   ├── assistant/        # Core voice interface, animated orb, status badges
│   ├── automation/       # Safe app action registry & Android integration
│   ├── history/          # Activity & command audit log
│   ├── home/             # Main responsive dashboard
│   └── settings/         # Configuration (AI switch, keys, sensitivity)
├── services/
│   ├── ai/               # AI Router, Offline AIService, Online GeminiService
│   ├── audio/            # Earcon playback & audio cues
│   ├── connectivity/     # Network & offline state monitor
│   ├── speech/           # STT & Wake-word detection contracts
│   ├── storage/          # Local persistence contracts
│   └── voice/            # TTS engine interface
└── shared/
    ├── theme/            # Material 3 light/dark themes
    └── widgets/          # Reusable UI components
```

---

## 🔒 Security & Safety Registry
To protect user devices against arbitrary shell execution and unsafe automation:
1. **Zero-Trust Command Whitelist**: Only actions explicitly defined in `ActionRegistry` can be triggered.
2. **Action Safety Levels**:
   - `Safe`: Non-destructive read or standard controls (e.g., flashlight, battery, volume).
   - `NeedsConfirmation`: Operations that send messages or modify data require user confirmation.
   - `Restricted`: System-level security functions (e.g. factory reset) are blocked.
3. **No Hardcoded Credentials**: API keys are securely entered by the user in Settings and saved to local secure storage.

---

## 🚀 Getting Started & Running the App

### Prerequisites
1. **Install Flutter SDK** (version 3.16.0 or later):
   - Download the Flutter Windows SDK from [flutter.dev](https://docs.flutter.dev/get-started/install/windows).
   - Extract to a path (e.g., `C:\flutter`).
   - Add `C:\flutter\bin` to your system `PATH` environment variable.
2. **Android Studio & SDK**:
   - Install Android Studio with Android SDK (API 34) and Android Command-line Tools.
3. **Verify Installation**:
   ```bash
   flutter doctor
   ```

### Running Locally
Once Flutter is installed:
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis
flutter analyze

# 3. Run automated tests
flutter test

# 4. Launch on connected Android device or emulator
flutter run
```
