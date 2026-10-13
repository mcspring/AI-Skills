# Naming Conventions

Go favors short names, package context, and consistency with the standard library. Prefer idiomatic names over rigid naming templates.

## Core Conventions

| Element | Guidance | Example |
|---|---|---|
| Package | short, lowercase, meaningful | `http`, `json`, `bytes` |
| Exported identifier | MixedCaps | `ReadAll`, `HTTPClient` |
| Unexported identifier | mixedCaps | `parseToken`, `userCount` |
| Constant | MixedCaps, not C-style ALL_CAPS | `MaxRetries` |
| Error variable | commonly `ErrX` when exported/sentinel | `ErrNotFound` |
| Error type | descriptive type name | `PathError` |
| Test | `TestXxx` / descriptive subtests | `TestParseToken` |

Use underscores where the language/ecosystem requires them (for example generated/cgo-related names or file names); ordinary Go identifiers conventionally use MixedCaps.

## Package Context and Stuttering

The package name already appears at call sites, so avoid repeating it when the shorter name remains clear:

```go
http.Client
json.Decoder
ring.New
```

`http.HTTPClient` or `json.JSONDecoder` usually stutter. This is a readability heuristic, not a rule to shorten names until meaning is lost.

## Initialisms

Keep common initialisms consistently capitalized within identifiers:

```go
URL
HTTPServer
parseHTTPResponse
userID
```

Follow the project's established spelling for domain-specific abbreviations.

## Constructors

`New` is conventional when a package has one obvious primary constructed type. `NewRequest`, `NewClient`, or other descriptive constructors are appropriate when the package exposes several constructors or the distinction matters.

Do not create a constructor when the useful zero value or a struct literal is clearer and safe.

## Receivers

Receiver names are typically short and derived from the type (`c *Client`, `b *Buffer`). Keep the same receiver name across that type's methods where practical.

Avoid `this`/`self` because they add little information in Go, but choose clarity over a fixed receiver-name length.

## Getters and Booleans

Go getters usually omit `Get`: `Name()` rather than `GetName()`. A setter, when useful, may be `SetName`.

Boolean names should read clearly at the call site. Prefixes such as `Is`, `Has`, or `Can` are useful when they improve the sentence, but are not mandatory for every boolean field.

## Zero Values and Enum-like Constants

A zero value such as `Unknown`/`Invalid` is useful when it makes an uninitialized enum-like value safe and explicit. Do not add an artificial unknown case when zero already has a natural valid meaning.

## Error Strings

Errors that are composed/wrapped by callers conventionally begin lowercase and avoid terminal punctuation unless the text contains proper nouns or other formatting that requires it.

## Scope and Length

Use short names in small scopes (`i`, `r`, `b`) and more descriptive names as scope or ambiguity grows. Avoid both single-letter names across large scopes and redundant long names that merely repeat type/package context.

## Review Questions

- Does the name read naturally at its call site?
- Does the package already supply context that the identifier repeats?
- Is the abbreviation conventional and consistent?
- Is a zero-value name expressing a real semantic state?
- Would renaming improve clarity enough to justify API churn?