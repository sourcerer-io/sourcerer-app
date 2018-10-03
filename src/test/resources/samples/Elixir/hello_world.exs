defmodule HelloWorld do
  @moduledoc "this is the obligatory hello, world example"

  @doc "says hello to the name provided, or 'world' by default"
  def hi(name \\ "world") do
    "hello, #{name}"
  end
end
