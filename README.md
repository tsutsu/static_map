# MapsAsFunctions

A compile-time macro to build fast mapper and predicate functions from a map.

## Usage

Define a map in your module using the macro `defmap/2`:

```elixir
use MapsAsFunctions

defmap :bar, [
  a: 1,
  b: 2
]
```

`defmap/2` will define, given a map `:bar`, a module-attribute `@bar`, which you can use as normal in further function definitions:

```elixir
def bar_values do
  Map.values(@bar)
end
```

`defmap/2` will also define, given a map `:bar`, the public functions `bar/0`, `bar/1`, and `bar?/1`:

```elixir
iex> Foo.bar
%{a: 1, b: 2}

iex> Foo.bar(:a)
1

iex> Foo.bar(:c)
nil

iex> Foo.bar?(:a)
true

iex> Foo.bar?(:c)
false
```

There will also be a strict version of `bar/1`, called `bar!/1`:

```elixir
iex> Foo.bar!(:a)
1

iex> Foo.bar!(:c)
** (FunctionClauseError) no function clause matching in Foo.bar!/1
```

...and a function `bar_keys/0` that returns the keys of the map as a `MapSet`:

```elixir
iex> Foo.bar_keys
#MapSet<[:a, :b]>
```

None of the above functions have any runtime logic; they are all expanded into a series of function-clauses at compile time.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `maps_as_functions` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:maps_as_functions, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/maps_as_functions](https://hexdocs.pm/maps_as_functions).

