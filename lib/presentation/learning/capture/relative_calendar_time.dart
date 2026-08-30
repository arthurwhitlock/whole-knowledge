import 'package:flutter/material.dart';

final class RelativeCalendarCopy {
  const RelativeCalendarCopy({required this.visual, required this.semantic});

  final String visual;
  final String semantic;
}

abstract final class RelativeCalendarTime {
  static RelativeCalendarCopy format(
    DateTime instant,
    DateTime now,
    MaterialLocalizations localizations,
  ) {
    final localInstant = instant.toLocal();
    final localNow = now.toLocal();
    final targetDay = DateTime(
      localInstant.year,
      localInstant.month,
      localInstant.day,
    );
    final currentDay = DateTime(localNow.year, localNow.month, localNow.day);
    final dayDelta = targetDay.difference(currentDay).inDays;
    final date = switch (dayDelta) {
      0 when localInstant.isAfter(localNow) => 'later today',
      0 => 'today',
      1 => 'tomorrow',
      -1 => 'yesterday',
      _ => localizations.formatShortDate(localInstant),
    };
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localInstant),
    );
    final fullDate = localizations.formatFullDate(localInstant);
    final zone = localInstant.timeZoneName;
    return RelativeCalendarCopy(
      visual: '$date at $time',
      semantic: '$fullDate at $time${zone.isEmpty ? '' : ', $zone'}',
    );
  }
}
