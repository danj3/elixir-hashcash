defmodule HashcashTest do
  use ExUnit.Case
  use Bitwise
  doctest Hashcash

  test "the truth" do
    assert 1 + 1 == 2
  end

  @wikipedia_example "1:20:060408:adam@cypherspace.org::1QTjaYd7niiQA/sc:ePa"
  @wikipedia_stamp %Hashcash{counter: "ePa",
			     date: [year: 2006, month: 4, day: 8],
			     ext: "",
			     rand: "1QTjaYd7niiQA/sc",
			     resource: "adam@cypherspace.org",
			     version: 1,
			     bits: 20,
			     stamp_string: @wikipedia_example
  }
  
  test "create resource" do
    # This leaves date_now exposed as untested
    assert(Hashcash.resource("testhashcash") ==
      %Hashcash{resource: "testhashcash", bits: 20, date: Hashcash.date_now})
    assert(Hashcash.resource("testhashcash") |> Hashcash.resource_bits(15) ==
      %Hashcash{resource: "testhashcash", bits: 15, date: Hashcash.date_now})
  end
  test "create stamp" do
    assert(Hashcash.stamp(@wikipedia_example) == @wikipedia_stamp )
  end

  test "parse stamp" do
    stamp = Hashcash.stamp(@wikipedia_example)
    assert(stamp == @wikipedia_stamp)
    assert(stamp.version == 1)
    assert(stamp.bits == 20)
    assert(stamp.date == [year: 2006, month: 4, day: 8])
  end

  def invalidate_stamp(stamp) do
    :crypto.hash(:sha,stamp)
    |> :binary.decode_unsigned()
    |> (fn int_digest -> int_digest >>> (160-32) end).()
    |> case do
	 0 -> invalidate_stamp(stamp <> "1")
	 _ -> stamp
       end
  end

  test "rand generate" do
    assert({:ok, _rest} = Base.decode64(Hashcash.rand_generate <> "="))
  end

  test "date format" do
    assert([year: _y, month: _m, day: _d] = Hashcash.date_now)
    assert("200507" = Hashcash.date_format([year: 2020, month: 5, day: 7]))
  end
  
  def date_string do
    Hashcash.date_format(Hashcash.date_now)
  end

  test "verify errors" do
    stamp = Hashcash.stamp(@wikipedia_example)
    assert(Hashcash.verify(stamp,"foo@example.org") == {:error, :resource_mismatch})
    assert(Hashcash.verify(stamp,"adam@cypherspace.org") == {:error, :resource_expired})

    stamp = invalidate_stamp("1:32:#{date_string}:testhashcash::foobar1234:1")

    assert(Hashcash.stamp(stamp)
    |> Hashcash.verify("testhashcash") == {:error, :unproven})
    
  end

  test "create and verify" do
    assert(Hashcash.resource("testhashcash")
    |> Hashcash.generate
    |> Hashcash.verify("testhashcash") == {:ok, :verified})
    
    assert(Hashcash.resource("testhashcash")
    |> Hashcash.resource_bits(10)
    |> Hashcash.generate
    |> Hashcash.verify("testhashcash") == {:ok, :verified})
  end
end
