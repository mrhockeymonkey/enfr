# enfr

A new Flutter project.

## TODO

- Refactor into pages, widgets, services
- Make any text selectable so it can bee google translated
- Include Canadian French translation
- Work on agent prompts
- Handle secrets safely

## CI/CD

This is a **web-only** Flutter app. On every push to `main`, GitHub Actions
builds the web app and deploys it to the `gh-pages` branch (GitHub Pages is
configured to serve from that branch).

The Flutter SDK version is pinned in `.flutter-version` at the repo root. CI
reads that file, so the SDK never floats to a new release on its own. To upgrade,
change that one file and regenerate `pubspec.lock`.

## Running locally

```bash
flutter run -d chrome
```

## Release build

```bash
flutter build web --base-href /enfr/ --no-web-resources-cdn
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
