# Relevix

A Flutter-based application for **data interpolation and bidirectional value mapping** from multi-source tabular datasets (CSV/Excel).

Designed for scientific and engineering use cases where datasets contain discrete measurements and exact values are not always available — Relevix estimates missing values using linear interpolation and nearest-neighbour averaging.

## Features

- **Multi-file upload** — Load multiple CSV/Excel files simultaneously
- **Auto-detection** — Handles tab/comma delimiters and skips title/description lines
- **Schema validation** — Ensures all uploaded files share the same column structure
- **Bidirectional mapping** — Swap input/output variables with one tap
- **Interpolation engine** — Exact match → Linear interpolation → Averaging fallback → Nearest value
- **Interactive graph** — Explore your data with touch tooltips (fl_chart)
- **Responsive layout** — Works on mobile (Android) and desktop (Windows)
- **Brown + beige theme** — Premium UI with Outfit font

## Interpolation Methods

| Method | When Used |
|--------|-----------|
| **Exact Match** | Input value exists in the dataset |
| **Linear Interpolation** | Input falls between two data points |
| **Averaged** | Multiple matches or duplicate values |
| **Nearest Value** | Input is outside the data range |

## Getting Started

### Prerequisites

- Flutter SDK (≥ 3.19 stable)
- Android Studio (for Android builds)
- Visual Studio 2022 with "Desktop development with C++" workload (for Windows builds)

### Setup

```bash
# Clone the repository
git clone <repository-url>
cd Relevix

# Install dependencies
flutter pub get

# Run on Android
flutter run

# Run on Windows
flutter run -d windows
```

### Build

```bash
# Android APK
flutter build apk --release

# Windows executable
flutter build windows --release
```

## Testing

```bash
flutter test
```

Covers: interpolation correctness, data validation, dataset merging, edge cases, and bidirectional mapping.

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   ├── dataset.dart                   # Dataset & DataRow models
│   └── interpolation_result.dart      # Result model with method enum
├── services/
│   ├── file_parser.dart               # CSV + Excel parser (auto-detect delimiter)
│   ├── data_validator.dart            # Schema & data validation
│   ├── dataset_merger.dart            # Multi-file merge + cleanup
│   └── interpolation_engine.dart      # Core interpolation algorithm
├── screens/
│   ├── splash_screen.dart             # Animated splash screen
│   ├── upload_screen.dart             # File picker + validation
│   ├── column_selection_screen.dart   # Variable selection + swap
│   └── main_screen.dart               # Graph + calculator
├── widgets/
│   ├── chart_widget.dart              # Interactive line chart
│   └── result_card.dart               # Styled result display
└── theme/
    └── app_theme.dart                 # Brown + beige Material 3 theme
```

## Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **Charts**: fl_chart
- **File Parsing**: csv, excel
- **File Picking**: file_picker
- **Typography**: Google Fonts (Outfit)

## License

All rights reserved.
