defmodule HashcashTest do
  use ExUnit.Case
  use Bitwise
  doctest Hashcash

  @wikipedia_example "1:20:060408:adam@cypherspace.org::1QTjaYd7niiQA/sc:ePa"
  @wikipedia_hcash %Hashcash{counter: "ePa",
			     date: [year: 2006, month: 4, day: 8],
			     ext: "",
			     rand: "1QTjaYd7niiQA/sc",
			     resource: "adam@cypherspace.org",
			     version: 1,
			     bits: 20,
			     stamp_string: @wikipedia_example
  }

  test "create new hashcash" do
    r20 = Hashcash.resource("testhashcash")
    assert( r20.bits == 20 )
    assert( r20.resource == "testhashcash" )
    assert( [year: y, month: m, day: d] = r20.date)
    assert( y > 2000 and m in 1..12 and d in 1..31 )
    assert( byte_size(r20.rand) > 12 )
    r15 = Hashcash.resource_bits(r20,15)
    assert( r15.bits == 15 )
  end
  
  test "create hashcash from string" do
    assert(Hashcash.stamp(@wikipedia_example) == @wikipedia_hcash )
  end

  test "create hashcash from string and verify parts" do
    hcash = Hashcash.stamp(@wikipedia_example)
    assert(hcash == @wikipedia_hcash)
    assert(hcash.version == 1)
    assert(hcash.bits == 20)
    assert(hcash.date == [year: 2006, month: 4, day: 8])
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
    hcash = Hashcash.stamp(@wikipedia_example)
    assert(Hashcash.verify(hcash,"foo@example.org") == {:error, :resource_mismatch})
    assert(Hashcash.verify(hcash,"adam@cypherspace.org") == {:error, :resource_expired})

    stamp = invalidate_stamp("1:32:#{date_string()}:testhashcash::foobar1234:1")

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
