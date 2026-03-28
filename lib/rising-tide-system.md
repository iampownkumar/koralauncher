# Rising Tide System — Full Architecture

## Core Philosophy
> "Force will never work. Ask why."

The system does not block. It **interrupts the autopilot** and forces a conscious choice. Every entry point — notification tap, recent apps, app drawer, direct tap — goes through the same gate.

---

## The Universal Gate

```
ANY app open attempt
(notification / recent / drawer / direct tap)
        ↓
RisingTideService.getStage(packageName)
        ↓
Stage 1 → open directly
Stage 2 → Stage2Screen
Stage 3 → Stage3Screen
Stage 4 → Stage4Screen
```

This works because your **InterceptionScreen already sits between every app tap and the actual launch.** You just need to make sure notification taps and recents also route through it.

For notifications and recents — Android's **Accessibility Service** is the only reliable way to intercept these. One service, watches all app foreground events, routes through your gate.

---

## The Four Stages

### Stage 1 — Whisper
**When:** 0% to 49% of daily limit

**What happens:**
- App opens immediately
- No friction whatsoever
- Background: session logged silently
- User feels nothing — the tide is low

**Logged:**
- App name
- Open time
- Stage = 1
- Today's intention linked

---

### Stage 2 — Dim
**When:** 50% to 99% of daily limit

**What happens:**
- Full screen blur overlay — unclosable
- Back button disabled
- Recent apps escape disabled
- Cannot be dismissed without completing the flow

**The Flow:**
```
Blur appears
      ↓
App name + minutes used today shown
      ↓
Today's intention shown
      ↓
Mood question appears
(must select one — no skip)
      ↓
After mood selected → countdown begins (5 seconds)
      ↓
Buttons activate
      ↓
User chooses: Go Back or Continue
      ↓
Decision logged → action taken
```

**Reopen Lock:**
If user force closes and reopens within 5 minutes → Stage 2 appears again immediately. Lock stored in SharedPreferences with timestamp and package name.

**Mood Options:**
- 😌 Relaxing
- 😤 Procrastinating
- 🎯 Taking a break
- 😶 Just habit

**Logged:**
- Mood selected
- Time spent on Stage 2 screen
- Decision (continue / go back)
- Override count updated
- Intention linked

---

### Stage 3 — Mirror
**When:** 100% to 199% of daily limit OR 2 overrides today

**What happens:**
- Stronger blur, darker overlay
- No mood question — direct confrontation
- Shows today's intention vs actual behaviour
- Shows how many times opened today
- Shows total minutes today
- Asks one direct question

**The Flow:**
```
Dark blur appears
      ↓
App name + "Limit reached" shown
      ↓
Today's intention shown
      ↓
Stats shown:
"You've opened this X times today"
"Total time: X minutes"
      ↓
One direct question:
"Is this helping you [intention]?"
      ↓
5 second mandatory wait — no mood needed
      ↓
Two choices appear:
"Yes, I need this" / "No, take me back"
      ↓
Decision logged → action taken
```

**If Continue chosen:**
- Override count increments
- If override count hits 3 → next open triggers Stage 4
- App launches

**If Go Back chosen:**
- Logged as conscious refusal
- Returned to home screen
- Small home screen badge: "Good call 👍"

**Logged:**
- Decision
- Override count
- Open count today
- Total minutes today
- Intention linked

---

### Stage 4 — Silence
**When:** 200%+ of daily limit OR 3 overrides today

**What happens:**
- Complete block — app does not launch
- Heaviest blur
- Calm message — not punishing, just firm
- One escape route: complete a task

**The Flow:**
```
Full block screen appears
      ↓
App name shown
      ↓
Today's stats shown:
"X minutes today. X times opened."
      ↓
Today's intention shown
      ↓
Calm message:
"You've chosen to stop here today."
      ↓
Two options:

Option A: "Come back tomorrow"
→ Returns to home screen
→ App stays blocked until midnight reset

Option B: "Complete a task to unlock 5 min"
→ Shows today's task list
→ User marks one complete
→ 5 minute unlock granted
→ After 5 minutes → Stage 4 returns
→ Unlock only works ONCE per day
```

**Logged:**
- Block event
- Whether task unlock was used
- Unlock time
- Whether they used the 5 minutes
- Intention linked

---

## Intention Skip Handling

