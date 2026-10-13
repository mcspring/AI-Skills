# Swift Charts

Use this reference for chart selection, composition, interaction, accessibility, and version-specific APIs.

## Availability

Check deployment targets before using newer chart APIs.

- Swift Charts: iOS 16+ and corresponding platform releases.
- selection/scrolling additions: newer SDK generations; confirm exact availability in the project's SDK.
- `Chart3D`, `SurfacePlot`, Z-axis/camera APIs: iOS 26+ generation.

Do not gate an entire chart when only one optional feature requires a newer OS.

## Start With the Question

Choose marks based on the relationship users need to understand:

| Need | Typical mark |
|---|---|
| compare categories | `BarMark` |
| trend over ordered domain/time | `LineMark` |
| trend with magnitude emphasis | `AreaMark` |
| individual observations | `PointMark` |
| intervals/ranges/heatmap cells | `RectangleMark` |
| thresholds/reference values | `RuleMark` |
| part-to-whole radial data | `SectorMark` |
| continuous 3D surface | `SurfacePlot` / Chart3D APIs |

Avoid choosing a chart by novelty. Start from the analytical task and data scale.

## Data and Identity

Keep the data model stable and explicit.

- use semantic IDs when rows can reorder/update;
- normalize units/domains before rendering;
- keep data transformation outside the chart builder when it is expensive or reused;
- avoid silently mixing incompatible units on one axis.

## Composition

A `Chart` can contain multiple marks. Compose marks when they share a meaningful domain, for example bars plus a target rule or points over a trend line.

Keep visual encodings consistent: one semantic category should not change color/symbol meaning between marks without a reason.

## Plottable Values

Use `.value(label, value)` with labels that describe the encoded variable. Labels support accessibility/debugging and are more useful than generic strings such as `"Value"` when several dimensions exist.

## Axes and Domains

Customize axes only when defaults fail the data/story.

- set explicit domains when comparisons require stable scales;
- format dates/numbers for the user's locale and precision needs;
- avoid overcrowded ticks/labels;
- use logarithmic/alternative transforms only when users can interpret them.

Do not hide axes solely for visual minimalism when that removes necessary context.

## Scrolling

Scrollable chart content is useful for dense ordered domains. Preserve a clear visible range and avoid creating so much horizontal content that users lose context.

When scroll position is programmatic, treat it as UI state with stable domain values rather than pixel offsets.

## Selection

Use built-in chart selection APIs when they express the interaction.

- single-value selection for inspecting one domain position;
- range selection for brushing/filtering;
- angle selection for radial charts where supported.

Keep selected data in semantic values, not geometry coordinates. Use `ChartProxy` only when built-in selection is insufficient.

## `ChartProxy`

`ChartProxy` is appropriate for custom overlays, geometry lookup, and interaction that cannot be expressed with selection modifiers.

Be careful with coordinate conversion and layout timing. Prefer built-in chart interactions when available because they track accessibility and framework evolution better.

## Styling

Use color, symbol, line style, and size as semantic visual channels.

- prefer system/semantic colors and sufficient contrast;
- keep categorical palettes stable;
- avoid encoding the same concept differently across screens;
- use legends when the encoding is not self-evident.

Do not rely on color alone for essential distinctions.

## Annotations

Annotations should clarify a selected/important value, not label every data point. Dense annotations quickly become harder to read than the chart itself.

## Animation

Animate data changes only when motion helps users track continuity. Preserve stable IDs/domain values so marks transition meaningfully.

Avoid decorative repeated animation, especially for large datasets or reduced-motion users.

## Chart3D

Use Chart3D only when a third quantitative dimension materially improves understanding. 3D perspective can make comparison harder, so 2D is usually preferable for ordinary categorical/time-series data.

For iOS 26+ APIs:

- gate only the 3D feature with availability checks;
- provide a meaningful 2D representation when older targets matter;
- keep camera/pose interaction accessible and nonessential to understanding the data.

## Performance

For large datasets:

- aggregate/downsample to the resolution the display can communicate;
- transform data outside the chart builder;
- avoid mark-by-mark expensive formatting/allocation;
- measure scrolling/selection responsiveness before adding custom caching.

Rendering every source sample is often unnecessary when many values map to the same pixels.

## Accessibility

Charts must communicate the same information without vision/color assumptions.

- provide meaningful labels/values for data points and series;
- support Dynamic Type around supporting text;
- ensure category distinction beyond color where needed;
- consider audio graph/accessibility representations when appropriate;
- provide a textual summary/table for complex analytics when that better serves assistive users.

## Common Failures

- unstable/random IDs causing animation churn;
- expensive sorting/filtering inside the chart builder;
- decorative 3D for inherently 2D comparisons;
- too many series/marks without hierarchy;
- color-only encoding;
- custom gestures where built-in selection already solves the interaction;
- applying one availability gate to unrelated older APIs.

## Review Checklist

1. Does the chart answer a specific question?
2. Are domains, units, labels, and identity correct?
3. Is the visual encoding consistent and accessible?
4. Are interaction/selection semantic rather than geometry-driven where possible?
5. Are newer APIs narrowly availability-gated?
6. Is dataset size appropriate for direct rendering?
