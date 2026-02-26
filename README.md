# mawaqit_core_logger

A shared Flutter logging package for internal use across all packages and applications. Built on top of [`logger`](https://pub.dev/packages/logger) with support for environment-aware logging and temporary release-mode debugging.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Log Levels](#log-levels)
- [Release Mode Debugging](#release-mode-debugging)
    - [Option A: Hidden Gesture](#option-a-hidden-gesture-trigger)
    - [Option B: Remote Config](#option-b-remote-config-trigger-recommended)
    - [Checking Status](#checking-logging-status)
    - [Manual Disable](#manual-disable)
- [API Reference](#api-reference)
- [Architecture](#architecture)
- [Versioning](#versioning)
- [Security Guidelines](#security-guidelines)
- [Contributing](#contributing)
- [Changelog](#changelog)

---

## Overview

`mawaqit_core_logger` is a centralized logging solution designed to:

- ✅ **Silence all logs in release mode** by default
- ✅ **Allow temporary logging in release** for troubleshooting (with auto-expiry)
- ✅ **Provide a consistent API** across all internal packages and apps
- ✅ **Act as a single place** to plug in crash reporters (Crashlytics, Sentry) in the future

> **Why not just use `print()`?**
> `print()` always logs — even in release mode — potentially exposing sensitive data to anyone with device log access. `mawaqit_core_logger` is environment-aware and safe by default.

---

## Features

| Feature | Details |
|---|---|
| Environment-aware | Logs in debug/profile, silent in release by default |
| Log levels | `trace → debug → info → warn → error → fatal` |
| Pretty output | Colored, emoji-tagged, timestamped logs in console |
| Temporary release logging | Enable with auto-expiry timeout (default: 2 hours) |
| Status inspection | Check if release logging is active and time remaining |
| Future-ready | Hook point for Crashlytics / Sentry already in place |

---

## Installation

Add `mawaqit_core_logger` to your package's `pubspec.yaml`:

```yaml
dependencies:
  core_logger:
    git:
      url: https://github.com/mawaqit/mawaqit_core_logger.git
      ref: v1.1.0  # always pin to a specific tag
```

Then run:

```bash
flutter pub get
```

> ⚠️ **Always pin to a version tag** (e.g. `v1.1.0`), never use `ref: main` in production. This ensures your builds are reproducible and not broken by upstream changes.

---

## Quick Start

```dart
import 'package:mawaqit_core_logger/mawaqit_core_logger.dart';

class AuthService {
  Future<void> login(String email, String password) async {
    try {
      Log.i('Login attempt for: $email');
      await _api.login(email, password);
      Log.i('Login successful');
    } catch (e, s) {
      Log.e('Login failed', error: e, stackTrace: s);
    }
  }
}
```

That's it. No setup, no initialization needed for standard usage.

---

## Log Levels

Use the appropriate level to make logs meaningful and filterable:

```dart
Log.t('Verbose detail — socket frames, raw JSON');   // 🐛 trace
Log.d('General debug info — variable values');        // 🐛 debug
Log.i('Key app events — user login, screen open');    // ℹ️ info
Log.w('Non-critical issues — retry attempt, fallback used'); // ⚠️ warning
Log.e('Errors — failed API call, caught exception',   // ❌ error
  error: e,
  stackTrace: s,
);
Log.f('Fatal — unrecoverable state, app about to crash', // 💀 fatal
  error: e,
  stackTrace: s,
);
```

### When to use each level

| Level | When to use | Example |
|---|---|---|
| `trace` | Very verbose, low-level detail | Raw HTTP request/response body |
| `debug` | Development-time info | Parsed model values, state changes |
| `info` | Important business events | User logged in, order placed |
| `warn` | Something unexpected but recoverable | Token expiring, cache miss |
| `error` | Caught exceptions, failures | API error, file not found |
| `fatal` | Unrecoverable failures | DB corruption, critical crash |

> **Rule of thumb:** If it would be noise in production, use `debug`. If it matters for understanding user flows, use `info`.

---

## Release Mode Debugging

By default, **all logs are silenced in release builds**. For troubleshooting bugs that only reproduce in release mode, you can temporarily enable logging with an auto-expiry timeout.

> ⚠️ **Security warning:** Only enable release logging when actively troubleshooting. It auto-disables after the timeout, but you should also call `Log.disableReleaseLogging()` when done.

### Option A: Hidden Gesture Trigger

Suitable for quick, on-device debugging without a backend dependency:

```dart
// Typically placed on a logo or version text in Settings / About screen
int _tapCount = 0;

GestureDetector(
  onTap: () {
    _tapCount++;
    if (_tapCount >= 7) {
      Log.enableReleaseLogging(timeout: const Duration(hours: 1));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debug logging enabled for 1 hour'),
          backgroundColor: Colors.orange,
        ),
      );
      _tapCount = 0;
    }
  },
  child: const AppVersionText(),
)
```

### Option B: Remote Config Trigger (Recommended)

Best for teams — toggle logging remotely per user or environment without a new build:

```dart
// In app startup (e.g. main.dart or AppProvider init)
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.fetchAndActivate();

final enableLogs = remoteConfig.getBool('force_enable_logs');
if (enableLogs) {
  Log.enableReleaseLogging(timeout: const Duration(hours: 2));
}
```

Set `force_enable_logs = true` in your Firebase Remote Config console, then set it back to `false` when done.

### Custom Timeout

```dart
// Default is 2 hours
Log.enableReleaseLogging(timeout: const Duration(minutes: 30));
```

### Checking Logging Status

```dart
if (LogConfig.isForceEnabled) {
  final remaining = LogConfig.timeRemaining;
  Log.i('Release logging active — expires in ${remaining?.inMinutes} min');
}
```

### Manual Disable

```dart
// Call this as soon as troubleshooting is complete
Log.disableReleaseLogging();
```

---

## API Reference

### `Log` — primary logging interface

```dart
// Log methods
Log.t(String msg)
Log.d(String msg)
Log.i(String msg)
Log.w(String msg)
Log.e(String msg, {Object? error, StackTrace? stackTrace})
Log.f(String msg, {Object? error, StackTrace? stackTrace})

// Release logging control
Log.enableReleaseLogging({Duration? timeout})  // default: 2 hours
Log.disableReleaseLogging()
```

### `LogConfig` — status inspection

```dart
LogConfig.shouldLog         // bool — is logging active right now?
LogConfig.isForceEnabled    // bool — is release logging force-enabled?
LogConfig.timeRemaining     // Duration? — time left before auto-disable
```

---

## Architecture

```
mawaqit_core_logger/
  lib/
    src/
      log_config.dart     # Controls when logging is allowed (env + release override)
      app_logger.dart     # Logger instance configuration (PrettyPrinter, levels)
      log.dart            # Public Log class — the only API consumers use
    mawaqit_core_logger.dart      # Public exports: Log + LogConfig
```

### Design decisions

**`app_logger.dart` is not exported.**
The `Logger` instance is an internal detail. Consumers should never interact with it directly — only through `Log.*`.

**`Log.enableReleaseLogging()` calls `refreshLogger()` internally.**
The underlying `logger` package captures log level at construction time. Rebuilding the instance after a config change ensures the new level takes effect immediately.

**`LogConfig` is exported for status inspection only.**
Consumers can read `LogConfig.isForceEnabled` and `LogConfig.timeRemaining` but all mutations should go through `Log.enableReleaseLogging()` / `Log.disableReleaseLogging()` to keep logger state in sync.

---

## Versioning

This package follows [Semantic Versioning](https://semver.org/):

| Change | Version bump | Example |
|---|---|---|
| Bug fix, internal improvement | patch | `v1.0.0 → v1.0.1` |
| New feature, backwards compatible | minor | `v1.0.0 → v1.1.0` |
| Breaking API change | major | `v1.0.0 → v2.0.0` |

### Updating your dependency

```yaml
# pubspec.yaml
dependencies:
  mawaqit_core_logger:
    git:
      url: https://github.com/mawaqit/mawaqit_core_logger.git
      ref: v1.1.0  # bump this when updating
```

---

## Security Guidelines

These apply to **all engineers** using this package:

- 🚫 **Never log passwords, tokens, or PII** (emails, phone numbers, IDs) at any log level
- 🚫 **Never leave release logging enabled** after troubleshooting — call `Log.disableReleaseLogging()` or let the timeout expire
- 🚫 **Never log raw API responses** that may contain sensitive user data
- ✅ **Use `Log.e` with stackTrace** for all caught exceptions — this is where Crashlytics will hook in
- ✅ **Prefer `Log.i`** for user-facing events (login, checkout) — these are most useful for debugging flows

---

## Contributing

This is an internal package maintained by the core platform team.

### To propose a change

1. Open an issue describing the problem or feature
2. Branch from `main`: `git checkout -b feat/your-feature`
3. Make changes, update tests
4. Bump version in `pubspec.yaml` following semver
5. Update [Changelog](#changelog)
6. Open a pull request — tag `@platform-team` for review

### Running tests

```bash
flutter test
```

---

## Changelog

### v1.1.0
- Added `LogConfig` for temporary release-mode logging
- Added `Log.enableReleaseLogging()` and `Log.disableReleaseLogging()`
- Added `LogConfig.isForceEnabled` and `LogConfig.timeRemaining` for status inspection
- Added `refreshLogger()` to rebuild logger instance after config changes

### v1.0.0
- Initial release
- `Log.t / d / i / w / e / f` methods
- Environment-aware logging (silent in release by default)
- PrettyPrinter configuration with colors, emojis, timestamps