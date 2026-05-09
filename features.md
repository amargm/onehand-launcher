Glad you're happy with it. Here are the most impactful things still missing, grouped by value:

---

### High impact — core launcher functionality

**1. App grid / home screen**
There's a clock 



**3. App long-press menu**
Long-pressing an app icon anywhere (folder panel, search results, home grid) should offer: pin to home, add to folder, uninstall shortcut. This is the standard mental model users expect.

**4. Swipe-up gesture**
Swiping up from the dock area should open search — the most common one-handed gesture. Currently you have to tap the search circle precisely.

---

### Medium impact — polish and ergonomics

**5. BroadcastReceiver instead of polling**
Replace the 2s timer in `HeadphoneNotifier` with a native `BroadcastReceiver` for `Intent.ACTION_HEADSET_PLUG` and `BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED`. Zero battery cost when nothing changes, instant response on plug/unplug.

**6. Haptic feedback**
A short `HapticFeedback.lightImpact()` on every dock tap, folder open/close, and app launch. Gives tactile confirmation that something happened — especially important for one-handed use where the user can't always look at the screen.

**7. Folder panel app labels**
The inline folder panel shows 44px icons but no names. Small 8px labels below each icon would reduce guesswork, especially for similar-looking icons.

**8. Widget support**
A single resizable widget slot on the home screen (weather, calendar, music controls). This is what differentiates launchers.

---

### Low effort, high perceived quality

**9. Default launcher banner behaviour**
Currently the "set as default" banner shows every launch. It should only appear once, or have a permanent dismiss option stored in SharedPreferences.

**10. App icon loading skeleton**
While `appsProvider` is loading, show shimmer placeholder circles instead of an empty dock row. Currently the dock feels broken for ~1s on cold start.

**11. Folder reordering**
Drag-to-reorder folders in the dock (and in Settings). Right now the order is fixed at creation time.

**12. Search history / recents**
When the search bar is empty, show the 5 most recently launched apps instead of all 32 apps in undefined order.

---

