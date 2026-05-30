# Dostok Assets

This directory contains all static assets used by the Dostok app. The three
subdirectories are already registered in `pubspec.yaml` under `flutter.assets`.

```
assets/
  images/       # PNG, JPG, SVG illustrations and photos
  animations/   # Lottie JSON files
  icons/        # Custom icon files (SVG, PNG)
```

## Adding Images

1. Place your image file in `assets/images/`.
2. Supported formats: **PNG** (preferred for illustrations), **JPG** (photos),
   **SVG** (with the `flutter_svg` package -- not currently a dependency).
3. Use descriptive, lowercase, snake_case filenames:
   ```
   assets/images/empty_chat_illustration.png
   assets/images/onboarding_welcome.png
   assets/images/mood_happy.png
   ```
4. Reference in Dart:
   ```dart
   Image.asset('assets/images/empty_chat_illustration.png')
   ```

### Recommended Sizes

| Asset Type           | Dimensions (px) | Format |
|----------------------|-----------------|--------|
| Onboarding screen    | 1024 x 1024     | PNG    |
| Empty state illo     | 512 x 512       | PNG    |
| Mood icons           | 128 x 128       | PNG    |
| Splash / launcher    | 1024 x 1024     | PNG    |
| Chat backgrounds     | 1080 x 1920     | JPG    |

## Adding Animations (Lottie)

1. Export your animation as a **Lottie JSON** file from After Effects
   (via the Bodymovin plugin) or Figma (via the LottieFiles plugin).
2. Place the `.json` file in `assets/animations/`.
3. Filenames:
   ```
   assets/animations/loading_dots.json
   assets/animations/empty_state.json
   assets/animations/success_checkmark.json
   ```
4. Reference in Dart (the `lottie` package is already in `pubspec.yaml`):
   ```dart
   import 'package:lottie/lottie.dart';

   Lottie.asset('assets/animations/loading_dots.json')
   ```

### Tips

- Keep file size under **200 KB** per animation for fast cold-start.
- Test on a low-end device; complex Lottie files can drop frames.
- Use [LottieFiles](https://lottiefiles.com/) for free, optimized animations
  and preview before committing.

## Adding Custom Icons

1. Place icon files in `assets/icons/`.
2. Prefer **SVG** for vector icons, or **PNG** at 128 x 128 / 256 x 256 px.
3. Filenames:
   ```
   assets/icons/dostok_logo.svg
   assets/icons/mood_selector.svg
   ```
4. For SVG icons, add `flutter_svg` to `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_svg: ^2.0.9
   ```
   Then reference:
   ```dart
   import 'package:flutter_svg/flutter_svg.dart';

   SvgPicture.asset('assets/icons/dostok_logo.svg')
   ```
5. For PNG icons, use `Image.asset` as with any other image.

## General Guidelines

- **Naming**: Use `snake_case` for all asset filenames. Avoid spaces, special
  characters, and uppercase letters.
- **Organisation**: Keep assets in the correct subdirectory. Do not place
  files directly in `assets/`.
- **Size budget**: Aim for a total asset payload under **5 MB** to keep the
  app bundle small. Compress images with [Squoosh](https://squoosh.app/) or
  [TinyPNG](https://tinypng.com/).
- **Dark mode**: Where possible, provide two variants of illustrations
  (e.g., `empty_light.png` / `empty_dark.png`) and select at runtime based
  on `Theme.of(context).brightness`.
- **Licensing**: Only include assets you have the right to use. Document the
  source and license in a comment at the top of this file or in a separate
  `LICENSE` file in this directory.
- **Accessibility**: Add meaningful semantic labels to images in Dart via
   `Semantics(image: ...)` or the `semanticLabel` parameter on `Image.asset`.
