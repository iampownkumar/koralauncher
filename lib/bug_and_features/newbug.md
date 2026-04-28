bug 1: [FIXED] when we freshly installed the app when i set the inentions in the first that popups it is not adding in the todo list task but 
        when i edit the same intention top bar and add some text it is adding perfectly.
        (Fix: Added missing TodoService sync to the onboarding flow.)
bug 2: [FIXED] when i add the app in the rising tide system the default is 10 mints; but when i try to edit that to 1 hour or something else it is changed. but the rising tide system is still questiong because it is not updated properply so this way i constatntly uninstalled my own app and never used it. The timing and others are updating but the questiong sstem is not updating
        (Fix: Added AICacheService.invalidate(packageName) call after saving the limit — in both GateSettingsSheet (interception screen) and DailyLimitSheet (TidePool screen). The cached AI question for the old stage was persisting. Now it's cleared on every limit change so the next interception generates a fresh message.)

bug 3: so now lets come with the real question asking system. even thoug i completed the todo list taks it is still aaksing in the interuptin gwhen i try to open the flagged app. and the questiong is really not good at all . 

bug 4: we have to rething and design the risign tide system and we need to change the positions of our entire ap where goes where 

bug 5: [FIXED] if i marked the todo list as completed the whole text is complete not vissible becuast that like is hding verhign may be we should find some way to fix it .
        (Fix: Raised completed text color from white38 → white60, card background from 2% → 5% opacity, border from 5% → 8% opacity. Also added explicit decorationColor: white38 so the strikethrough line is subtly dimmer than the text, keeping the hierarchy clear.)