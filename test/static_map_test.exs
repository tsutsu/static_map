defmodule StaticMapTest do
  use ExUnit.Case

  use StaticMap
  defmap MyMap, %{a: 1, b: 2}

  doctest StaticMap
end
