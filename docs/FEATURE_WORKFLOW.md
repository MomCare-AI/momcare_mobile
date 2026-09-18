# MomCare Patient App — Feature Implementation Workflow

How a new feature gets built in this repo from here on. This is a procedure, not a
fact about the project — `CLAUDE.md` holds the facts/rules and is always loaded;
this file gets read (or pasted from) at the *start of each new feature*, not kept
loaded the whole session.

The sequence, every time:

```
PLAN (stop and get approval)
  ↓
IMPLEMENT — one phase only
  ↓
TEST — prove it, don't just claim it
  ↓
REVIEW — a different pass, not the implementer re-reading their own work
  ↓
PROFILE — only with evidence, only if something's actually slow
  ↓
COMMIT — one focused commit per phase
```

Never: "build the whole feature" in one shot. `hospital_discovery_screen.dart` (711
lines, mixing map rendering + 4 permission states + network status + two different
popup UIs in one file) is the concrete, in-repo example of what skipping phases
produces — see `CLAUDE.md`'s known-debt list. Don't repeat it for Vitals/Chat/Food-AI.

---

## 1. Plan first — don't start coding

Before writing any feature code, answer these and get explicit approval before phase
1 starts:

1. **Existing code to reuse** — screens/widgets/models/providers/repositories that
   already do something adjacent. Check `lib/shared/widgets/`, `lib/theme/`, and the
   closest existing feature (`hospitals` is the reference implementation) before
   writing anything new.
2. **User flow** — the complete journey, including what happens on every dead end
   (permission denied, no data, offline).
3. **State model** — every real state: initial/loading/success/empty/permission-
   denied/error/offline. Not just "loading and loaded."
4. **Architecture** — `UI → provider (StateNotifier) → repository → service/API`,
   matching the shape in `CLAUDE.md`'s Architecture section. If a repository doesn't
   exist for this feature's data source yet, this is where it gets added.
5. **Data model** — what a model needs, sourced from a real contract if one exists.
6. **API requirements** — if a MomCare-backend endpoint is missing, **document the
   contract you need, don't invent an implementation against a guess.** This is
   already the discipline documented in `docs/PRODUCT_RULES.md`'s deferred-feature
   table — extend it, don't bypass it.
7. **Reuse plan** — the specific existing files this feature will import from.
8. **Implementation phases** — broken small enough that each phase is independently
   testable and committable (see the Nearby Hospitals example below).
9. **Testing plan** — what gets a unit/widget test, referencing `CLAUDE.md`'s Testing
   section (including the stepped-`pump()` requirement for anything animated).
10. **Performance considerations** — likely rebuild scope, network frequency,
    anything resembling `hospital_discovery_screen.dart`'s full-`Stack` rebuild on
    every location tick.
11. **Security/privacy considerations** — per `CLAUDE.md`'s Security section and
    `docs/PRODUCT_RULES.md`'s clinical-safety rules. Explicitly note if this feature
    touches anything currently named as blocked/deferred there.

**Stop here. Do not implement until this plan is approved.**

## 2. Implement — one phase at a time

Rules for each phase:

- Modify only the files that phase actually needs.
- Reuse existing architecture — don't redesign something adjacent because it was
  convenient while you were in the file.
- Don't install a dependency unless the phase genuinely can't be done without one
  (see `CLAUDE.md`: "do not add a package that an existing dependency already
  solves").
- If you hit a real architectural problem mid-phase, **stop and report it** — don't
  silently redesign the project to route around it.
- Run `dart format` and `flutter analyze` on the changed files.
- Report back: files changed, what changed, tests run, test results, remaining risks.

## 3. Test — prove it, don't just claim it

"It compiles" is not "it works." Before calling a phase done:

- Run `flutter analyze` and `flutter test`.
- Walk the affected flow for: loading, success, empty, error, offline, permission-
  denied, navigation, disposal (no leaked controllers/streams/tickers), and whether
  the layout holds up at different sizes.
- Report anything you genuinely could not verify — don't imply it was checked when it
  wasn't.

## 4. Review — a separate pass, not implementer self-review

After a phase is implemented and tested, start a **second pass** that doesn't assume
the implementation was right:

> Act as a senior Flutter code reviewer who did not write this code. Review for:
> architecture violations against `CLAUDE.md`, unnecessary abstractions, duplicated
> logic, race conditions, lifecycle bugs, memory leaks, unnecessary rebuilds,
> unnecessary API calls, missing states (loading/empty/error), permission issues,
> security/clinical-safety issues against `docs/PRODUCT_RULES.md`, accessibility,
> test gaps, and maintenance risk. Rank findings CRITICAL/HIGH/MEDIUM/LOW, each with
> file, problem, why it matters, recommended fix. Do not fix anything yet — wait.

## 5. Profile — only with evidence

Don't optimize on a guess, and don't judge performance from a debug build (debug-mode
jank isn't evidence of anything — see `CLAUDE.md`'s Performance section). If a
concrete performance question exists:

> Analyze rebuild frequency, frame performance, memory, network requests, image
> sizes, list/map rendering, and unnecessary state propagation for this feature,
> using a **profile build**, not debug. Identify which problems are actually
> measurable versus theoretical. Propose the smallest safe optimization. Don't
> sacrifice readability or architecture for a negligible gain.

## 6. Commit — one focused commit per phase

`git status` / `git diff` / `flutter analyze` / `flutter test` before every commit.
One phase, one commit, a message that says what the phase actually did
(`feat(patient): add hospital location permission flow`, not
`feat(patient): nearby hospitals`). This is what makes a bad phase revertable
without losing the good ones next to it.

---

## Worked example: how Nearby Hospitals should have been phased

It wasn't built this way originally (see `CLAUDE.md` known-debt #1 for the resulting
711-line file) — this is the phasing it should have followed, and the template for
Vitals/Chat/Food-AI next:

1. Location permission + service (`location_provider.dart` — this part was actually
   done cleanly).
2. Permission UX (the four permission-state screens).
3. Map rendering shell (`flutter_map` + tile layer, no markers yet).
4. Hospital repository + data source (Overpass today; swappable later per
   `docs/patient-app-plan.md` §3a's Option A/B discussion).
5. Markers (the Airbnb-style distance pills).
6. Hospital list (the draggable sheet).
7. Map/list selection sync.
8. Hospital detail popup.
9. Directions/appointment entry point.
10. Tests + a performance pass once real usage exists.

Each of those is independently testable and committable — the actual file would have
stayed under ~150 lines per phase instead of accumulating into one 711-line class.
