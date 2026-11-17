import 'package:enfr/models/subtitle_cue.dart';

/// How far into a cue "previous" restarts that cue instead of going back one.
const restartThreshold = Duration(seconds: 1);

/// Index of the last cue that has started at [position], or null before the
/// first cue. [cues] must be sorted by start time.
int? activeIndex(List<SubtitleCue> cues, Duration position) {
  var lo = 0, hi = cues.length - 1;
  int? result;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    if (cues[mid].start <= position) {
      result = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return result;
}

/// Whether [position] falls within [cue]'s time range.
bool isInside(SubtitleCue cue, Duration position) =>
    position >= cue.start && position < cue.end;

/// Where "previous sentence" should seek: the start of the current cue if
/// we're more than [restartThreshold] into it, otherwise the previous cue.
Duration? previousTarget(List<SubtitleCue> cues, Duration position) {
  if (cues.isEmpty) return null;
  final i = activeIndex(cues, position);
  if (i == null) return cues.first.start;
  if (position - cues[i].start > restartThreshold || i == 0) {
    return cues[i].start;
  }
  return cues[i - 1].start;
}

/// Where "next sentence" should seek, or null if already on the last cue.
Duration? nextTarget(List<SubtitleCue> cues, Duration position) {
  if (cues.isEmpty) return null;
  final i = activeIndex(cues, position);
  final next = i == null ? 0 : i + 1;
  return next < cues.length ? cues[next].start : null;
}
