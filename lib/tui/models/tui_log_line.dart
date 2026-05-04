enum LogLevel { info, warn, error, system }

/// A single line of output in the running screen log.
class TuiLogLine {
  final String text;
  final LogLevel level;

  const TuiLogLine(this.text, {this.level = LogLevel.info});

  factory TuiLogLine.warn(String text) => TuiLogLine(text, level: LogLevel.warn);
  factory TuiLogLine.error(String text) => TuiLogLine(text, level: LogLevel.error);
  factory TuiLogLine.system(String text) => TuiLogLine(text, level: LogLevel.system);
}
