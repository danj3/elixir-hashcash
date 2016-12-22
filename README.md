# Hashcash

Elixir implementation of the hashcash algorigthm as described in
http://hashcash.org and
https://en.wikipedia.org/wiki/Hashcash

Based loosely on https://github.com/grempe/hashcash.git

## Usage

The tests are a more complete set of examples, however:

Import a hashcash stamp

```elixir
stamp = Hashcash.stamp(stamp_string)
```

 Verify a stamp

```elixir
case Hashcash.verify(stamp,"valid_resourcd@example.com") do
{:ok, :verified } -> :yay
{:error, :unproven} -> :work_didnt_happen
{:error, :resource_mismatch} -> :valid_resource_didnt_match
{:error, :resource_expired} -> :time_stamp_is_too_old  # 2 days
end
```

## Installation

This is not applicable, not available on Hex, but will be shortly.

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `hashcash` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:hashcash, "~> 0.1.0"}]
    end
    ```
