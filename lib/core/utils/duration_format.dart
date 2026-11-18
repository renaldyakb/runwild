/// Formats a duration as a clock value for metric displays.
///
/// Below one hour uses `minutes:seconds` (example `42:07`); one hour or more
/// uses `hours:minutes:seconds` (example `1:02:07`). Negative values are
/// treated as zero so a broken sample never renders a negative clock.
String formatClockDuration(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final totalSeconds = safe.inSeconds;
  final hours = totalSeconds ~/ Duration.secondsPerHour;
  final minutes = (totalSeconds ~/ Duration.secondsPerMinute) % 60;
  final seconds = totalSeconds % 60;
  final paddedSeconds = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$paddedSeconds';
  }
  return '${minutes.toString().padLeft(2, '0')}:$paddedSeconds';
}
