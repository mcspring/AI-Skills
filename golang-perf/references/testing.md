# Testing with stretchr/testify

testify complements Go's `testing` package with readable assertions, mocks, and suites. It does not replace `testing` — always use `*testing.T` as the entry point.

## assert vs require

Both offer identical assertions. The difference is failure behavior:

- **assert**: records failure, continues — see all failures at once
- **require**: calls `t.FailNow()` — use for preconditions where continuing would panic

Use `assert.New(t)` / `require.New(t)` for readability. Name them `is` and `must`:

```go
func TestParseConfig(t *testing.T) {
    is := assert.New(t)
    must := require.New(t)

    cfg, err := ParseConfig("testdata/valid.yaml")
    must.NoError(err)    // stop if parsing fails
    must.NotNil(cfg)

    is.Equal("production", cfg.Environment)
    is.Equal(8080, cfg.Port)
    is.True(cfg.TLS.Enabled)
}
```

**Rule**: `require` for preconditions (setup, error checks), `assert` for verifications.

## Core Assertions

```go
is := assert.New(t)

// Equality
is.Equal(expected, actual)              // DeepEqual + exact type
is.NotEqual(unexpected, actual)
is.EqualValues(expected, actual)        // converts to common type
is.EqualExportedValues(expected, actual)

// Nil / Bool / Emptiness
is.Nil(obj)                  is.NotNil(obj)
is.True(cond)                is.False(cond)
is.Empty(collection)         is.NotEmpty(collection)
is.Len(collection, n)

// Contains (strings, slices, map keys)
is.Contains("hello world", "world")
is.Contains([]int{1, 2, 3}, 2)
is.Contains(map[string]int{"a": 1}, "a")

// Comparison
is.Greater(actual, threshold)     is.Less(actual, ceiling)
is.Positive(val)                  is.Negative(val)
is.Zero(val)

// Errors
is.Error(err)                     is.NoError(err)
is.ErrorIs(err, ErrNotFound)      // walks error chain
is.ErrorAs(err, &target)
is.ErrorContains(err, "not found")

// Type
is.IsType(&User{}, obj)
is.Implements((*io.Reader)(nil), obj)
```

**Argument order**: always `(expected, actual)`.

## Advanced Assertions

```go
is.ElementsMatch([]string{"b", "a", "c"}, result)     // unordered
is.InDelta(3.14, computedPi, 0.01)                    // float tolerance
is.JSONEq(`{"name":"alice"}`, `{"name": "alice"}`)     // ignores whitespace
is.WithinDuration(expected, actual, 5*time.Second)
is.Regexp(`^user-[a-f0-9]+$`, userID)

// Async polling
is.Eventually(func() bool {
    status, _ := client.GetJobStatus(jobID)
    return status == "completed"
}, 5*time.Second, 100*time.Millisecond)

// Async with rich assertions
is.EventuallyWithT(func(c *assert.CollectT) {
    resp, err := client.GetOrder(orderID)
    assert.NoError(c, err)
    assert.Equal(c, "shipped", resp.Status)
}, 10*time.Second, 500*time.Millisecond)
```

## testify/mock

Mock interfaces to isolate the unit under test. Embed `mock.Mock`, implement methods with `m.Called()`, always verify with `AssertExpectations(t)`.

```go
type MockStore struct { mock.Mock }

func (m *MockStore) FindByID(ctx context.Context, id string) (*User, error) {
    args := m.Called(ctx, id)
    return args.Get(0).(*User), args.Error(1)
}

// In test:
store := new(MockStore)
store.On("FindByID", mock.Anything, "user-1").Return(&User{Name: "Alice"}, nil).Once()

svc := NewUserService(store)
user, err := svc.GetUser(ctx, "user-1")

is.NoError(err)
is.Equal("Alice", user.Name)
store.AssertExpectations(t)
```

**Matchers**: `mock.Anything`, `mock.AnythingOfType("string")`, `mock.MatchedBy(func(v T) bool)`.

**Call modifiers**: `.Once()`, `.Times(n)`, `.Maybe()`, `.Run(func(args))`, `.Return(...)`.

## testify/suite

Suites group related tests with shared setup/teardown:

```
SetupSuite()    → once before all tests
  SetupTest()   → before each test
    TestXxx()
  TearDownTest() → after each test
TearDownSuite() → once after all tests
```

```go
type TokenServiceSuite struct {
    suite.Suite
    store   *MockTokenStore
    service *TokenService
}

func (s *TokenServiceSuite) SetupTest() {
    s.store = new(MockTokenStore)
    s.service = NewTokenService(s.store)
}

func (s *TokenServiceSuite) TestGenerate_ReturnsValidToken() {
    s.store.On("Save", mock.Anything, mock.Anything).Return(nil)
    token, err := s.service.Generate("user-42")
    s.NoError(err)
    s.NotEmpty(token)
    s.store.AssertExpectations(s.T())
}

// Required launcher
func TestTokenServiceSuite(t *testing.T) {
    suite.Run(t, new(TokenServiceSuite))
}
```

Suite methods (`s.Equal()`) behave like `assert`. For require: `s.Require().NotNil(obj)`.

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Forgetting `AssertExpectations(t)` | Mock expectations silently pass without it |
| `is.Equal(ErrNotFound, err)` | Use `is.ErrorIs` to walk wrapped chains |
| Swapped `(actual, expected)` order | Always `(expected, actual)` |
| `assert` for guards/preconditions | Use `require` — test continues after assert failure |
| Missing `suite.Run()` launcher | Zero tests execute silently without it |
| Comparing pointers with `is.Equal` | Dereference or use `EqualExportedValues` |
