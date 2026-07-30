---
kind: frontend_style
name: Flutter Material 3 Theme System with Archetype-Based Identity Theming
category: frontend_style
scope:
    - '**'
source_files:
    - lib/core/theme/app_theme.dart
    - lib/core/theme/archetype_theme.dart
    - lib/core/theme/theme_provider.dart
    - pubspec.yaml
    - lib/main.dart
---

The Emerge app uses a Flutter-based frontend styling system built on Material 3 with a layered theming architecture that combines global app themes with user-selected archetype identities.

**System Architecture:**
The styling system is centered around two primary theme files: `lib/core/theme/app_theme.dart` defines the global cosmic design system (dark purple-black backgrounds with green accents), while `lib/core/theme/archetype_theme.dart` provides per-user identity themes through five archetypes (Athlete, Scholar, Creator, Stoic, Zealot) plus a default Explorer theme. The `ThemeController` in `theme_provider.dart` manages light/dark/system mode persistence via Riverpod state management.

**Design Tokens and Color System:**
The app establishes a comprehensive color palette with named tokens including `cosmicVoidDark`, `neonGreen`, `warmGold`, and glassmorphism colors (`glassWhite`, `glassBorder`). Gradients are defined as constants for cosmic backgrounds, neon accents, and gold rewards. Typography uses Google Fonts' Spline Sans throughout both light and dark themes.

**Material 3 Implementation:**
The app uses `useMaterial3: true` with custom `ColorScheme` definitions for both light and dark modes. Input decoration themes use consistent 12px border radius with filled inputs. App bars are configured with transparent backgrounds and centered titles. The system supports dynamic archetype-specific colors through `IdentityThemeExtension` which extends Flutter's theme extension mechanism.

**Responsive Strategy:**
The Flutter framework handles cross-platform responsiveness automatically across mobile, web, and desktop targets. The web build includes standard responsive considerations through Flutter's adaptive widgets and the `flutter_web` platform support.

**Asset Management:**
Visual assets are organized under `assets/` with structured subdirectories for icons, images (avatars, backgrounds, levels), rive animations, and world-specific content. The `pubspec.yaml` declares all asset paths, and shaders include a custom `cracked_orb.frag` GLSL shader for visual effects.

**State Management Integration:**
Theme state is managed through Riverpod providers with `ThemeController` handling mode switching between light, dark, and system preferences. The controller persists theme choices to local storage and integrates with the app's authentication flow to apply archetype-specific theming when users are logged in.