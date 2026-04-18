# enfr

A new Flutter project.

## TODO

- Refactor into pages, widgets, services
- Make any text selectable so it can bee google translated
- Include Canadian French translation
- Work on agent prompts
- Handle secrets safely

## CI/CD

On every push to `main`, GitHub Actions:

- **Web** — builds and deploys to the `gh-pages` branch (configure GitHub Pages to serve from that branch)
- **Android** — builds a debug APK and uploads it as a workflow artifact (`enfr-debug`) downloadable from the Actions tab

## Release

```bash
flutter run --release
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
