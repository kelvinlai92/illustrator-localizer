# Target-language font fallback guidance

Use the source font for unchanged brand/Latin runs when it supports the required glyphs. Use a language-appropriate installed font for translated text.

- zh-CN: Source Han Sans SC, Noto Sans CJK SC, PingFang SC, Microsoft YaHei
- zh-TW: Source Han Sans TC, Noto Sans CJK TC, PingFang TC, Microsoft JhengHei
- ja: Source Han Sans JP, Noto Sans CJK JP, Hiragino Sans, Yu Gothic
- ko: Source Han Sans KR, Noto Sans CJK KR, Apple SD Gothic Neo, Malgun Gothic
- vi: preserve source Latin family if Vietnamese glyph coverage is complete; otherwise Noto Sans or another full Vietnamese-capable family

Match visual weight rather than font style-name literally: display -> Heavy/Black; section title -> Bold/Semibold; body -> Regular/Book; footer -> Light/Regular.
