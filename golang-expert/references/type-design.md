# Go Type and API Design

Use this reference for interfaces, constructors, method sets, zero values, generics, and exported API shape.

## Start Concrete

Prefer concrete types until an abstraction boundary is useful. Introduce an interface when callers need substitutability, testing boundaries, multiple implementations, or decoupling from an external dependency.

Small interfaces are easier to satisfy and compose, but method count is not a hard rule. The right interface expresses one coherent capability.

## Define Interfaces Near Consumption

Interfaces often belong in the package that consumes the capability because that package knows the minimum behavior it needs.

Provider-side interfaces are still reasonable when the abstraction itself is part of the public domain API (for example `io.Reader`). Avoid creating an interface solely because a concrete type exists.

## Accept Interfaces, Return Useful Types

Accept the narrowest useful behavior at boundaries. Returning a concrete type is often simpler because callers retain its full capabilities.

Returning an interface can be appropriate when hiding implementations is itself part of the API contract. Treat “never return interfaces” as a heuristic, not a language rule.

## Zero Values

Design useful zero values where it is natural (`bytes.Buffer`, `sync.Mutex`).

Do not force a zero value to be usable when the type requires mandatory validated configuration, external resources, or invariants that cannot be represented safely. In those cases, a constructor is clearer.

## Constructors

Use constructors when initialization establishes invariants or dependencies.

- `New` is conventional when one primary exported type exists;
- a more specific name is fine when several constructions are meaningful;
- return an error only when construction can actually fail;
- functional options are useful for a growing set of independent optional settings, not as a mandatory pattern for every constructor.

Avoid options that make invalid combinations easy to express; a config struct or separate constructors may be clearer.

## Pointer vs Value Receivers

Use pointer receivers when methods mutate the receiver, the type is large/noncopyable, contains synchronization state, or identity matters.

Value receivers are natural for small immutable/value-semantic types.

Consistency matters, but a type can legitimately have different method-set constraints. Do not convert receivers mechanically only to make them uniform.

## Exported Types

Keep exported surface area small and stable.

- expose fields when direct mutation is intentionally part of the API;
- hide fields when invariants must be maintained;
- use methods for behavior, not Java-style getters/setters by default;
- avoid exporting concrete implementation details that make future change difficult.

Serialized structs need tags only for formats whose default field names/behavior do not match the intended wire contract. Tags are not inherently required on every exported field.

## Enums and Constants

Use named integer/string types plus constants when they make invalid mixing harder.

A meaningful zero value is helpful, but an `Unknown` zero member is not universally required. Choose zero semantics based on whether “unset/unknown” is a real state.

## Generics

Use generics when one algorithm/data structure genuinely works over a family of types and avoids duplication without obscuring intent.

Prefer the weakest constraint that expresses required operations. Do not introduce a custom constraint hierarchy when `any`, `comparable`, or `cmp.Ordered` is enough.

### Go 1.27 Generic Methods

When the module targets Go 1.27+, methods can declare their own type parameters.

Use a generic method when the operation naturally belongs to the receiver and the method form improves the API. Keep a package-level generic function when it is conceptually independent or better for compatibility/discoverability.

Interface methods still cannot declare their own type parameters; consider a generic type/interface shape or function instead.

## Type Aliases vs Defined Types

Use a defined type when you want a distinct method set or type-safety boundary. Use an alias when two names should denote the same type for migration/organization.

Do not create newtypes for every primitive if they add ceremony without preventing mistakes.

## Composition

Prefer embedding/composition when it exposes the right behavior, but be cautious in public structs: embedding promotes methods/fields and can unintentionally expand the API surface.

## Compile-Time Interface Assertions

`var _ Interface = (*Type)(nil)` is useful when conformance is intentional but not otherwise obvious from a nearby assignment/return. It is not needed for every implementation.

## Common Failures

- interfaces invented before a consumer needs abstraction;
- giant “service” interfaces that force unrelated mocks;
- functional options for two mandatory fields;
- exposing mutable fields that bypass invariants;
- returning interface only to hide a type callers actually need;
- generic helpers that are harder to understand than two simple functions;
- raising minimum Go version for generic-method style without API benefit.

## Review Questions

1. What invariant/abstraction does this type represent?
2. Is ownership/mutability clear?
3. Could the exported surface be smaller?
4. Does the zero value have sensible semantics, or should construction be explicit?
5. Is an interface required by a consumer/domain boundary?
6. Do generics simplify real duplication?
7. Will this API remain evolvable without breaking callers?
