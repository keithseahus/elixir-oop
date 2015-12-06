defmodule OOP.Mixfile do
  use Mix.Project

  def project do
    [ app: :oop,
      version: "0.0.2",
      elixir: ">= 1.1.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [ :managed_process ] ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [ { :managed_process, github: "keithseahus/elixir-managed_process" } ]
  end
end
