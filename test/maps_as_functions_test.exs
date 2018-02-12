defmodule MapsAsFunctionsTest do
  use ExUnit.Case

  defmodule Foo do
    use MapsAsFunctions
    defmap :bar, %{a: 1, b: 2}
  end

  doctest MapsAsFunctions
end