```
Phone unlocked → morning first open
        ↓
Has today's intention been set?
        ├── YES → home screen
        └── NO → IntentionScreen
                      ↓
              10 second countdown
              Skip button hidden
                      ↓
              After 10s:
              Skip button appears (small, faded)
                      ↓
        ┌─────────────┴─────────────┐
      Skip                       Set intention
        ↓                              ↓
Logged as "skipped"          Logged as "set"
        ↓                              ↓
Home screen                    Home screen
with subtle reminder:          normal
"No intention set today"
(shown all day, small text)
```

**Fake Intention Detection:**
- Less than 3 characters → prompt for more
- Same intention 3 days in a row → gentle nudge
- Single word like "ok" or "." → prompt for more

---

## The Reopen Loop

This is the most important architectural decision:

```
Stage 2 triggers at 2:14pm
        ↓
User force closes Kora
        ↓
User reopens flagged app
        ↓
Accessibility Service catches foreground event
        ↓
RisingTideService checks:
Is stage2_locked_package == this app?
Is current time < stage2_locked_until?
        ↓
YES → Stage 2 appears again
        ↓
Loop continues until:
- User completes the flow (mood + decision)
- OR 5 minute lock expires
```

---

## All Entry Points Covered

| Entry Point | How Covered |
|---|---|
| App drawer tap | InterceptionScreen already handles |
| Home screen shortcut | InterceptionScreen already handles |
| Notification tap | Accessibility Service intercepts |
| Recent apps | Accessibility Service intercepts |
| Google Assistant | Accessibility Service intercepts |
| Browser shortcut | Accessibility Service intercepts |
| Third party launcher | Cannot cover — acceptable gap |
| Uninstalling Kora | Cannot cover — acceptable gap |

The two gaps are acceptable because the philosophy is not a prison. If someone uninstalls — they made a conscious choice. That's fine.

---

## Complete Database Events

Every single moment logged:

| Event | When |
|---|---|
| `intention_set` | Morning intention written |
| `intention_skipped` | Skip button pressed |
| `intention_fake` | Short/repeated intention detected |
| `app_open_stage1` | App opened freely |
| `app_open_stage2` | Stage 2 triggered |
| `app_open_stage3` | Stage 3 triggered |
| `app_open_stage4` | Stage 4 block shown |
| `mood_selected` | Mood chosen in Stage 2 |
| `decision_continue` | Chose to continue |
| `decision_goback` | Chose to go back |
| `stage2_reopen_blocked` | Reopened during lock |
| `stage4_task_unlock` | Used task to unlock |
| `stage4_unlock_expired` | 5 min unlock used up |
| `midnight_reset` | Daily reset triggered |

---

## The 30-Day Insight This Creates

After 30 days of this data:

```
"You opened Instagram 203 times this month"
"127 times you said 'just habit' at Stage 2"
"Your best week: intention set every day"
"Most dangerous time: 2pm-4pm daily"
"Stage 4 hit 8 times — always on Sundays"
"Days with intention = 43% less screen time"
```

This is the data that makes Kora genuinely different from every screen time app. Not rules. Not blocks. **Self-knowledge.**

---

## Service Names for Code Generation

Give these exact names to your AI:

- `RisingTideService` — stage calculation, lock management
- `RisingTideStage` — enum: whisper, dim, mirror, silence
- `RisingTideLogger` — all database event logging
- `IntentionGateService` — morning intention check and fake detection
- `AppLockManager` — Stage 2 reopen lock, Stage 4 block, unlock logic
- `AccessibilityWatcherService` — Android service catching all foreground events
- `MidnightResetService` — daily reset of all stages and counts
- `InsightEngine` — 30-day pattern analysis (Month 2)

---

## Build Order

**Week 1:** `RisingTideService` + `RisingTideLogger` + wire into existing InterceptionScreen

**Week 2:** Stage 2 screen complete — blur, mood, countdown, lock

**Week 3:** Stage 3 screen + `AppLockManager` + reopen loop

**Week 4:** Stage 4 screen + task unlock + `AccessibilityWatcherService`

**Month 2:** `IntentionGateService` fake detection + `MidnightResetService`

**Month 3:** `InsightEngine` + 30-day analytics screen

---

This is your complete Rising Tide architecture. Every escape route covered. Every event logged. Every stage purposeful. 🌊