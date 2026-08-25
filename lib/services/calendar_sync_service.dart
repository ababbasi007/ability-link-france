import 'package:add_2_calendar/add_2_calendar.dart';

import '../models/care_appointment.dart';

/// Exports care appointments to the device calendar.
class CalendarSyncService {
  CalendarSyncService._();
  static final CalendarSyncService instance = CalendarSyncService._();

  Future<bool> addAppointment(CareAppointment a) {
    final end = a.startAt.add(Duration(minutes: a.durationMin));
    final event = Event(
      title: '${a.kindLabel}: ${a.providerName}',
      description: [
        a.specialty,
        a.modeLabel,
        if (a.notes.isNotEmpty) a.notes,
        if (a.summary.isNotEmpty) a.summary,
        if (a.joinCode.isNotEmpty) 'Join code: ${a.joinCode}',
      ].where((s) => s.trim().isNotEmpty).join('\n'),
      location: a.isRemote ? 'Online · Ability Link' : a.modeLabel,
      startDate: a.startAt,
      endDate: end,
      allDay: false,
    );
    return Add2Calendar.addEvent2Cal(event);
  }
}
