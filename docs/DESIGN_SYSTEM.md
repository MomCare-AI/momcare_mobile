# MomCare Patient App — Design System

Extracted from what the codebase actually uses today (grep'd across all of `lib/`,
2026-09-18), not invented. Where usage was already inconsistent, this picks one value
and calls out the current variance so it can be cleaned up deliberately instead of
multiplying. This is a reference doc — no code changes were made to produce it. Turning
these into real Dart constants (`AppSpacing`, `AppRadius`, `AppTypography`, `AppMotion`)
is a natural next step once this is approved, not done yet.

## Colors

The real, current source of truth is `lib/theme/app_colors.dart` — this doc doesn't
duplicate it, it documents how to *use* it correctly.

| Token | Value | Use for |
|---|---|---|
| `AppColors.primary` | `#08695D` (deep teal) | Brand actions, active states, links |
| `AppColors.surface` | `#FFFFFF` | Cards, sheets, floating elements |
| `AppColors.background` | `#F5F7F9` | Screen backgrounds |
| `AppColors.textPrimary` | `#1A2B3C` | Primary readable text |
| `AppColors.textSecondary` | `#6B7A8B` | Secondary/meta text, timestamps |
| `AppColors.border` | `#E2E8F0` | Card borders, dividers |
| `AppColors.stable` | `#10B981` (emerald) | Risk level: stable |
| `AppColors.moderate` | `#F59E0B` (amber) | Risk level: moderate |
| `AppColors.high` | `#EF4444` (red) | Risk level: high; also destructive actions |
| `AppColors.accentPink` | `#FDA4AF` | Decorative accent only — not yet load-bearing anywhere |
| `AppColors.accentSage` | `#86EFAC` | Decorative accent only — not yet load-bearing anywhere |

**Known gaps, not yet fixed:**
- **No `critical` token exists.** The platform's risk model has 4 levels
  (stable/moderate/high/critical) — the missing 4th color will be needed the moment
  a real RiskPanel screen gets built. Add it before that, don't reuse `high` for both.
- **Legacy aliases exist** (`ink`, `body`, `brand`, `faint`, `brandWash`, `surfaceSubtle`,
  `accentRed`, `primaryPurple` — all aliased to the tokens above) from prior palette
  iterations. **Never use an alias in new code** — use the real token name from the
  table above. The aliases exist only so old screens didn't break mid-migration.

## Typography

Font families in use: **Inter** (body/UI text) and **Playfair Display, italic**
(display headlines — welcome screens, hero copy). No third family exists.

No named type-scale exists in code today — every screen calls
`GoogleFonts.inter(fontSize: N, ...)` inline (85 call sites, `grep`-counted). The sizes
below are the *actual* most common values in use, organized into the roles your project
brief asked for:

| Role | Size | Weight | Family | Where it's used today |
|---|---|---|---|---|
| `display` | 40–52 | 600–700, italic | Playfair Display | Onboarding hero ("Let's make your days healthier"), Auth welcome |
| `heading` | 24–28 | 700 | Playfair Display or Inter | Home greeting, Food Scan step titles |
| `title` | 18–20 | 600–700 | Inter | Screen app-bar titles, section headers ("Today's care", "Nearby care") |
| `body` | 15–16 | 400–600 | Inter | Primary readable text, card titles, button labels |
| `label` | 12–14 | 500–600 | Inter | Secondary text, form labels, timestamps, chips |
| `caption` | 10–11 | 500–700 | Inter | Bottom-nav labels, tiny meta text |

**Known gap:** `display` currently varies between 40 (Auth) and 52 (Onboarding) with no
stated reason — pick one when this scale gets formalized into code. `AppTheme.light()`
already defines a real `TextTheme`, but it's used in exactly one (unrouted) screen —
either start routing screens through `Theme.of(context).textTheme` for these roles, or
retire the unused `TextTheme` definition; don't leave both half-adopted.

## Spacing

The real, dominant scale already in use (most-frequent `SizedBox`/`EdgeInsets` values,
grep-counted): **4, 8, 12, 16, 20, 24, 32, 48**. This matches a standard 4px-base scale
almost exactly — worth adopting as-is rather than inventing a different one.

| Token (proposed) | Value | Typical use |
|---|---|---|
| `xs` | 4 | Icon-to-label gaps, tight inline spacing |
| `sm` | 8 | Between related small elements |
| `md` | 12 | Default gap between stacked items |
| `base` | 16 | Default card/screen padding |
| `lg` | 20 | Card internal padding (larger cards) |
| `xl` | 24 | Section spacing, screen edge padding |
| `xxl` | 32 | Major section breaks |
| `xxxl` | 48 | Rare — large top-of-screen breathing room |

**One special case, not part of the base scale:** `80` appears 4 times, always as
bottom padding on scrollable content so the last item clears the floating bottom nav.
Keep this as a named `bottomNavClearance` constant, not a spacing-scale value — it's
answering a layout question ("how tall is the nav"), not a design-rhythm question.

## Radius

Real values in use, grep-counted: **8, 10, 12, 14, 16, 20, 24, 999 (pill)**.

| Token (proposed) | Value | Use for |
|---|---|---|
| `sm` | 8 | Small inline elements |
| `md` | 12 | Text fields, small chips |
| `lg` | 16 | Standard cards (`ClinicalCard`'s own default) |
| `xl` | 20–24 | Bottom sheets, large cards, modals |
| `pill` | 999 | Buttons, filter chips, distance-pill markers |

`10` and `14` each appear once or twice as one-off choices close to `md`/`lg` — fold
into the nearest scale value when touched, don't perpetuate a third-off value.

## Motion

Real durations in use, grep-counted, split into two genuinely different categories
that shouldn't share one scale:

**Interaction feedback** (should stay fast and consistent):

| Token (proposed) | Value | Use for |
|---|---|---|
| `micro` | 150ms | Toggle/tab-indicator slide (`_AuthToggle`) |
| `standard` | 300–320ms | Page/tab transitions, map camera moves, bottom-nav pill animation |

**Simulated/narrative delays** (deliberately slower — these are standing in for
something that will eventually be real async work, not UI feedback):

- `900ms` — splash screen dwell time before navigating on
- `800ms`–`1000ms` — Food Scan's simulated "AI processing" delay, particle-button
  disintegration animation

Don't use the second category's durations for anything that's supposed to feel like a
UI response — keep them visually and semantically distinct if this becomes a real
`AppMotion` class.

## Iconography

**Not actually consistent — corrected after initially asserting otherwise.** Two
libraries are mixed: `lucide_icons` in every newer (teal-era) screen, and Flutter's
own Material `Icons.*` in the older glassmorphism-era screens that haven't been
migrated yet — `guest_home_screen.dart`, `exercise_detail_screen.dart`,
`video_placeholder.dart`, `map_placeholder.dart`, `account_required_gate.dart`,
`topic_card.dart`, and the unrouted `placeholder_home_screen.dart`. Same root cause as
the `GlassButton`/`GlassSurface` shim issue in `CLAUDE.md` — an unfinished migration,
not two deliberate choices. New code should use `LucideIcons`; migrate the listed
files' icons when they're next touched for another reason, rather than as a standalone
pass.

## What this doc deliberately does not cover

Elevation/shadow values — currently ad hoc per-widget `BoxShadow`s, low-risk enough
not to need a scale yet. Revisit if it becomes inconsistent enough to matter.
