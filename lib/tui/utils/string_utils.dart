/// Removes emoji characters from [text] and collapses any resulting extra
/// whitespace, returning a trimmed string.
///
/// This is a temporary workaround for terminals that cannot render Unicode
/// emoji without corrupting the layout.
String stripEmojis(String text) {
  return text
      .replaceAll(
        RegExp(
          r'[\u{1F000}-\u{1FFFF}]|' // Enclosed CJK, Mahjong, Domino, Playing Cards,
          //   Enclosed Alphanumeric Supplement, Emoticons,
          //   Misc Symbols and Pictographs, Transport & Map,
          //   Alchemical Symbols, Geometric Shapes Extended,
          //   Supplemental Arrows-C, Supplemental Symbols &
          //   Pictographs, Chess Symbols, Symbols & Pictographs
          //   Extended-A, Symbols for Legacy Computing …
          r'[\u{2600}-\u{27BF}]|' // Misc Symbols, Dingbats
          r'[\u{FE00}-\u{FE0F}]|' // Variation Selectors
          r'[\u{200D}]', // Zero-Width Joiner (used in multi-codepoint emoji)
          unicode: true,
        ),
        '',
      )
      .replaceAll(RegExp(r' {2,}'), ' ')
      .trim();
}
