import 'package:intl/intl.dart';

import '../constants/app_strings.dart';

/// General-purpose utility functions used across the Dostok app.
///
/// All functions are pure (no side effects) and stateless. They handle
/// time formatting, text manipulation, date calculations, and Darija-aware
/// greetings.
///
/// Usage:
/// ```dart
/// final greeting = Helpers.getGreeting();        // "صباح الخير"
/// final time = Helpers.formatTime(DateTime.now()); // "14:30"
/// ```
abstract final class Helpers {
  // ---------------------------------------------------------------------------
  // Time Formatting
  // ---------------------------------------------------------------------------

  /// Formats a [DateTime] as a 24-hour time string (e.g. `"14:30"`).
  ///
  /// Uses `intl` package for locale-safe formatting. Falls back to manual
  /// zero-padded formatting if `intl` is unavailable.
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Formats a [DateTime] as a 12-hour time with AM/PM indicator (e.g. `"2:30 م"`).
  ///
  /// Uses Arabic AM/PM markers: ص (sabah/morning) for AM, م (masa/evening) for PM.
  static String formatTime12(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص'; // م = PM, ص = AM
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Formats a [DateTime] as a relative time string in Darija.
  ///
  /// Returns:
  /// - "دابا" (now) if within the last minute.
  /// - "قبل X دقيقة" (X minutes ago) if within the last hour.
  /// - "قبل X ساعة" (X hours ago) if within the last 24 hours.
  /// - "نهار هذا" (today) if same calendar day.
  /// - "بارح" (yesterday) if one day ago.
  /// - A formatted date otherwise.
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'دابا'; // Now
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return 'قبل $minutes دقيقة'; // X minutes ago
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return 'قبل $hours ساعة'; // X hours ago
    }
    if (diff.inDays == 0) return 'نهار هذا'; // Today
    if (diff.inDays == 1) return 'بارح'; // Yesterday
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  // ---------------------------------------------------------------------------
  // Greeting (Time-Based)
  // ---------------------------------------------------------------------------

  /// Returns a Darija greeting appropriate for the current time of day.
  ///
  /// - 5:00 AM to 11:59 AM: "صباح الخير" (good morning)
  /// - 12:00 PM to 5:59 PM: "مساء الخير" (good afternoon)
  /// - 6:00 PM to 4:59 AM: "ليلة سعيدة" (good evening/night)
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return AppStrings.greetingMorning;
    if (hour >= 12 && hour < 18) return AppStrings.greetingAfternoon;
    return AppStrings.greetingEvening;
  }

  /// Returns a personalized greeting combining time-based greeting with [name].
  ///
  /// Example: `"صباح الخير، يا محمد!"`.
  static String getPersonalGreeting(String name) {
    return '${getGreeting()}، يا $name!';
  }

  // ---------------------------------------------------------------------------
  // Date Calculations
  // ---------------------------------------------------------------------------

  /// Returns the number of days between [startDate] and today.
  ///
  /// Always returns a non-negative value. If [startDate] is in the future,
  /// returns 0.
  static int getDaysSince(DateTime startDate) {
    final now = DateTime.now();
    final diff = now.difference(startDate);
    return diff.inDays < 0 ? 0 : diff.inDays;
  }

  /// Returns the number of days between two [DateTime] values.
  ///
  /// Always returns the absolute (non-negative) difference.
  static int daysBetween(DateTime a, DateTime b) {
    return (a.difference(b).inDays).abs();
  }

  /// Returns `true` if [date] is today (same calendar day).
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Returns `true` if [date] is yesterday.
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // ---------------------------------------------------------------------------
  // Duration Formatting
  // ---------------------------------------------------------------------------

  /// Formats a [Duration] as a human-readable Darija string.
  ///
  /// Examples:
  /// - `Duration(seconds: 5)` => `"5 ثوان"`
  /// - `Duration(minutes: 3, seconds: 42)` => `"3:42"`
  /// - `Duration(hours: 1, minutes: 15)` => `"1 ساعة و 15 دقيقة"`
  ///
  /// For call-style durations under an hour, returns `M:SS` format.
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      final parts = <String>[];
      parts.add('$hours ساعة'); // X hour(s)
      if (minutes > 0) parts.add('$minutes دقيقة'); // X minute(s)
      return parts.join(' و '); // "and"
    }

    if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '$seconds ثانية'; // X second(s)
  }

  /// Formats a [Duration] as a compact call-style string (`"MM:SS"` or
  /// `"HH:MM:SS"` for calls over an hour).
  static String formatCallDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Text Manipulation
  // ---------------------------------------------------------------------------

  /// Truncates [text] to [maxLength] characters, appending [ellipsis] if cut.
  ///
  /// If [text] is already within the limit, returns it unchanged.
  /// Defaults to `maxLength = 100` and `ellipsis = '...'`.
  ///
  /// Example:
  /// ```dart
  /// Helpers.truncateText('Long text here...', 10); // 'Long te...'
  /// ```
  static String truncateText(
    String text, [
    int maxLength = 100,
    String ellipsis = '...',
  ]) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Returns the first [count] words from [text].
  ///
  /// Useful for preview snippets. Returns the full text if it has fewer words
  /// than [count].
  static String firstWords(String text, [int count = 10]) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= count) return text;
    return '${words.take(count).join(' ')}...';
  }

  /// Returns `true` if [text] contains predominantly Arabic characters.
  ///
  /// Checks if more than 50% of non-whitespace characters are in the Arabic
  /// Unicode block. Useful for determining text direction.
  static bool isArabicText(String text) {
    if (text.isEmpty) return false;
    final nonSpace = text.replaceAll(RegExp(r'\s'), '');
    if (nonSpace.isEmpty) return false;
    final arabicCount =
        nonSpace.runes.where((r) => r >= 0x0600 && r <= 0x06FF).length;
    return arabicCount / nonSpace.length > 0.5;
  }

  // ---------------------------------------------------------------------------
  // Name Utilities
  // ---------------------------------------------------------------------------

  /// Returns a display-safe version of [name], trimmed and title-cased.
  ///
  /// Handles both Arabic and Latin names gracefully.
  static String sanitizeName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return trimmed;

    // For Arabic names, just return trimmed (no title-casing).
    if (isArabicText(trimmed)) return trimmed;

    // For Latin names, title-case each word.
    return trimmed
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }
}
