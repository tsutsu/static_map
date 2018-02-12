defmodule MapsAsFunctions do
  @doc false
  defmacro __using__(_opts) do
    quote do
      import MapsAsFunctions
    end
  end

  @doc """
  Defines a mapping function.

      defmodule Foo do
        use MapsAsFunctions
        defmap :bar, [a: 1, b: 2]
      end

  ## Examples

  Get the map:

      iex> Foo.bar
      %{a: 1, b: 2}

  Get values from the map, with a default of `nil` (ala `Map.get/1`):

      iex> Foo.bar(:a)
      1

      iex> Foo.bar(:c)
      nil

  Get values from the map or raise (ala `Map.fetch!/1`):

      iex> Foo.bar!(:a)
      1

      iex> Foo.bar!(:c)
      ** (FunctionClauseError) no function clause matching in MapsAsFunctionsTest.Foo.bar!/1

  Test for membership (ala `Map.has_key?/1`):

      iex> Foo.bar?(:a)
      true

      iex> Foo.bar?(:c)
      false

  Get keys (ala `Map.keys/1`), as a compile-time-generated `MapSet`:

      iex> Foo.bar_keys
      #MapSet<[:a, :b]>
  """
  defmacro defmap(map_name, map_pairs) do
    map_pairs = Map.new(map_pairs)
    map_keys_set = map_pairs |> Map.keys() |> MapSet.new()

    escaped_map_pairs = Macro.escape(map_pairs)

    attribute_part =
      quote location: :keep do
        Module.put_attribute(__MODULE__, unquote(map_name), unquote(escaped_map_pairs))
        def unquote(map_name)(), do: unquote(escaped_map_pairs)
      end

    mapper_clauses =
      Enum.map(map_pairs, fn {k, v} ->
        escaped_k = Macro.escape(k)
        escaped_v = Macro.escape(v)

        quote location: :keep do
          def unquote(map_name)(unquote(escaped_k)), do: unquote(escaped_v)
        end
      end)

    mapper_fallback_clause =
      quote do
        def unquote(map_name)(_), do: nil
      end

    strict_mapper_name = :"#{map_name}!"

    strict_mapper_clauses =
      Enum.map(map_pairs, fn {k, v} ->
        escaped_k = Macro.escape(k)
        escaped_v = Macro.escape(v)

        quote location: :keep do
          def unquote(strict_mapper_name)(unquote(escaped_k)), do: unquote(escaped_v)
        end
      end)

    predicate_name = :"#{map_name}?"

    predicate_clauses =
      Enum.map(map_pairs, fn {k, _} ->
        escaped_k = Macro.escape(k)

        quote location: :keep do
          def unquote(predicate_name)(unquote(escaped_k)), do: true
        end
      end)

    predicate_fallback_clause =
      quote location: :keep do
        def unquote(predicate_name)(_), do: false
      end

    keys_name = :"#{map_name}_keys"
    escaped_map_keys_set = Macro.escape(map_keys_set)

    keys_part =
      quote location: :keep do
        def unquote(keys_name)(), do: unquote(escaped_map_keys_set)
      end

    quote location: :keep do
      unquote(attribute_part)

      unquote(mapper_clauses)
      unquote(mapper_fallback_clause)

      unquote(strict_mapper_clauses)

      unquote(predicate_clauses)
      unquote(predicate_fallback_clause)

      unquote(keys_part)
    end
  end
end
