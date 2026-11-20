/// Salam beranda mengikuti jam lokal pengguna (DESIGN.md bagian copy).
enum DayGreeting { morning, afternoon, evening, night }

/// Batas jam salam: pagi sampai 10.59, siang sampai 14.59, sore sampai 18.59,
/// selebihnya malam.
const _afternoonStartHour = 11;
const _eveningStartHour = 15;
const _nightStartHour = 19;

/// Memilih salam dari jam lokal (0-23).
DayGreeting dayGreetingFor(int hour) {
  if (hour < _afternoonStartHour) return DayGreeting.morning;
  if (hour < _eveningStartHour) return DayGreeting.afternoon;
  if (hour < _nightStartHour) return DayGreeting.evening;
  return DayGreeting.night;
}

/// Nama depan pengguna untuk sapaan; nama kosong jatuh ke seluruh teks.
String firstNameOf(String displayName) {
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) return displayName;
  final parts = trimmed.split(RegExp(r'\s+'));
  return parts.first;
}
