import 'package:flutter/material.dart' show TimeOfDay;

/// وردية عمل (فتح/إغلاق) داخل يوم.
class DayShift {
  DayShift({required this.open, required this.close});

  TimeOfDay open;
  TimeOfDay close;

  DayShift copy() => DayShift(open: open, close: close);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'open': formatTime(open),
        'close': formatTime(close),
      };
}

/// أسماء الأيام بالعربية (1 = الاثنين … 7 = الأحد).
const Map<int, String> kDayNames = <int, String>{
  1: 'الإثنين',
  2: 'الثلاثاء',
  3: 'الأربعاء',
  4: 'الخميس',
  5: 'الجمعة',
  6: 'السبت',
  7: 'الأحد',
};

/// ترتيب عرض الأسبوع بدءاً من السبت.
const List<int> kWeekOrder = <int>[6, 7, 1, 2, 3, 4, 5];

/// تنسيق الوقت إلى `HH:MM` (24 ساعة).
String formatTime(TimeOfDay t) {
  final String h = t.hour.toString().padLeft(2, '0');
  final String m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// تحويل نص قاعدة البيانات (`HH:MM:SS`) إلى `TimeOfDay`.
TimeOfDay parseTime(String raw) {
  final List<String> parts = raw.split(':');
  final int h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final int m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return TimeOfDay(hour: h, minute: m);
}
