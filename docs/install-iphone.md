# Installing Peak Season on iPhone – step-by-step guide

This guide is for everyone, including people who have never installed an app outside the App Store.
Peak Season is not on the App Store. You install it yourself, for free, with an app called **SideStore**.

## At a glance

| | |
|---|---|
| **Cost** | Free |
| **What you need** | An iPhone with iOS 15 or later, a computer (Windows or Mac) **only for the first setup**, a USB cable, Wi-Fi, your Apple Account (Apple ID) |
| **First setup** | About 30–45 minutes, once |
| **After that** | Everything from the iPhone. About 1 minute **once a week** to "refresh" the apps |
| **Updates** | They appear by themselves in SideStore: one tap, no computer |
| **Your data** | Favourites, lists and settings are always kept, even if the app expires |

## Why there is a weekly refresh

Apple only lets you install apps from outside the App Store if they are "signed" with an Apple Account.
With a free Apple Account, Apple makes the signature last **7 days**.
After 7 days the app stays on your iPhone with all your data, but **it does not open** until you refresh it.
Refreshing takes one tap in SideStore. Nothing is deleted or downloaded again.

## The pieces, and what each one does

| Piece | Where | What it does | Link |
|---|---|---|---|
| **iTunes** (Windows only) | Computer | Lets Windows talk to the iPhone through the cable | [Apple (recommended)](https://www.apple.com/itunes/download/win64) · [Microsoft Store](https://apps.microsoft.com/store/detail/9PB2MZ1ZMB1S) |
| **iloader** | Computer | Puts SideStore on the iPhone and gives it the "pairing file" | [iloader.app](https://iloader.app) · [GitHub](https://github.com/nab138/iloader/releases/latest) |
| **Pairing file** | iPhone (inside SideStore) | A "permission" that lets SideStore install and refresh apps without a computer | Created by iloader |
| **LocalDevVPN** | iPhone | A VPN that stays **inside your iPhone**: it does not send your data anywhere. SideStore needs it to install and refresh apps | [App Store](https://apps.apple.com/app/localdevvpn/id6755608044) |
| **SideStore** | iPhone | Your small personal app store: it signs, installs, updates and refreshes Peak Season | [sidestore.io](https://sidestore.io) |
| **Peak Season source** | iPhone (inside SideStore) | The "channel" that tells SideStore about every new version of Peak Season | Added in Part 5 |
| **Peak Season** | iPhone | The app | [Releases](https://github.com/NunzioLangiulli/peak-season-app/releases) |

---

## Part 1 – Prepare the computer (10 minutes)

### Windows

1. Check that Windows is 64-bit: press `Win + R`, type `control /name microsoft.system` and press Enter. "System type" must say **64-bit** (Windows 10 on ARM is not supported).
2. Install **iTunes** [from Apple's website](https://www.apple.com/itunes/download/win64) (recommended) or [from the Microsoft Store](https://apps.microsoft.com/store/detail/9PB2MZ1ZMB1S). You do not need to sign in to it.
3. Download and install **iloader**: [iloader-windows-x64.msi](https://github.com/nab138/iloader/releases/latest/download/iloader-windows-x64.msi).

### Mac

1. Download **iloader**: [iloader-darwin-universal.dmg](https://github.com/nab138/iloader/releases/latest/download/iloader-darwin-universal.dmg).
2. Open the file and drag iloader into *Applications*. Nothing else is needed.

> Download iloader only from [iloader.app](https://iloader.app) or its [GitHub page](https://github.com/nab138/iloader). Other sites may offer modified copies.

## Part 2 – Prepare the iPhone (5 minutes)

1. Make sure the iPhone has a **passcode** (*Settings → Face ID & Passcode*).
2. Connect it to **Wi-Fi** (mobile data is not enough for SideStore).
3. Install **[LocalDevVPN](https://apps.apple.com/app/localdevvpn/id6755608044)** from the App Store.
4. Open LocalDevVPN, tap **Connect**, then **Allow** when iOS asks to add a VPN configuration, and enter your passcode.

## Part 3 – Install SideStore from the computer (10 minutes)

1. Connect the iPhone to the computer with the cable. If the iPhone asks **"Trust This Computer?"**, tap **Trust** and enter your passcode.
2. Open **iloader** on the computer.
3. Sign in with your **Apple Account** (email and password). Type it exactly: it is case-sensitive.
   - It can be your normal Apple Account. It is only used to sign apps.
4. Select your iPhone in the list.
5. Click **Install SideStore (Stable)** and wait for it to finish.
6. Still in iloader: click **Manage Pairing File**, then **Place** next to SideStore. Wait for the green message *"Pairing file placed successfully!"*.

## Part 4 – Turn SideStore on, on the iPhone (5 minutes)

1. **Trust your Apple Account:** *Settings → General → VPN & Device Management*. Under **Developer App**, tap your Apple Account, then **Trust** (on iOS 18 and later: **Allow & Restart** and your passcode).
2. **Turn on Developer Mode** (iOS 16 and later): *Settings → Privacy & Security*, scroll to the bottom, **Developer Mode** → on. The iPhone restarts; after the restart, confirm with **Turn On** and your passcode.
3. Open **LocalDevVPN** and tap **Connect**.
4. Open **SideStore** and sign in with **the same Apple Account** you used in iloader.
5. Go to the **My Apps** tab and tap the **7 DAYS** button next to SideStore. If it asks to create or revoke a certificate, tap **Yes** / **Refresh Now**.

You can now unplug the cable. **From here on you no longer need the computer.**

## Part 5 – Add the Peak Season source and install the app (5 minutes)

The source is the "channel" of Peak Season inside SideStore. You add it once: from then on SideStore installs the app from it and shows you every new version by itself.

1. Make sure Wi-Fi and **LocalDevVPN** are connected.
2. Copy this address (on GitHub, the copy button is on the right of the box):

   ```
   https://raw.githubusercontent.com/NunzioLangiulli/peak-season-app/main/sidestore/source.json
   ```

3. Open **SideStore → Sources**, tap **+**, paste the address and confirm with **Add Source**.
4. Open **SideStore → Browse**, find **Peak Season** and tap the install button (**FREE**).
5. If SideStore asks whether to keep the **app extensions**: Peak Season contains one, the Live Activity (the shopping list on the lock screen).
   - **Keep it** if Peak Season is the only app you install with SideStore.
   - **Remove it** if you need a free slot for another app: Peak Season works the same, without the list on the lock screen.
6. Wait a few seconds: Peak Season appears on the Home Screen. Done!

## Every week – refresh (1 minute)

1. Connect to Wi-Fi and open **LocalDevVPN → Connect**.
2. Open **SideStore → My Apps** and tap **Refresh All**.

The counter next to each app shows the days left. SideStore also tries to refresh in the background on its own, but do not rely on it: **refresh by hand at least once a week.**
You can switch off LocalDevVPN when you are done.

> **If you forget:** Peak Season stops opening but keeps all your data. Refresh in SideStore and it works again.
>
> **If SideStore itself expires** (more than 7 days without refreshing): SideStore can no longer refresh anything and you need the computer again (repeat Part 3 and Part 4, step 5). Your apps and data stay on the iPhone.

## Updating Peak Season to a new version

**No computer is needed**, and you do not have to download anything by hand: thanks to the source you added in Part 5, SideStore already knows about every new version.

1. Turn on Wi-Fi and **LocalDevVPN**.
2. Open **SideStore → My Apps**: when a new version is out, it is listed under **Updates**. Tap **Update**.

The update installs over the old version: favourites, lists and settings are kept, and the 7-day counter starts again.
In the app, *Settings → Check for Updates* also tells you when a new version is out.

> **Update not showing yet?** Pull down the list in **My Apps** to check again. A new version reaches the source a few minutes after it is published on GitHub.

## Why SideStore needs Wi-Fi and LocalDevVPN

Apple only allows "developer" apps to be installed through a special channel normally used by a computer (for example a Mac with Xcode).
SideStore pretends to be that computer, from inside your iPhone:

- **LocalDevVPN** creates a small network loop that leads back to the iPhone itself, so SideStore can "talk" to the iPhone as if it were a computer connected to it. The traffic never leaves your iPhone: it is not a VPN that hides or redirects your browsing.
- **Wi-Fi** is needed because iOS only opens that channel over a network connection such as Wi-Fi: mobile data does not work. SideStore also needs internet access to sign apps with your Apple Account on Apple's servers.

You only need both **while installing, updating or refreshing**. The rest of the time you can switch LocalDevVPN off, and Peak Season works offline as usual.

## What must stay installed, and what you can remove

### On the iPhone

| App | Can I uninstall it? | Why |
|---|---|---|
| **Peak Season** | Yes, whenever you want | It is the app |
| **SideStore** | ❌ **No – keep it** | It is the only thing that refreshes and updates Peak Season. Without it, Peak Season stops opening after 7 days, and reinstalling SideStore needs the computer again |
| **LocalDevVPN** | ❌ **No – keep it** (but you can leave it switched off) | SideStore needs it every time it installs, updates or refreshes an app. It is a normal App Store app: it never expires and does not use one of your 3 slots |

### On the computer

| Program | Can I uninstall it? | Why |
|---|---|---|
| **iloader** | ✅ Yes, after the setup | It is only needed for the first setup. Keeping it is handy: you need it again if the pairing file stops working or SideStore expires |
| **iTunes** (Windows) | ✅ Yes, after the setup | Only iloader needs it. If you remove it, reinstall it before using iloader again |

## How long each thing lasts

| What | How long it lasts | What to do |
|---|---|---|
| Peak Season | 7 days per refresh | Refresh weekly in SideStore (an update also restarts the 7 days) |
| SideStore | 7 days per refresh | Refreshed together with the other apps |
| LocalDevVPN | Forever (normal App Store app) | Turn it on only when installing, updating or refreshing |
| Peak Season source | Forever | Nothing: SideStore checks it by itself |
| Pairing file | Until an iOS update, an iPhone reset, or (rarely) without a clear reason | If SideStore shows connection errors, place it again with iloader (Part 3, step 6) |
| Computer setup | Needed once | Again only if the pairing file stops working or SideStore expires |

## Limits of a free Apple Account (Apple's rules)

- At most **3 active apps** installed this way, **SideStore included** (app extensions may also count).
- At most **10 different apps** installed in 7 days.
- With a paid Apple Developer account (99 €/year) apps last 1 year and the 3-app limit disappears, but nobody needs it just for Peak Season.

## Troubleshooting

| Problem | Fix |
|---|---|
| SideStore cannot connect / installation stuck | Check that Wi-Fi **and** LocalDevVPN are both on. Turn off ad-blocking or DNS-blocking apps. Close and reopen SideStore and LocalDevVPN |
| Errors after an iOS update | The pairing file needs replacing: connect to the computer, open iloader → **Manage Pairing File** → **Place** next to SideStore |
| Cannot sign in to SideStore | Usually a temporary server problem: wait and retry, or change the *Anisette server* in SideStore's settings |
| An app does not open | It has expired: refresh it in SideStore |
| SideStore does not open | It has expired: repeat Part 3 and Part 4, step 5 with the computer |
| Peak Season is not in **Browse** | Check under **Sources** that the Peak Season source is there; if not, add it again (Part 5, steps 2–3) |

More help: [SideStore troubleshooting](https://docs.sidestore.io/docs/troubleshooting/common-issues) · [SideStore FAQ](https://docs.sidestore.io/docs/faq) · [SideStore Discord](https://dis.sidestore.io).
For problems with Peak Season itself, open an [issue](https://github.com/NunzioLangiulli/peak-season-app/issues).

## Uninstalling

Touch and hold Peak Season, SideStore or LocalDevVPN on the Home Screen → **Remove App**. You can uninstall iloader and iTunes from the computer at any time.

## Useful links

- [SideStore website](https://sidestore.io) · [Official guide](https://docs.sidestore.io/docs/installation/prerequisites)
- [iloader](https://iloader.app)
- [LocalDevVPN on the App Store](https://apps.apple.com/app/localdevvpn/id6755608044)
- [Peak Season releases](https://github.com/NunzioLangiulli/peak-season-app/releases)
- [Peak Season source](https://raw.githubusercontent.com/NunzioLangiulli/peak-season-app/main/sidestore/source.json)

*SideStore, iloader and LocalDevVPN are independent projects, not made by Peak Season. This guide follows their official documentation as of November 2026.*
