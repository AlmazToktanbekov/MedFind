/// Утилиты для разбора строки графика работы аптеки.
///
/// Формат строки: `"Пн 09:00-21:00, Вт 09:00-21:00, ..."` либо `"Круглосуточно"`.
library;

const _ruDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

/// Открыт ли филиал прямо сейчас.
/// `true` — открыт, `false` — закрыт, `null` — график неизвестен / не разобран.
bool? isPharmacyOpenNow(String? workingHours, {DateTime? now}) {
  final raw = workingHours?.trim();
  if (raw == null || raw.isEmpty) return null;
  if (raw == 'Круглосуточно') return true;

  final dt = now ?? DateTime.now();
  final today = _ruDays[dt.weekday - 1];

  for (final part in raw.split(',')) {
    final s = part.trim();
    if (!s.startsWith(today)) continue;
    final hours = s.substring(today.length).trim();
    final m = RegExp(r'(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})').firstMatch(hours);
    if (m == null) return null;
    final openMin = int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
    var closeMin = int.parse(m.group(3)!) * 60 + int.parse(m.group(4)!);
    if (closeMin <= openMin) closeMin += 24 * 60; // переход через полночь
    final nowMin = dt.hour * 60 + dt.minute;
    return nowMin >= openMin && nowMin < closeMin;
  }
  // Сегодняшнего дня нет в графике → считаем закрытым.
  return false;
}

/// Открыта ли хотя бы одна из строк-графиков прямо сейчас.
/// `null`, если ни у одного филиала нет понятного графика.
bool? isAnyOpenNow(Iterable<String?> workingHoursList) {
  var sawSchedule = false;
  for (final wh in workingHoursList) {
    final open = isPharmacyOpenNow(wh);
    if (open == null) continue;
    sawSchedule = true;
    if (open) return true;
  }
  return sawSchedule ? false : null;
}
