# MomCare Patient App — Engineering Rules

Flutter patient-facing app for MomCare, a maternal-health RPM platform. Full product
context lives in `docs/patient-app-plan.md` (project root, sibling to this repo) — read
it before scoping a new feature. This file is the persistent, always-loaded briefing:
project facts and hard rules, not step-by-step procedures.

Architecture audit performed 2026-09-18 — findings below are grounded in that, not
guessed. Re-audit before trusting these as current if a lot of code has changed since.

**Starting a new feature?** Read `docs/FEATURE_WORKFLOW.md` first — plan → one phase
at a time → test → separate review pass → profile-with-evidence → commit. Don't skip
straight to implementation; `docs/DESIGN_SYSTEM.md` and `docs/PRODUCT_RULES.md` are
the other two docs a new feature plan should check against.

## Core principles

- Do not implement a feature before understanding the architecture it has to fit into.
- Do not rewrite working code without evidence it's actually broken.
- Reuse existing components before creating new ones (see "Reuse" below).
- Do not duplicate business logic across features.
- Do not put business logic or network calls directly inside widgets/screens.
- Do not hardcode production data, secrets, or a fixed device location.
- Do not silently swallow errors — every `catch` needs a real, honest UI state.
- Do not add a package that an existing dependency already solves.
- Do not modify files unrelated to the current task.

## Architecture

- Feature-first: `lib/features/<name>/{screens,widgets,models,providers,repositories}`.
  This is a real, followed convention — keep following it.
- State management is **Riverpod**, project-wide. The `hospitals` feature
  (`lib/features/hospitals/`) is the one fully-realized example — a `StateNotifier` +
  a typed state class with a status enum (`idle/loading/loaded/error`). Use that shape
  for every new feature's state, not local `setState`, once the feature needs real data.
- **Repositories are currently missing everywhere, including in `hospitals`** — its
  provider calls the network directly. New features should add a repository layer
  between the provider and the network/API call; retrofit `hospitals` opportunistically,
  not as a prerequisite for other work.
- Route MomCare-backend calls through the shared `dioProvider`
  (`lib/core/api/api_client.dart`) — don't instantiate a fresh `Dio()` per feature.
  A genuinely different API (e.g. OpenStreetMap's Overpass, used by
  `real_hospitals_provider.dart`) gets its own clearly-named client — that's a
  deliberate exception, not the default.
- Routing is `go_router`, flat top-level routes (`lib/core/router/app_router.dart`).
  A screen's own internal detail views (e.g. one exercise's detail) are a plain
  `Navigator.push` from inside that feature, not a new top-level route.

## UI / Design system

- `AppColors` (`lib/theme/app_colors.dart`) is the single source of truth for color.
  Never introduce a new raw `Color(0x...)` or `Colors.*` value in a screen when a
  token already exists.
- `ClinicalCard` and `PrimaryButton` (`lib/shared/widgets/`) are the real shared
  widgets. **`GlassButton`, `GlassSurface`, and `GradientBackground` are deprecated
  shims** (their own doc comments say so) — never import them in new code. If you
  touch a screen that still uses one, migrate that screen to the real widget instead
  of leaving it.
- Typography: prefer `Theme.of(context).textTheme` where practical. In practice
  almost every screen currently calls `GoogleFonts.inter(...)`/`GoogleFonts.playfairDisplay(...)`
  ad hoc instead — a known, tracked inconsistency (see "Known technical debt"), not
  something to silently keep multiplying in new code.
- No unnecessary animation. Accessibility (contrast, tap targets, screen-reader labels)
  is required, not optional.

## Performance

- Don't perform expensive work in `build()`.
- Avoid unnecessary rebuilds — scope `ref.watch` narrowly.
- Use lazy lists (`ListView.builder`) for anything that could grow.
- Dispose every `StreamSubscription`/`AnimationController`/`TextEditingController`/
  `MapController` you create — the `hospitals` feature does this correctly; match it.
- Profile (DevTools, **profile build**, not debug) before optimizing based on a guess.
  Debug-mode jank is not evidence of a real performance problem — see Flutter's own
  guidance that debug performance isn't representative of release.

## Security & privacy

