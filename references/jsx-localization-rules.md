# Illustrator JSX Localization Rules

## 1. Preflight before mutation

Build the complete source mapping first. Find frames by artboard + normalized exact source content where possible. Use token fallback only if exact matching is impossible. If a required target is missing, abort before modifying the document.

```jsx
function norm(s) {
    return String(s || "")
        .replace(/\r\n/g, "\n")
        .replace(/\r/g, "\n")
        .replace(/[\t ]+/g, " ")
        .replace(/^\s+|\s+$/g, "")
        .toLowerCase();
}
```

For duplicate strings, disambiguate by artboard and geometry.

## 2. Snapshot appearance before changing text

Color must be inherited from the source runtime object, not reconstructed from a screenshot.

```jsx
function appearanceFromChar(tf, idx) {
    if (!tf || tf.characters.length === 0) throw new Error("Empty source TextFrame");
    idx = Math.max(0, Math.min(idx || 0, tf.characters.length - 1));
    var ca = tf.characters[idx].characterAttributes;
    return {
        fillColor: ca.fillColor,
        strokeColor: ca.strokeColor,
        strokeWeight: ca.strokeWeight,
        overprintFill: ca.overprintFill,
        overprintStroke: ca.overprintStroke,
        textFont: ca.textFont,
        size: ca.size,
        leading: ca.leading,
        tracking: ca.tracking,
        horizontalScale: ca.horizontalScale,
        verticalScale: ca.verticalScale
    };
}

function applyAppearance(dstChar, srcStyle, copyFont) {
    var ca = dstChar.characterAttributes;
    try { ca.fillColor = srcStyle.fillColor; } catch (e1) {}
    try { ca.strokeColor = srcStyle.strokeColor; } catch (e2) {}
    try { ca.strokeWeight = srcStyle.strokeWeight; } catch (e3) {}
    try { ca.overprintFill = srcStyle.overprintFill; } catch (e4) {}
    try { ca.overprintStroke = srcStyle.overprintStroke; } catch (e5) {}
    if (copyFont) {
        try { ca.textFont = srcStyle.textFont; } catch (e6) {}
    }
}
```

Direct assignment is deliberate: in the same Illustrator document it preserves the source color resource, including Spot/Gradient/Pattern references better than guessed RGB/CMYK reconstruction.

Do not delete the source frame before target styling is complete.

## 3. One-style frame

For a translated frame that should keep one source color:

1. Capture source style.
2. Replace/create target content.
3. Apply the target-language font.
4. Apply the captured source fill/stroke appearance to the entire target range.
5. Reapply source brand font only to unchanged Latin terms.

## 4. Multi-color phrase

Never preserve multi-color phrases by hard-coded hex values.

Represent the target as semantic runs:

```js
[
  { text: "如何", styleFrom: "HERO_WHITE" },
  { text: "开始", styleFrom: "HERO_BLUE" }
]
```

Capture `HERO_WHITE` from the original white source frame/range and `HERO_BLUE` from the original blue source frame/range at runtime.

After setting target text, apply each style run by exact target character index:

```jsx
function applyStyleRange(tf, start, len, srcStyle) {
    var end = Math.min(tf.characters.length, start + len);
    for (var i = start; i < end; i++) {
        applyAppearance(tf.characters[i], srcStyle, false);
    }
}
```

Count JavaScript characters carefully. For surrogate-pair-heavy text, prefer run concatenation logic and validate lengths; CJK BMP text is normally safe.

## 5. Keep color and font concerns separate

Target CJK text generally needs a CJK font, but still inherits original source colors.

Example sequence:

1. `tf.contents = targetText`
2. set base CJK font/weight/size/leading/tracking
3. apply source color appearance to entire target
4. apply source color run mappings
5. restore source Avenir/brand font to `AIZENO`, `ZENO MARKET`, URL, hashtags, etc.

Do not let font restoration overwrite the inherited color.

## 6. Geometry and safe fitting

### Source-locked
Preserve source top/left or center/top anchor. Fit conservatively:
- tracking adjustment first;
- then small font-size/leading reduction;
- do not go below roughly 92% of intended size unless user explicitly approves;
- if still overflowing, warn instead of crushing the layout.

### Reference-aware
If a translated Golden Reference is supplied:
- use the reference to set target-language text geometry;
- use the source `.ai` for graphics and exact style/color tokens;
- do not sample color from the reference image when original Illustrator styles exist.

## 7. Non-destructive Save As

Before mutating content, create a new output copy:

```jsx
var out = new File(folder.fsName + "/" + stem + "_CN.ai");
var opt = new IllustratorSaveOptions();
opt.pdfCompatible = true;
opt.compressed = true;
doc.saveAs(out, opt);
```

If the output exists, append `_v2`, `_v3`, etc. Never overwrite the original source.

## 8. Locked/hidden parents

Temporarily unlock/unhide parent objects only when needed and restore state afterward.

```jsx
function ensureEditable(item) {
    var states = [], o = item;
    while (o && o.typename !== "Document") {
        try {
            states.push({o:o, locked:o.locked, hidden:o.hidden});
            o.locked = false;
            o.hidden = false;
        } catch (e) {}
        o = o.parent;
    }
    return states;
}
function restoreStates(states) {
    for (var i = states.length - 1; i >= 0; i--) {
        try { states[i].o.locked = states[i].locked; } catch (e1) {}
        try { states[i].o.hidden = states[i].hidden; } catch (e2) {}
    }
}
```

## 9. Do not guess colors

Forbidden unless the user explicitly requests a new color:

```jsx
// BAD for localization
var blue = new RGBColor();
blue.red = 110;
blue.green = 170;
blue.blue = 230;
```

Use the original source style instead.

## 10. Required completion check

Before delivering a generated JSX, verify:
- all source text targets mapped;
- all target strings final;
- all multi-color runs mapped to source style tokens;
- no replacement palette guessed;
- output Save As is non-destructive;
- no TODO/PLACEHOLDER text remains.
