## Home Screen Widget Standards

### Android Launcher Standards (AOSP / Material 3)

**Widget system basics:**
- Widgets are `AppWidget` providers — each declares a `minWidth` / `minHeight` in grid cells (1 cell ≈ 73dp on most phones)
- Standard grid: **4 or 5 columns**, rows auto-sized to screen
- Widget sizes: 1×1, 2×1, 2×2, 4×1, 4×2 (column × row)
- Widgets must be resizable within declared min/max bounds
- Android 12+ supports **dynamic color** via `@color/system_accent1_*` tokens

**What a launcher must implement to host widgets:**
- `BIND_APPWIDGET` permission (requires user grant via `AppWidgetManager`)
- `AppWidgetHost` to manage widget views
- `AppWidgetHostView` per widget instance
- Persist widget IDs in storage — IDs survive process death but not factory reset

---

### For *This* App (Obsidian Pulse, One-Handed)

The right swipe screen should follow one rule: **everything reachable in the bottom 60% of the screen**, since the top 40% is dead space for one-handed thumbs.

#### What belongs there and where:

```
┌──────────────────────────────────────┐
│  ░░░░ DEAD ZONE (top 40%) ░░░░░░░░  │  ← nothing interactive here
│                                      │
│  Weather / ambient card  [4×2]       │  ← top of reach zone, read-only
│                                      │
│  ─────────────────────────────────  │
│                                      │
│  Calendar next event     [4×1]       │  ← one-tap open
│                                      │
│  Music / media player    [4×1]       │  ← most tapped — below calendar
│                                      │
│  ─────────────────────────────────  │
│                                      │
│  Quick-stat row (battery, steps)     │  ← 1×1 chips, non-interactive
│                                      │
│████████████████████████████████████ │  ← dock / nav (existing)
└──────────────────────────────────────┘
```

#### Specific widget candidates and rationale:

| Widget | Size | Position | Reason |
|---|---|---|---|
| **Clock / date** | 4×2 | Upper reach zone | Already on home — mirror here with world clock |
| **Weather** | 4×2 | Upper reach zone | Read-only, glanceable, no tap needed |
| **Next calendar event** | 4×1 | Mid zone | Single tap to open Calendar |
| **Media player** | 4×1 | Mid-low zone | Play/pause is the #1 repeated tap |
| **Battery / quick stats** | 4×1 | Just above dock | At thumb tip — fastest reach |

#### One-handed rules to enforce on the widget screen:
1. **No interactive elements above 55% screen height** — scrollable widget list starts mid-screen
2. **Min touch target: 48×48dp** on all widget controls (Android standard)
3. **Full-width (4-column) widgets preferred** — no two-column hunting across the screen
4. **Horizontal paging only** (left↔right swipe) — no vertical scroll on the page level, only within a widget if it declares it
5. **Widget resize handles** should appear at bottom-corners only — reachable

#### Architecture notes for when you build it:

```
// What you'll need:
- AppWidgetHost (one per launcher process)
- AppWidgetManager (system service)
- BIND_APPWIDGET permission (runtime grant dialog)
- A new screen/route (WidgetScreen) navigated via horizontal page swipe
- SharedPreferences or DB to persist: widgetId → gridPosition map
```

The widget screen should **not** have the dock at the bottom duplicated — the user swipes back to home to use the dock, keeping the widget canvas clean.