# UI Usability Regression Checklist

Use this checklist before merging launcher UI changes and when validating a release. Mark a check only after verifying it on a running build; static review alone does not count as device verification.

## Automated checks

- [ ] `flutter pub get`
- [ ] `flutter analyze --no-fatal-infos`
- [ ] `flutter test`
- [ ] `flutter build apk --debug`
- [ ] `flutter build appbundle --release` (CI validates the release build with temporary signing credentials)
- [ ] GitHub Actions `Android CI and Play internal release` passes for the commit

## Theme and contrast

- [ ] Verify every screen in light mode and dark mode.
- [ ] Verify system theme changes update all screens, overlays, widgets, borders, disabled controls, and icons.
- [ ] Check text and icon contrast over both plain surfaces and user wallpapers.
- [ ] Confirm selected, current-day, event, completed, disabled, focused, and pressed states are distinguishable without relying on color alone.
- [ ] Check dialogs, bottom sheets, snackbars, empty states, and error states in both themes.

## Layout and display sizes

- [ ] Test a compact-height device and a tall device.
- [ ] Test portrait and landscape orientations where supported.
- [ ] Test increased system font/display size and ensure important text and controls do not clip.
- [ ] Confirm the planner arrow stays above the dock/shell without overlap while opening, closing, dragging, and changing dock context.
- [ ] Check keyboard visibility and bottom insets on forms.
- [ ] Check scrolling at the top and bottom of every scrollable screen.

## Touch, gestures, and accessibility

- [ ] Confirm primary interactive targets are at least 48 × 48 dp where practical.
- [ ] Confirm screen-reader labels describe actions, not just icon appearance.
- [ ] Navigate key controls with TalkBack and verify reading order is logical.
- [ ] Verify text scaling, focus visibility, and semantic state for task completion and drawer open/closed state.
- [ ] Confirm tap, long-press, horizontal swipe, vertical drag, and Android system-back gestures do not conflict.
- [ ] Verify controls remain reachable for one-handed use.

## Calendar, planner, and widgets

- [ ] Tap today, another date, a date with events, and a date without events; confirm navigation and selection feedback.
- [ ] Add, complete, reopen, delete, and undo deletion of a to-do.
- [ ] Add and delete an event; confirm the list and counters update immediately.
- [ ] Verify empty calendar/planner states offer a clear next action.
- [ ] Verify unavailable or failed widget content gives useful feedback rather than a blank or misleading state.
- [ ] Add, remove, and rearrange widgets; confirm the arrangement survives restart.

## Persistence and recovery

- [ ] Force-close and reopen the launcher; verify settings, task data, and layout persist.
- [ ] Change theme and accent color, navigate away, and return; confirm no stale colors remain.
- [ ] Test interrupted flows and dismissible dialogs; confirm no invisible overlay blocks interaction.
- [ ] Confirm destructive actions are reversible where appropriate and error messages explain the next step.

## Final manual sign-off

- [ ] No visible overlap, clipping, overflow, or unintended blank regions.
- [ ] No dead tap targets or controls that respond only intermittently.
- [ ] No unexpected state loss or duplicate items after repeated taps.
- [ ] Attach device/OS, display size, theme, steps to reproduce, and screenshots for any issue found.
