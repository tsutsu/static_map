defmodule StaticMap do
  @doc false
  defmacro __using__(_opts) do
    quote do
      import StaticMap, only: [defmap: 2]
    end
  end

  defmacro get(map_module_alias, quoted_k) do
    maybe_precompile(:get, map_module_alias, quoted_k, __CALLER__)
  end

  defmacro fetch(map_module_alias, quoted_k) do
    maybe_precompile(:fetch, map_module_alias, quoted_k, __CALLER__)
  end

  defmacro fetch!(map_module_alias, quoted_k) do
    maybe_precompile(:fetch!, map_module_alias, quoted_k, __CALLER__)
  end

  defmacro has_key?(map_module_alias, quoted_k) do
    maybe_precompile(:has_key?, map_module_alias, quoted_k, __CALLER__)
  end

  @doc false
  defp maybe_precompile(function_name, map_module_alias, quoted_k, env) do
    if literal?(map_module_alias) and literal?(quoted_k) do
      try do
        precompile!(function_name, map_module_alias, quoted_k, env)
      rescue CompileError ->
        apply_at_runtime(function_name, map_module_alias, quoted_k)
      end
    else
      apply_at_runtime(function_name, map_module_alias, quoted_k)
    end
  end

  @doc false
  defp precompile!(function_name, map_module_alias, quoted_k, env) do
    {map_module, []} = Code.eval_quoted(map_module_alias, [], env)
    {k, []} = Code.eval_quoted(quoted_k, [], env)
    v = :erlang.apply(map_module, function_name, [k])
    Macro.escape(v)
  end

  @doc false
  defp apply_at_runtime(function_name, map_module_alias, quoted_k) do
    quote do
      unquote(map_module_alias).unquote(function_name)(unquote(quoted_k))
    end
  end

  @doc false
  defp literal?(quoted) do
    {_, acc} = Macro.prewalk quoted, true, fn node, acc ->
      case node do
        {:@, _, _} -> {nil, false}
        {var, _, mod} when is_atom(var) and is_atom(mod) -> {nil, false}
        _ -> {node, acc}
      end
    end

    acc
  end

  @doc """
  Defines a mapping function.

      use StaticMap
      defmap MyMap, [a: 1, b: 2]

  This will create a module `MyMap` in the current context, representing a statically-compiled version of the map.

  The API of the generated module closely resembles that of `Enum`, though the module does not implement `Enumerable`.

  ## Examples

  Get the map itself:

      iex> MyMap.to_map
      %{a: 1, b: 2}

  Get the map as a list:

      iex> MyMap.to_list
      [a: 1, b: 2]

  Get values from the map, with a default of `nil` (ala `Map.get/1`):

      iex> MyMap.get(:a)
      1

      iex> MyMap.get(:c)
      nil

  Fetch values from the map (ala `Map.fetch/1`):

      iex> MyMap.fetch(:a)
      {:ok, 1}

      iex> MyMap.fetch(:c)
      :error

  Get values from the map or raise (ala `Map.fetch!/1`):

      iex> MyMap.fetch!(:a)
      1

      iex> MyMap.fetch!(:c)
      ** (FunctionClauseError) no function clause matching in StaticMapTest.MyMap.fetch!/1

  Test for membership (ala `Map.has_key?/1`):

      iex> MyMap.has_key?(:a)
      true

      iex> MyMap.has_key?(:c)
      false

  Get keys (ala `Map.keys/1`), but as a compile-time-generated `MapSet`:

      iex> MyMap.keys_set
      #MapSet<[:a, :b]>

  Get values (ala `Map.values/1`), but as a compile-time-generated `MapSet`:

      iex> MyMap.values_set
      #MapSet<[1, 2]>
  """
  defmacro defmap(map_module_alias, map_pairs) do
    {map_pairs, []} = Code.eval_quoted(map_pairs, [], __CALLER__)

    map = Map.new(map_pairs)
    map_pairs = Enum.to_list(map)
    map_keys_set = Map.keys(map) |> MapSet.new()
    map_values_set = Map.values(map) |> MapSet.new()

    escaped_map = Macro.escape(map)
    escaped_map_pairs = Macro.escape(map_pairs)
    escaped_map_keys_set = Macro.escape(map_keys_set)
    escaped_map_values_set = Macro.escape(map_values_set)
    list_escaped_pairs = Enum.map map, fn {k, v} ->
      {Macro.escape(k), Macro.escape(v)}
    end

    to_map_function =
      quote location: :keep do
        def to_map(), do: unquote(escaped_map)
      end

    to_list_function =
      quote location: :keep do
        def to_list(), do: unquote(escaped_map_pairs)
      end

    get_function_header =
      quote location: :keep do
        def get(key, default \\ nil)
      end

    get_function_clauses =
      Enum.map(list_escaped_pairs, fn {escaped_k, escaped_v} ->
        quote location: :keep do
          def get(unquote(escaped_k), _), do: unquote(escaped_v)
        end
      end)

    get_function_fallback_clause =
      quote do
        def get(_, default), do: default
      end

    fetch_function_clauses =
      Enum.map(list_escaped_pairs, fn {escaped_k, escaped_v} ->
        quote location: :keep do
          def fetch(unquote(escaped_k)), do: {:ok, unquote(escaped_v)}
        end
      end)

    fetch_function_fallback_clause =
      quote location: :keep do
        def fetch(_), do: :error
      end

    fetch_strict_function_clauses =
      Enum.map(list_escaped_pairs, fn {escaped_k, escaped_v} ->
        quote location: :keep do
          def fetch!(unquote(escaped_k)), do: unquote(escaped_v)
        end
      end)

    has_key_p_function_clauses =
      Enum.map(list_escaped_pairs, fn {escaped_k, _} ->
        quote location: :keep do
          def has_key?(unquote(escaped_k)), do: true
        end
      end)

    has_key_p_function_fallback_clause =
      quote location: :keep do
        def has_key?(_), do: false
      end

    keys_set_function =
      quote location: :keep do
        def keys_set(), do: unquote(escaped_map_keys_set)
      end

    values_set_function =
      quote location: :keep do
        def values_set(), do: unquote(escaped_map_values_set)
      end

    quote location: :keep do
      defmodule unquote(map_module_alias) do
        unquote(to_map_function)
        unquote(to_list_function)

        unquote(get_function_header)
        unquote(get_function_clauses)
        unquote(get_function_fallback_clause)

        unquote(fetch_function_clauses)
        unquote(fetch_function_fallback_clause)

        unquote(fetch_strict_function_clauses)

        unquote(has_key_p_function_clauses)
        unquote(has_key_p_function_fallback_clause)

        unquote(keys_set_function)
        unquote(values_set_function)
      end
    end
  end
end
