Code.load_file("hello_world.exs")

ExUnit.start

defmodule HelloWorldTest do
  use ExUnit.Case

  test "say hello" do
    assert HelloWorld.hi() == "hello, world"
  end

  test "say hello to michael" do
    assert HelloWorld.hi("michael") == "hello, michael"
  end
end
