import 'dart:math';

import '../models/rising_tide_stage.dart';
import 'ai_context_builder.dart';

/// Handcrafted message engine — the fallback when on-device AI is unavailable.
///
/// Contains 50+ templates organized by stage, time of day, and user context.
/// Each message uses `{variable}` placeholders that are dynamically replaced
/// with real user data, making them feel personal despite being pre-written.
///
/// This file is self-contained and provider-agnostic — it can be extracted
/// into any project that has an [AIContext] object.
class TemplateMessageEngine {
  static final Random _rng = Random();

  /// Select and populate a message template for the given context.
  static String generate(AIContext ctx) {
    final templates = _getTemplatesForContext(ctx);
    if (templates.isEmpty) return _defaultMessage(ctx);

    final template = templates[_rng.nextInt(templates.length)];
    return _interpolate(template, ctx);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Template Selection Logic
  // ─────────────────────────────────────────────────────────────────────────

  static List<String> _getTemplatesForContext(AIContext ctx) {
    final List<String> pool = [];

    switch (ctx.stage) {
      case RisingTideStage.dim:
        pool.addAll(_dimGeneral);
        if (ctx.hasIntention) pool.addAll(_dimWithIntention);
        if (ctx.hasPendingTodos) pool.addAll(_dimWithTodos);
        if (ctx.isPeakHour) pool.addAll(_dimPeakHour);
        pool.addAll(_dimByTimeOfDay(ctx.timeOfDay));
        if (ctx.opensToday >= 3) pool.addAll(_dimFrequentOpener);
        break;

      case RisingTideStage.mirror:
        pool.addAll(_mirrorGeneral);
        if (ctx.hasIntention) pool.addAll(_mirrorWithIntention);
        if (ctx.hasPendingTodos) pool.addAll(_mirrorWithTodos);
        if (ctx.isPeakHour) pool.addAll(_mirrorPeakHour);
        pool.addAll(_mirrorByTimeOfDay(ctx.timeOfDay));
        if (ctx.weeklyResistRate > 0.5) pool.addAll(_mirrorHighResist);
        if (ctx.weeklyResistRate < 0.2) pool.addAll(_mirrorLowResist);
        break;

      default:
        break;
    }

    return pool;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIM STAGE TEMPLATES (50% – 99% of limit)
  // ─────────────────────────────────────────────────────────────────────────

  static const _dimGeneral = [
    "You've spent {minutes} minutes in {app} today. You have {remaining} left of your {limit}-minute limit.",
    "{app} has had {opens} of your attention today. {remaining} minutes remain on your budget.",
    "Halfway point. {minutes} minutes in {app} — {remaining} left before the limit.",
    "Quick check: {minutes} minutes in {app} so far. How much more do you need?",
    "{opens} opens today, {minutes} minutes total. Just making sure this one is intentional.",
    "You're at {percent} of your {app} limit. {remaining} minutes left.",
  ];

  static const _dimWithIntention = [
    "Your focus today: \"{intention}\". You've used {minutes} min of {app} — does this help?",
    "You wrote \"{intention}\" this morning. {remaining} minutes of {app} left today.",
    "\"{intention}\" — that was your intention. {app} is at {minutes} min. Still aligned?",
    "Today's goal is \"{intention}\". You've opened {app} {opens} times. Quick one?",
  ];

  static const _dimWithTodos = [
    "\"{todo}\" is still on your list. You've been in {app} {minutes} minutes — worth continuing?",
    "You have {todoCount} tasks pending. {app} has taken {minutes} minutes so far.",
    "Before you go in: \"{todo}\" is waiting. {remaining} min of {app} left today.",
    "Your todo list has {todoCount} items. {app} is at {percent} of your limit.",
  ];

  static const _dimPeakHour = [
    "This is usually your heaviest {app} hour. You're at {minutes} min already.",
    "Heads up — historically, this is when {app} pulls you in most. {minutes} min so far.",
    "Your peak {app} time is around now. You've used {minutes} of {limit} minutes.",
  ];

  static const _dimFrequentOpener = [
    "This is open #{opens} for {app} today. Each one adds up.",
    "{opens} times today you've reached for {app}. {minutes} minutes total.",
    "You've opened {app} {opens} times today. Habit or need?",
  ];

  static List<String> _dimByTimeOfDay(TimeOfDay tod) {
    switch (tod) {
      case TimeOfDay.morning:
        return const [
          "Morning {app} check — {minutes} min so far. The day is still fresh.",
          "It's {time}. {minutes} minutes into {app} already today.",
        ];
      case TimeOfDay.afternoon:
        return const [
          "Afternoon — {minutes} min of {app} used. {remaining} left before your limit.",
          "It's past noon. {app} has had {minutes} minutes of your afternoon.",
        ];
      case TimeOfDay.evening:
        return const [
          "Evening wind-down? {minutes} min in {app} today, {remaining} left.",
          "It's {time}. {app} is at {percent} of your daily limit.",
        ];
      case TimeOfDay.lateNight:
        return const [
          "Late night {app}? You're at {minutes} minutes. These sessions often run long.",
          "It's {time}. Late-night scrolling tends to stretch. {remaining} min left.",
        ];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MIRROR STAGE TEMPLATES (100%+ of limit or 2+ overrides)
  // ─────────────────────────────────────────────────────────────────────────

  static const _mirrorGeneral = [
    "Limit reached. {minutes} minutes in {app} with a {limit}-minute budget.",
    "{app} — {minutes} min today vs your {limit}-min limit. You're past the line.",
    "You've used your full {app} budget. {opens} opens, {minutes} minutes.",
    "Your {app} limit is up. This is the moment you asked Kora to catch.",
    "{minutes} minutes. {opens} opens. The {app} budget is done for today.",
    "Limit hit. {app} has had {minutes} of your {limit} minutes today.",
  ];

  static const _mirrorWithIntention = [
    "You said today was about \"{intention}\". {app} used {minutes} min — limit done.",
    "\"{intention}\" — your words this morning. {app} is past its limit now.",
    "Your intention: \"{intention}\". Time spent in {app}: {minutes} min (limit: {limit}). Is this the trade-off?",
    "\"{intention}\" vs {minutes} min of {app}. The limit is reached. Your call.",
  ];

  static const _mirrorWithTodos = [
    "\"{todo}\" is still undone. {app} took {minutes} minutes of your day.",
    "You have {todoCount} tasks waiting. {app} has used its full {limit}-min limit.",
    "\"{todo}\" vs {app}. {minutes} minutes spent, {todoCount} tasks pending.",
    "Your list has {todoCount} things. {app} has had {minutes} minutes. What gets your next hour?",
  ];

  static const _mirrorPeakHour = [
    "This is your peak {app} hour — and the limit is already hit.",
    "Historically, this is when {app} keeps you longest. The limit kicked in.",
  ];

  static const _mirrorHighResist = [
    "You've been strong this week — {resistRate} resist rate. Another one?",
    "You chose 'go back' often this week. This is that same choice again.",
    "Your self-awareness has been high this week. Keep the streak?",
  ];

  static const _mirrorLowResist = [
    "Most times this week, you tapped continue. This is another chance to choose differently.",
    "You've been opening past the limit often this week. No judgement — just a fact.",
  ];

  static List<String> _mirrorByTimeOfDay(TimeOfDay tod) {
    switch (tod) {
      case TimeOfDay.morning:
        return const [
          "Morning and already past the {app} limit. Long day ahead.",
          "It's only {time}. The {app} limit is already done.",
        ];
      case TimeOfDay.afternoon:
        return const [
          "Afternoon — {app} limit reached. What else could this time be?",
          "It's {time}. {app} is past the line. The afternoon is still yours.",
        ];
      case TimeOfDay.evening:
        return const [
          "Evening — {app} limit reached. Tomorrow resets everything.",
          "The day is winding down and {app} has used its budget. Your call.",
        ];
      case TimeOfDay.lateNight:
        return const [
          "Late night, limit reached. You know how this usually ends.",
          "It's {time}. {app} past the limit. Sleep might be better.",
        ];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Interpolation
  // ─────────────────────────────────────────────────────────────────────────

  static String _interpolate(String template, AIContext ctx) {
    return template
        .replaceAll('{app}', ctx.appName)
        .replaceAll('{minutes}', ctx.minutesToday.toString())
        .replaceAll('{limit}', ctx.limitMinutes.toString())
        .replaceAll('{remaining}', ctx.remainingMinutes.toString())
        .replaceAll('{opens}', ctx.opensToday.toString())
        .replaceAll('{percent}', '${(ctx.usagePercent * 100).round()}%')
        .replaceAll('{intention}', ctx.dailyIntention ?? '')
        .replaceAll('{todo}', ctx.topPendingTodo ?? '')
        .replaceAll('{todoCount}', ctx.pendingTodoCount.toString())
        .replaceAll('{completedCount}', ctx.completedTodoCount.toString())
        .replaceAll('{resistRate}', '${(ctx.weeklyResistRate * 100).round()}%')
        .replaceAll('{time}', ctx.formattedTime);
  }

  static String _defaultMessage(AIContext ctx) {
    if (ctx.stage == RisingTideStage.mirror) {
      return "Limit reached for ${ctx.appName}. ${ctx.minutesToday} minutes today.";
    }
    return "You've used ${ctx.appName} for ${ctx.minutesToday} minutes today.";
  }
}
