# Kora Launcher: Behavioral Architecture & Psychology
*A deep-dive document designed for behavioral psychology AI ideation to design the ultimate anti-distraction system.*

## 1. Core Philosophy
Kora Launcher is an ultra-minimalist Android home replacement app designed to **break the mindless scroll loop** and reduce screen time. Instead of relying on passive "Screen Time" metrics that users simply ignore, Kora acts as an aggressive, active gatekeeper. It forces users to transition from *mindless reactive* behavior to *conscious intentional* behavior.

## 2. The Current Architecture
The launcher replaces the entire Android operating system home screen, giving it top-level priority and systemic authority over the device.

### A. The Aesthetic of Focus
- **Pure Black Interface:** The entire launcher runs on a solid `#000000` background. There is no colorful wallpaper, no widgets, and no notifications on the home screen.
- **The Precision Clock:** At the top of the screen sits a large, beautifully smooth digital clock displaying time down to the **millisecond** (`HH:MM:SS.MS`). This fast-ticking clock is a psychological anchor that grounds the user in the present reality of passing time, creating subtle anxiety about wasting it.

### B. The Intention Anchor
- Every day exactly at midnight, the home screen resets. The next time the user unlocks their phone, a mandatory overlay appears asking: **"What is your intention today?"**.
- The user must type their highest priority goal (e.g., "Finish the report"). 
- This text remains permanently pinned in huge letters in the center of the home screen, meaning every time they unlock their phone to open Instagram, they stare directly at the goal they are actively ignoring.

### C. App Accessibility Friction
- **No App Icons:** The home screen has zero colorful icons (except 4 essential text-based quick actions hidden at the bottom: Phone, Messages, Browser, Camera).
- **Search-to-Launch:** To open an app, the user must swipe up into a pure black App Drawer. The keyboard automatically opens. To open YouTube, the user must consciously *type* "Y-o-u". If it narrows down to exactly one result, it auto-launches, rewarding intentional searching while explicitly punishing passive icon scanning.

### D. The Micro-Reflection Gate (Anti-Distraction)
If a user searches for a "Flagged" addictive app (like WhatsApp, Instagram, or TikTok), the app is literally intercepted by Kora before it opens.
- The screen goes black and shows the app icon with the prompt: **"Why are you opening this?"**
- They cannot proceed until they actively diagnose their urge by selecting one of three buttons:
  1. `Habit / Boredom`
  2. `Quick Task`
  3. `Important Work`
- Submitting the answer introduces exactly enough cognitive friction (Mindfulness) to short-circuit the dopamine loop of opening apps unconsciously. Only after selecting a reason can they tap "Open anyway" or "Never mind".

### E. Unfiltered Usage Dashboard
When swiping right from the home screen, the user enters the Usage Dashboard. 
- Unlike Apple/Google's official "Digital Wellbeing" (which hides background processes and system components to make the charts look nicer), Kora asks Android for the raw, brutal foreground execution time of every application in the drawer. 
- The user sees exactly how many minutes they've genuinely spent staring at an app today, sorted from highest to lowest.

---

## 3. The Current System Capabilities (Android Loophole)
Modern Android Operating Systems (Android 10+) aggressively block apps from suddenly jumping to the foreground or interrupting the user. However, there is one massive exception: **The Default Home App**.
Because Kora is the designated home launcher, it possesses "Ultimate System Authority" to pull itself to the foreground at any given moment, instantly forcing whatever app the user is staring at (e.g., TikTok) to minimize into the background.

## 4. The Request for the Psychology AI
**The Problem Statement:**
The user has passed the "Micro-Reflection Gate" and successfully opened the addictive app. Currently, we have no systemic way of stopping them from scrolling endlessly for the next 2 hours.

**The Objective:**
We need to design the "Ultimate System Control." Now that Kora Launcher has the raw systemic authority to pull the user *out* of an active app at will, we need the psychology AI to draft the most effective, behavior-changing, and unique method for enforcing **Session Limits**.

Should we aggressively rip them back to the home screen after exactly 5 minutes? Should we slowly fade the screen to black? Should we force them to do a physical action? 

*Draft the ultimate psychological mechanism for stopping the limitless scroll once an app is already open, specifically leveraging the Launcher's ability to forcefully minimize active apps.*
