# NameDayApp (macOS Menu Bar)

Minimal, elegant macOS menu bar app that shows Czech name days. It displays **today’s** and **tomorrow’s** name day, auto‑updates at midnight (Europe/Prague), and can launch automatically at login.

> ✅ All data is local (JSON file). No analytics, no network requests.

---

## App Store

Get it on the Mac App Store:

**NameDayApp on the Mac App Store** → [https://apps.apple.com/app/6752279964](https://apps.apple.com/app/6752279964)


---

## Features

* **Menu bar glance:** Shows today’s name day directly in the menu bar.
* **Popover details:** Two elegant blocks: *Dnes má svátek* (today) and *Zítra bude mít svátek* (tomorrow).
* **Prague time zone:** All date math uses `Europe/Prague`.
* **Auto refresh:** Reschedules a task to refresh at the next midnight and reacts to wake/clock changes.
* **Launch at login:** Uses `SMAppService` to enable/disable start at login.
* **Local data:** Reads `svatek.json` either from app bundle or `Application Support/<bundle id>/`.

---

## Requirements

* macOS 13 Ventura or newer (uses `MenuBarExtra`).
* Xcode 15 or newer.
* Swift 6 / Swift Concurrency.

---

## Installation

### From the Mac App Store

1. Open the Mac App Store link above.
2. Click **Get** → **Install**.
3. Launch the app; it will appear in the **menu bar**.

### Build from Source

1. Clone the repository.
2. Open the project in **Xcode 15+**.
3. Select the **NameDayApp** scheme and **My Mac** destination.
4. Build & Run (⌘R).

> Note: To use **Launch at Login**, your bundle identifier should remain consistent across builds. For sandboxed App Store builds, ensure appropriate capabilities are enabled.

---

## Using the App

* The **menu bar title** shows today’s name day (monospaced digits, single line).
* Click the icon/title to open the popover:

  * **Dnes má svátek:** Today’s name(s).
  * **Zítra bude mít svátek:** Tomorrow’s name(s).
  * **Otevřít po startu:** Toggle to enable/disable launch at login.
  * **Ukončit:** Quit the app.

> Tip: The popover uses `.menuBarExtraStyle(.window)` to ensure controls (like Toggle) are fully interactive.

---

## Data Source (`svatek.json`)

The app expects a JSON mapping of **MM-DD** → **String** or **\[String]**.

**Example:**

```json
{
  "01-01": "Nový rok",
  "01-02": ["Karina", "Karolína"],
  "05-12": "Pankrác"
}
```

**Lookup logic:**

* First look in `~/Library/Application Support/com.kadrnozka.nameDay/svatek.json` (created on demand if you place it there).
* Fallback to `svatek.json` bundled with the app.

**Display rules:**

* Arrays are joined by `", "` (comma + space).
* Empty/whitespace values render as `–`.

---

## Time & Scheduling

* All date computations use a custom **Prague** calendar:

  * `Calendar(identifier: .gregorian)` with `timeZone = Europe/Prague`.
* Midnight scheduling:

  * Calculates **next midnight** and sleeps until then using `Task.sleep`.
  * On wake (`NSWorkspace.didWakeNotification`) or calendar day change (`.NSCalendarDayChanged`), refreshes data.

---

## Launch at Login

* Uses the modern `ServiceManagement` API (`SMAppService.mainApp`).
* `register()` / `unregister()` is wrapped by a user toggle in the popover.
* Errors are printed to the console.

---

## Privacy

* 100% offline. No network calls.
* Reads a local JSON file only.

---

## Troubleshooting

* **Toggle not clickable in popover**

  * Ensure the scene applies `.menuBarExtraStyle(.window)`.
  * Keep the Toggle as `.checkbox` for best reliability within a menu bar popover.

* **No names showing (`–`)**

  * Verify the `svatek.json` exists and contains an entry for today’s `MM-DD`.
  * Check both locations (Application Support first, then bundle).

* **Launch at login doesn’t stick**

  * Confirm your app’s bundle identifier is stable.
  * If testing outside the App Store, macOS may require re‑granting permissions after moving the app.

---

## Project Structure Notes

* **`NamedayViewModel`** (MainActor):

  * Publishes `displayText`, `tomorrowText`, and `launchAtLoginEnabled`.
  * Handles loading JSON, day changes, and login item state.
* **`NamedayStore`**: Loads `svatek.json` from Application Support or bundle.
* **`PragueDateKey`**: Builds `MM-DD` keys and computes tomorrow/next midnight.
* **SwiftUI Views**: `MenuBarExtra` popover with two info blocks, a checkbox toggle, and a capsule quit button.


## License

MIT License

Copyright (c) 2025 Daniel Kadrnožka

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