- Never hardcode secrets or tokens. None exist in this repo today — keep it that way.
- Never log sensitive patient data.
- **The Flutter client is never the security boundary.** Any patient-visibility logic
  (e.g. a future "Doctor Notes" screen) is presentation-only — the backend enforces
  who can see what. Don't write `if (role == 'doctor')` and treat that as access control.
- `ApiConfig`'s dev base URL (`http://10.0.2.2:8000`) is plain HTTP with no matching
  network-security-config exception in the Android manifest yet — Android 9+ blocks
  cleartext by default. Fix this before wiring the first real API call, not after
  hitting a confusing silent failure.

## Clinical safety

MomCare is a maternal-health app. The patient client must not:

- diagnose conditions, or present an AI estimate as medically certain
- turn an estimated value (e.g. Food Scan nutrition) into a medical recommendation
- expose internal clinical notes, another patient's data, or fabricate a vital,
  hospital, appointment confirmation, or alert
- default a missing/unknown value to a normal-looking one — absent data stays visibly
  absent (an existing, followed rule — every sample-data screen labels itself as such)

Always distinguish, visibly: educational content, AI estimates, patient-entered data,
device-entered data, clinician-entered data, and system-generated alerts. When
uncertain about clinical framing or copy, stop and ask rather than inventing it.

## Testing

**Baseline as of 2026-09-18: `flutter analyze` clean (2 pre-existing, unrelated info/
warning-level notices) and `flutter test` fully green — 5 tests across 2 files.**
Coverage is thin (only the splash screen and onboarding screen have any test at all;
the `hospitals` feature — the most complex code in the app — has none), but what
exists passes for real. Treat a red `flutter test` as a real regression from here on,
not a pre-existing condition to work around.

- New business logic (providers, repositories) needs tests.
- Run `flutter analyze` and relevant tests before calling a feature done — not just
  "it compiles."
- **Animation-driven navigation needs stepped `pump()` calls, not one big jump.**
  Confirmed empirically in `test/onboarding_screen_test.dart`: a single
  `tester.pump(const Duration(milliseconds: 900))` after tapping a button that fires
  `context.go()` from an `AnimationController` status-listener callback left the
  destination screen's content entirely absent from the tree — the same total duration
  pumped in small steps (e.g. 50ms increments) reliably works. `pumpAndSettle()` is
  unusable on any screen with an indefinitely-running `Ticker` (e.g. onboarding's
  `AutoScrollingRow`) — it never returns; use bounded stepped `pump()` there too.

## Git

- Keep changes scoped to the task. Don't drive-by fix unrelated things without saying so.
- Never reset/revert/discard the user's own uncommitted work without explicit permission.
- No commits or pushes unless explicitly authorized in that same message.

## Known technical debt (as of the 2026-09-18 audit)

Not blocking, but don't build new work that assumes these are already fixed:

1. `GlassButton`/`GlassSurface`/`GradientBackground` shims still imported by several
   screens (splash, guest home, hospital discovery's map placeholder/card) — migration
   to `PrimaryButton`/`ClinicalCard` is unfinished. Same root cause, separate symptom:
   Material `Icons.*` is still used in those same older screens instead of
   `LucideIcons` (see `docs/DESIGN_SYSTEM.md`) — migrate icons alongside widgets when
   a listed file is next touched.
2. Dead code: `lib/features/hospitals/providers/hospitals_provider.dart` +
   `lib/features/hospitals/models/hospital.dart` (superseded by `RealHospital`/Overpass),
   `lib/theme/app_gradients.dart` (orphaned), `lib/screens/placeholder_home_screen.dart`
   (no longer routed).
3. `freezed_annotation`/`json_annotation`/`build_runner`/`freezed`/`json_serializable`
   are installed, zero usages anywhere. Decide once whether the first real API models
   adopt them, rather than leaving them idle indefinitely.
4. Auth (`AuthScreen`) is a hardcoded stub — Login/Register navigate to `/home`
   regardless of input, deliberately, until a real backend login endpoint exists.
5. Test coverage is thin (see "Testing" above) — only 2 of ~15 screens have any test,
   and the `hospitals` feature (providers, repositories-that-should-exist) has none.
