# SwiftUI Lists, Collections, and Identity

Use this reference for `List`, `ForEach`, grids, reordering, selection, and collection identity.

## Identity First

Every dynamic element needs stable semantic identity for correct state, animation, diffing, and selection.

Prefer:

- `Identifiable` domain IDs;
- an explicit stable key path;
- value identity only when the value itself is genuinely unique and stable.

Avoid transient/random IDs generated during rendering.

## Indices

Indices are positions, not item identities. Using `.indices` is fine for a fixed positional UI where insertion/removal/reordering cannot change semantic identity.

For mutable collections, identify by the item and derive/index into the collection separately when mutation requires a position.

## `ForEach`

Keep each element's view structure predictable and move expensive filtering/sorting outside the builder when collection size makes that work meaningful.

Do not assume “one view per item” is a hard correctness rule; builders can produce conditional/grouped content. The real concerns are stable identity, understandable structure, and performance.

## `List` vs Scroll + Lazy Stack/Grid

Use `List` when you want platform list behavior such as selection, edit actions, row semantics, swipe actions, separators, disclosure, or large standard collections.

Use `ScrollView` + lazy containers when custom layout/spacing/composition is more important than list semantics.

Do not replace `List` solely for visual styling if native modifiers can achieve the design.

## Selection

Model selection by stable item ID/value. Use single or multiple selection according to platform interaction conventions.

On macOS/iPad, selection often interacts with keyboard/focus/navigation; preserve native semantics rather than implementing tap-only selected-row state.

## Reordering

Use native reorder APIs when available. Keep mutation in the source-of-truth collection and identify items stably.

The 2027 SwiftUI generation adds reorderable-container support beyond `List`, including stacks, grids, and custom layouts. Use it when the project SDK/target supports it instead of rebuilding drag/drop ordering manually.

For extremely large collections, evaluate framework traversal/layout cost with representative data. Native reordering can still need to inspect collection structure; virtualization is not a substitute for data-scale testing.

## Swipe Actions

Use native swipe actions for familiar row/content actions. The 2027 SDK generation extends swipe-action support beyond traditional `List` through container support.

Keep destructive actions explicit and accessible through non-swipe alternatives when discoverability matters.

## Filtering and Sorting

For small collections, a computed filtered/sorted value can be perfectly adequate. For large or frequently updating collections, avoid repeating expensive transforms every body evaluation.

Choose among model-level derived data, cached/query results, database filtering, or a local computed projection based on actual cost. Do not create synchronized duplicate `@State` solely to avoid a cheap computed filter.

## Per-Row State

Keep transient state inside a row only when it belongs to that row's identity/lifetime. State that must survive item removal/recreation belongs in the model/store.

Broad shared observable state can invalidate many rows; narrow row inputs or per-item observable state can help when profiling confirms fan-out.

## Navigation From Rows

Prefer value-based navigation with stable values/IDs on supported targets. Avoid embedding destination state in a way that recreates expensive models unpredictably for every row evaluation.

See `sheet-navigation-patterns.md`.

## Grids and Tables

Use lazy grids for standard large grid behavior and `Grid` for smaller two-dimensional layouts where all cells participate in layout.

Use `Table` where columnar data, sorting, and selection fit desktop/tablet interaction. Adapt dense desktop data for smaller form factors rather than forcing the same presentation.

## Empty and Loading States

Keep empty/loading/error presentation outside the item identity loop. A placeholder should not masquerade as a data item unless it has real collection semantics.

## Performance

For large collections:

- stable IDs;
- lazy containers where appropriate;
- narrow row dependencies;
- properly sized images;
- no synchronous I/O/heavy transforms in row body;
- bounded async work rather than task-per-row fan-out.

See `performance-patterns.md`.

## Accessibility

Preserve semantic controls and list/table grouping. Ensure reorder/delete/swipe-only actions have accessible equivalents or system actions exposed to assistive technologies.

## Common Failures

- random UUID created during render as item ID;
- `.indices` used as identity for a collection that reorders/inserts/deletes;
- filtering/sorting a large collection in every row/body pass;
- row task starts repeatedly with no cancellation;
- custom swipe/reorder implementation replacing a native API without need;
- selection modeled by visual position rather than stable item identity.

## Review Checklist

1. Is identity stable across updates/reordering?
2. Does the chosen container match semantic/platform behavior?
3. Are transforms and row construction cheap enough for the data size?
4. Does row state have the correct lifetime?
5. Are reordering, selection, and destructive actions accessible?
6. Can current native APIs replace custom drag/swipe plumbing?
