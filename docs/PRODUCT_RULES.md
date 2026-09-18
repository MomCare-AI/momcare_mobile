# MomCare Patient App — Product Rules

What this app is not allowed to do, and why — distilled from the platform's own
locked decisions in `docs/PLAN.md` and `docs/patient-app-plan.md` (project root,
sibling to this repo). Those are the canonical, dated source; this file is a
working distillation for engineering sessions on this repo specifically. If this
file and those ever disagree, the project-root docs win — update this file, not the
other way around.

## The one rule everything else follows from

**A `Patient` clinical record is never created by this app.** A hospital creates a
`Patient` row; this app only ever attaches an optional login to a `Patient` a hospital
already made. This is why the app has no self-service sign-up path to a full clinical
identity — see "Account model" below for exactly where that line sits today.

## Account model

- The account is **optional per patient**, never a precondition for being monitored.
  A patient with no app account is not a bug or a lesser case — it's the default.
- Self-signup (creating a `User` before any hospital relationship exists) is **in
  scope**, reversing an earlier "deferred" decision — but it still can only ever
  produce a `User`, never a `Patient`. Two questions are still open before this can be
  built for real (not guessed at): what a hospital "accepting" a signup request
  actually creates (books a visit vs. auto-creates a bare `Patient` row), and hospital
  geocoding doesn't exist yet at all. Don't build the real request-acceptance flow
  until both are answered.
- Clinicians never self-register in this ecosystem, on the web portal or here —
  don't build a "sign up as a doctor" path.

## What's real vs. not-yet-backed (as of 2026-09-18)

Only these have any real backend/data behind them for a signed-in patient, once the
backend endpoints in `docs/patient-app-plan.md` §6 exist: own pregnancy status, own
risk level, own vitals (read-only), own alerts, own care team. Everything below is
**named and deliberately deferred, not silently dropped** — don't build the real
version of any of these without the specific open question next to it being answered
first:

| Feature | Blocked on |
|---|---|
| Patient-entered vitals feeding the risk engine | Whether self-reported/estimated data should touch `risk_rules.py` at all — needs the same clinical review already planned for that file. |
| AI food-photo nutrition scanner | No vision/food-recognition model chosen or evaluated; same risk-engine question as above if it's ever wired to anything clinical. |
| Patient ↔ doctor chat | No messaging model, transport, or notification infra exists in either repo. |
| Hospital appointment request/booking | The self-signup open question above, plus real geocoding not existing yet. |
| Patient-visible, reply-able doctor notes | **Reverses** an explicit existing rule (see below) — needs a named, conscious decision from whoever owns clinical-communication risk, not just a UI. |
| Push notifications | No mobile infra (FCM, device registration) built yet — sequenced, not blocked on a decision. |

Build the UI for any of these against placeholder/sample data if useful (same pattern
already used for Hospital Discovery before it got real OSM data) — just don't wire a
fake "success" behind any of them.

## Rules that must not be broken

Carried over from the platform-wide rules (`docs/PLAN.md` §5) — these apply to this
app exactly as much as the web portal:

- Never fabricate clinical data. Empty states, not placeholder numbers that look real.
- Colour is reserved for clinical state, never decoration, and never carries meaning
  alone — every state needs a text label too.
- Absent data stays visibly absent ("No reading," never a normal-looking default).
- AI output is always labelled decision support, never diagnosis — this is doubly true
  here, since the patient reads it directly with no clinician in between.
- `ClinicalNote` is clinician-only — "written about her, not for her." A patient-visible
  or reply-able notes feature is a reversal of this, not an extension of it (see table
  above); it needs the same explicit-reversal treatment the self-signup decision got,
  not a quiet UI change.

## Guest mode

- Guest content is educational and non-diagnostic only: nearby hospitals (real, from
  OpenStreetMap — see `CLAUDE.md`), nutrition/exercise/education topics (sample
  placeholder content, clearly generic, never real medical guidance presented as real).
- Anything requiring an account is gated with an honest "Account required" prompt
  (`shared/widgets/account_required_gate.dart`) at the moment it's needed — never a
  dead button, never a feature that quietly does nothing.

## Copy tone

Patient-facing copy for clinical states (risk level, alerts) is **not** automatically
the same copy the web portal uses for clinicians. This is a stated open item in
`docs/patient-app-plan.md` §7 — don't default to reusing clinician-facing strings
verbatim without a tone pass when a real risk/alert screen gets built.
