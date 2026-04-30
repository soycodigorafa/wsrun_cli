/// Renders a status/hint bar as a single line of key→action pairs.
class StatusBar {
  /// Renders [hints] as a space-separated string of `key action` pairs.
  /// Example: `[('r', 'reload'), ('Q', 'quit')]` → `r reload   Q quit`
  static String render(List<(String key, String action)> hints) {
    return hints.map((h) => '\x1B[1m${h.$1}\x1B[0m ${h.$2}').join('   ');
  }
}
