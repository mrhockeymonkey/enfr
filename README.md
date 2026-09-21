# enfr

A new Flutter project.

## TODO

- Refactor into pages, widgets, services
- Make any text selectable so it can bee google translated
- Include Canadian French translation
- Work on agent prompts
- Handle secrets safely

## CI/CD

This is a **web-only** Flutter app, hosted on Cloudflare Workers. On every push
to `main`, GitHub Actions builds the web app with `--wasm` and deploys it to the
`enfr-prod` Worker at <https://enfr-prod.scottmatthews343.workers.dev>. Pull
requests get a stable preview at
`https://pr-<number>-enfr-prod.scottmatthews343.workers.dev`. The wasm build
ships a JS fallback alongside it, so browsers without WebAssembly GC support
still work.

The Flutter SDK version is pinned in `.fvmrc` at the repo root (managed via
[fvm](https://fvm.app)). CI reads that file, so the SDK never floats to a new
release on its own. To upgrade, change that one file and regenerate
`pubspec.lock`.

## Running locally

```bash
fvm flutter run -d chrome
```

## Release build

```bash
fvm flutter build web --wasm --no-web-resources-cdn
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
