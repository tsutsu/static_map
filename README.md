# StaticMap

A compile-time macro to build a module that behaves like a `map()`, but with "pre-baked" lookup functions.

## Installation

Add `static_map` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:static_map, "~> 0.1.0"}
  ]
end
```

## Usage

First, require and import `StaticMap` into the current context:

```elixir
use StaticMap
```

Then you can define a map module:

```elixir
defmap MyMap, [
  a: 1,
  b: 2
]
```

The first argument to `StaticMap.defmap/2` is the name of the module to define, as an Alias (calling `defmap Bar, ...` from within the body of a module `Foo` will thus define `Foo.Bar`.)

You can pass any enumerable value as the second argument; it will be transformed into a `map()` using `Map.new/1`.

The module defined above (`MyMap`) will contain the following functions:

 * `MyMap.to_map/0`: returns the map
 * `MyMap.to_list/0`: returns the map, passed through `Enum.to_list/1`
 * `MyMap.get/1`: behaves as `Map.get/2`
 * `MyMap.get/2`: behaves as `Map.get/3`
 * `MyMap.fetch/1`: behaves as `Map.fetch/2`
 * `MyMap.fetch!/1`: behaves as `Map.fetch!/2`
 * `MyMap.has_key?/1`: behaves as `Map.has_key?/2`
 * `MyMap.keys_set/0`: behaves as `Map.keys/1`, passed through `MapSet.new/1`
 * `MyMap.values_set/0`: behaves as `Map.values/1`, passed through `MapSet.new/1`

None of the above functions have any runtime logic; all return values are generated at compile time, and each potential input is built into its own function clause.

### Precompiled accessor macros

`StaticMap` contains macros that allow for *compile-time lookups* of values in your map module.

* `StaticMap.get/2`
* `StaticMap.fetch/2`
* `StaticMap.fetch!/2`
* `StaticMap.has_key!/2`

These macros act the same as their equivalent functions in `Map`, taking your map module in place of a `map()`.

When used in your code, these macros will—*if possible*—expand to their literal value, rather than to a function-call to your map module. (See the Efficiency Guide below for more details.) These macro-accessor calls can effectively replace the usage of huge numbers of literals or scalar module attributes in your code:

```elixir
# Before
@foo_one 1
@foo_two 2
def x, do: [
  @foo_one,
  @foo_two
]

# After
defmap Foo, %{one: 1, two: 2}
def x, do: [
  StaticMap.fetch!(Foo, :one),
  StaticMap.fetch!(Foo, :two)
]
```

If literal expansion is not possible (e.g. if you are passing a variable key name to the macro-call), calls to the accessor macros will instead expand to calls to your map-module's accessor functions. Thus, there are no disadvantages (other than verbosity) to always preferring the macro-accessors on `StaticMap` over directly calling the accessor functions on the map-module.

## Efficiency Guide

### Runtime clause-match overhead

Because map-key hashing has a constant overhead, the accessor functions defined on the map module (`MyMap.has_key?/1`, `MyMap.get/1,2`, `MyMap.fetch/1`, and `MyMap.fetch!/1`) will be faster than their counterparts in `Map`, but only up to a point. For large (>500 pair) maps, the `O(log n)` time-complexity of [the binary-search op used in clause-head unification](http://erlang.org/doc/efficiency_guide/functions.html) will outweigh the constant overhead of map-key hashing.

For such high-cardinality maps, it is better to use rely on `StaticMap` only for its value functions (`MyMap.to_map/0`, `MyMap.to_list/0`, `MyMap.keys_set/0` and `MyMap.values_set/0`), and to do any accessing of the map by calling `MyMap.to_map/0` and passing the return value to regular `Map` functions.

### When precompiled accessors will expand to literals

The `StaticMap` precompiled-accessor macros first *test* the passed (quoted) expressions to determine whether they seem to contain only compile-time-available literals. Importantly, any use of a variable or module-attribute in the accessor macro-call will disqualify the macro-call from literal expansion, instead directly expanding to the runtime-call form.

If the passed expressions *are* eligible for compile-time evaluation, the macro will then attempt to evaluate the passed expressions in the calling context and use the results to perform the lookup. If, during this step, a `CompileError` is generated, the macro will fall back to runtime expansion.

The accessor macro has no way of knowing whether a function call is "pure", and so will happily evaluate and reduce impure/nondeterministic functions to literals. Avoid using nondeterministic functions!

To summarize, here are the guidelines for keys:

* **Do**: use a literal key — `MyMap |> StaticMap.fetch!(:a)`
* **Do**: use an alias key — `MyMap |> StaticMap.fetch!(Foo)`
* **Do**: pass a literal expression through a pure+deterministic function that evaluates to a literal or alias key — `MyMap |> StaticMap.fetch!(List.first([:a, :b]))`
* **Do not**: use a variable key — `MyMap |> StaticMap.fetch(a)`
* **Do not**: use a module-attribute key — `MyMap |> StaticMap.fetch(@a)`
* **Do not**: pass an expression through an impure/nondeterministic function — `MyMap |> StaticMap.fetch!(make_ref())`
* **Do not**: use a variable or module-attribute in an expression that evaluates to a key — `MyMap |> StaticMap.fetch(List.first([:a, x, @y]))`

And here are the guidelines for map-modules:

* **Do**: use a literal map-module — `:my_map |> StaticMap.fetch!(:a)`
* **Do**: use an alias map-module — `MyMap |> StaticMap.fetch!(:a)`
* **Do**: pass a literal expression through a pure+deterministic function that evaluates to a map-module literal or alias — `[MapA, MapB] |> List.first() |> StaticMap.fetch!(:a)`
* **Do not**: use a module-attribute map-module — `@map_module |> StaticMap.fetch(:a)`
* **Do not**: use a map-module alias that does not name a compiled-and-loaded module — `MapDefinedLaterInTheFile |> StaticMap.fetch!(:a)`
* **Do not**: pass an expression through an impure/nondeterministic function — `[MapA, MapB] |> Enum.shuffle() |> List.first() |> StaticMap.fetch!(make_ref())`
* **Do not**: use a variable or module-attribute in an expression that evaluates to a map-module — `[MyMap, x, @y] |> List.first() |> StaticMap.fetch(:a)`
