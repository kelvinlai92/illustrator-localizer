---
name: illustrator-localizer
description: Generate Adobe Illustrator ExtendScript (.jsx) localization scripts from user-provided .ai source files. Use when the user uploads an Illustrator source and asks to translate/localize it to Chinese, Korean, Japanese, Vietnamese, English, or another language while preserving the original design, editable Live Text, geometry, brand terms, and especially the exact source text colors. Also use when the user asks for an Illustrator text-replacement/localization JSX, a reusable CN/KR/JP/VN localizer, or says the next source file + target language should directly produce a JSX file.
---

# Illustrator Localizer

Create a runnable Illustrator `.jsx` that localizes the user's source `.ai` without redesigning it.

## Default contract

When the user provides a source `.ai` and a target language:

1. Inspect the source first.
2. Translate visible editable text unless the user supplied approved copy; approved copy is authoritative.
3. Generate a self-contained `.jsx` file for that source and target language.
4. Keep the original `.ai` untouched; the JSX must save a new localized `.ai` copy.
5. Preserve graphics, logo, mockups, icons, QR codes, backgrounds, artboard sizes, and non-text objects.
6. Preserve translated text as Illustrator Live Text.
7. Preserve source colors exactly by inheritance at runtime. Never approximate source colors from screenshots or hard-code replacements when an original styled text object exists.
8. Deliver the `.jsx` file directly. Do not require the user to manually rebuild text mappings.

Only ask a question when a critical ambiguity cannot be resolved from the source or request, such as Chinese Simplified vs Traditional, or two visually identical text objects that cannot be mapped safely. Otherwise proceed.

## Inspect the source

Use `scripts/inspect_ai.sh <source.ai> <output_dir>` through the container when useful. Also inspect supplied screenshots/reference renders visually.

Determine:
- number of artboards/pages where possible;
- source text strings and likely frame groupings;
- which phrases are split across multiple text objects;
- multi-color or mixed-style phrases;
- original geometry and hierarchy;
- brand terms, URLs, hashtags, product names, and numbers that should remain unchanged.

If the `.ai` is PDF-compatible, prefer its embedded PDF text/geometry for inspection. The generated JSX must still find and manipulate Illustrator `TextFrame` objects at runtime.

## Choose localization mode

### Reference-aware mode
Use this when the user supplies an approved translated image/render or explicitly says to follow a translated visual reference.

- Treat the source `.ai` as the graphics/brand master.
- Treat the approved translated image as the target-language typography/layout Golden Reference.
- Rebuild target Live Text using the reference geometry while preserving source graphics.
- Source colors still come from the original Illustrator text objects, not sampled pixels.

### Source-locked mode
Use this when only the source `.ai` and target language are supplied.

- Preserve each source text area's anchor/geometry and hierarchy.
- Fit translated text conservatively.
- Prefer fixed line breaks chosen for the target language over uncontrolled Illustrator wrapping.
- Allow only small tracking/leading/font-size adjustments. Never aggressively squeeze text just to fit.

## Translation rules

- If the user supplies final/approved translation, use it exactly.
- If only a target language is given, translate visible user-facing text yourself.
- Preserve brand names and technical labels unless translation is clearly requested: examples include `AIZENO`, `ZENO MARKET`, `ZENO SIGNAL`, `ZENO AI`, URLs, hashtags, ticker symbols, and proper product names.
- Preserve numerical values, dates, and URLs unless localization requires formatting changes.
- Use natural target-language line breaks that preserve the original visual hierarchy.

## Exact color inheritance — mandatory

Apply Rule A: all localized text colors must follow the original Illustrator source.

- Never replace a source white/blue/gray/etc. with guessed RGB/CMYK values.
- Snapshot the original source text appearance before changing or clearing any source frame.
- For one-style frames, apply the original fill/stroke appearance to the translated frame.
- For multi-color phrases, create semantic target runs and map each target run to the matching source style run.
  - Example: source `HOW TO` (white) + `GET STARTED` (blue) -> target `如何` inherits `HOW TO`; `开始` inherits `GET STARTED`.
- Preserve Spot/Gradient/Pattern colors by referencing the source Illustrator color/style object at runtime whenever possible.
- Preserve stroke color, overprint state, and opacity when they are used by the source typography.
- Color inheritance and font inheritance are separate. CJK text may need a different font, but its color must remain sourced from the original style.

Read `references/jsx-localization-rules.md` before generating the JSX; it contains the required style-capture and run-mapping pattern.

## Font behavior

- Keep unchanged Latin brand terms in the source brand font when available.
- For CJK translation, choose an installed language-appropriate font at runtime rather than forcing an English font with missing glyphs.
- Preferred fallbacks:
  - zh-CN: Source Han Sans SC -> Noto Sans CJK SC -> PingFang SC -> Microsoft YaHei
  - zh-TW: Source Han Sans TC -> Noto Sans CJK TC -> PingFang TC
  - ja: Source Han Sans JP -> Noto Sans CJK JP -> Hiragino Sans
  - ko: Source Han Sans KR -> Noto Sans CJK KR -> Apple SD Gothic Neo
  - vi and other Latin languages: preserve source font when glyph coverage is adequate; otherwise use Noto Sans/appropriate installed fallback.
- Keep weight relationships: display/heavy, title/bold, body/regular, light/footer.

## JSX safety requirements

Every generated JSX must:

- start with `#target illustrator`;
- require an open document and validate expected artboard count when known;
- locate all intended source text objects before making changes;
- abort with a clear alert if required targets are missing or ambiguous;
- snapshot styles before replacement;
- preserve original source document by `Save As` to a new filename such as `<source>_<LANG>.ai`;
- never silently overwrite the source;
- use UTF-8-compatible literal handling;
- preserve/restore locked and hidden states when temporarily editing items;
- keep non-text artwork unchanged;
- use explicit line breaks in translated content where needed;
- restore mixed Latin brand fonts after setting the target-language base font;
- restore exact inherited source colors after text replacement;
- show completion/warning information to the user inside Illustrator.

## Output naming

Default generated script name:

`<source-stem>_<LANG>_Localizer.jsx`

Examples:
- `AIZENO_Banner_80x200cm_CN_Localizer.jsx`
- `AIZENO_Banner_80x200cm_KR_Localizer.jsx`
- `Poster_JP_Localizer.jsx`

If the user requests a reusable Master + JSON workflow, additionally generate the JSON and replacer scripts, but the default request of source + language should return one self-contained JSX.

## Quality check before delivery

Before returning the file:

- verify no translation placeholder/TODO remains;
- verify every intended source text has a target mapping;
- verify every multi-color source phrase has explicit target run-to-source-style mapping;
- verify no hard-coded replacement color is used when an original source style can be inherited;
- verify source save is non-destructive;
- inspect the JSX around mixed-style and color logic for off-by-one character ranges;
- ensure the file is saved with `.jsx` extension.

Return the generated JSX as a downloadable artifact and briefly state the target language and the non-destructive/color-inheritance behavior.
