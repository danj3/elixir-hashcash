defmodule Hashcash do
  require Logger
  
  defstruct version: 1,
    bits: 20,
    date: nil,
    resource: nil,
    ext: nil,
    rand: nil,
    counter: 0,
    stamp_string: nil,
    stamp_base: nil
  
  @stamp_version "1"
  
  # Create a %Hashcash stamp from a stamp string. Use this to turn a string
  # that may be passed between parties to a form that can be used with the
  # rest of the functions here.
  def stamp(stamp_string) do
    [@stamp_version,
     bits,
     <<date_y::binary-size(2), date_m::binary-size(2), date_d::binary-size(2)>>,
     resource,
     ext,
     rand,
     counter] = String.split(stamp_string,":")

    %Hashcash{bits: String.to_integer(bits),
	      date: [year: String.to_integer(date_y)+2000,
		     month: String.to_integer(date_m),
		     day: String.to_integer(date_d)],
	      resource: resource,
	      ext: ext,
	      rand: rand,
	      counter: counter,
	      stamp_string: stamp_string,
    }
  end
  
  # Create a new %Hashcash with the resource_string and specified
  # date Keyword list
  def resource(resource_string, date = [year: _y, month: _m, day: _d]) do
    %Hashcash{resource: resource_string, rand: rand_generate, date: date}
  end

  # Create a new %Hashcash with resource_string and today as the date.
  def resource(resource_string) do
    %Hashcash{resource: resource_string, rand: rand_generate, date: date_now}
  end

  # Modify the bits required of a %Hashcash 
  def resource_bits(stamp,bits) when is_integer(bits) do
    %Hashcash{stamp | bits: bits}
  end

  # Modify the date of a %Hashcash
  def resource_date(stamp, y, m, d) when is_integer(y) and is_integer(m) and is_integer(d) do
    %Hashcash{stamp | date: %{year: y, month: m, day: d}}
  end

  def strip_trailing_char(string) do
    slen = byte_size(string)-1
    <<core::binary-size(slen), _rest::binary>> = string
    core
  end
  # Generate the rand field using a crypto.strong_rand_bytes
  def rand_generate do
    12
    |> :crypto.strong_rand_bytes
    |> Base.encode64
    |> strip_trailing_char # remove the trailing =
  end

  # Set rand field of %Hashcash to newly generated string
  def resource_rand(stamp) do
    %Hashcash{stamp | rand: rand_generate}
  end

  # Generate date string section from date keywords list
  def date_format(date_keywords) do
    [y,m,d] = Keyword.values(date_keywords)
    to_string(:io_lib.format("~2..0B~2..0B~2..0B", [rem(y,100),m,d]))
  end

  # Generate date keywords list of now
  def date_now do
    %{day: day, month: month, year: year} = DateTime.utc_now
    [year: year, month: month, day: day]
  end

  # Generate or return stamp.base from stamp properies
  # This excludes the count field so that the generator can use this base
  # with successive iterations of new counts by appending just the count.
  def resource_format_base(stamp) do
    if base = stamp.stamp_base do
      base
    else
	Enum.join([stamp.version,
		   stamp.bits,
		   date_format(stamp.date),
		   stamp.resource,
		   stamp.ext,
		   stamp.rand,
		  ],":")
    end
  end

  # Append the counter to the base to make a full stamp string
  def resource_format_string(base,counter) do
    base <> ":#{counter}"
  end

  # Count leading zero bits in a bitstring
  def count_lead_zeros_in_bitstring(bs, count \\ 0) do
    <<bh::size(1), rest::bitstring>> = bs
    if bh == 0 do
      count_lead_zeros_in_bitstring(rest,count+1)
    else
      count
    end
  end

  # Count leading zero bits in SHA1 hash of stamp.stamp_string
  def zero_bits_count(stamp) do
    count_lead_zeros_in_bitstring(:crypto.hash(:sha,stamp.stamp_string))
  end

  # Return %Hashcash with stamp_base and stamp_string set.
  def resource_format(stamp) do
    base = resource_format_base(stamp)
    %Hashcash{stamp | stamp_base: base,
	      stamp_string: resource_format_string(base,stamp.counter)}
  end

  # Validate the stamp string proof-of-work only. Use verify for full check
  def validate(stamp) do
    if zero_bits_count(stamp) == stamp.bits do
      {:ok}
    else
      {:error, :unproven}
    end
  end

  # Generate a full stamp, doing the work
  def generate(stamp) do
    generate(stamp,System.os_time(:milliseconds))
  end

  defp generate(stamp,began) do
    stamp = resource_format(stamp)
    case validate(stamp) do
      {:ok} ->
	stamp
      {:error, :unproven} ->
	generate(%Hashcash{stamp | counter: stamp.counter+1},began)
    end
  end
  
  @calendar_base :calendar.date_to_gregorian_days(1970,1,1)
  
  defp date_seconds([year: y, month: m, day: d]) do
    (:calendar.date_to_gregorian_days(y,m,d) - @calendar_base) * 86400
  end

  # Verify stamp resource is a valid resource
  def verify_resource(resource,valid_resources) do
    if resource in valid_resources do
      {:ok}
    else
      {:error, :resource_mismatch}
    end
  end

  # Verify date keyword list is within 2 days
  def verify_time(date) do
    if System.os_time(:seconds) - date_seconds(date) < 86400*2 do
      {:ok}
    else
      {:error, :resource_expired}
    end
  end

  # Verfiy all attributes and proof of work against a list of acceptable resources
  def verify(stamp = %Hashcash{},valid_resources = [_h|_t]) do
    with {:ok} <- verify_resource(stamp.resource,valid_resources),
	 {:ok} <- verify_time(stamp.date),
	 {:ok} <- validate(stamp), do: {:ok, :verified}
  end

  # Verfiy all attributes and proof of work against a single resources
  def verify(stamp = %Hashcash{},single_resource) do
    verify(stamp,[single_resource])
  end
end
