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

  @type t :: %Hashcash{}

  @stamp_version "1"

  @doc """
  Create a %Hashcash stamp from a stamp string. Use this to turn a string
  that may be passed between parties to a form that can be used with the
  rest of the functions here.
  """

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
	      counter: String.to_integer(counter),
	      stamp_string: stamp_string,
    }
  end
  
  @doc """
  Create a new %Hashcash with the resource_string and specified
  date Keyword list
  """
  @spec resource(resource_string :: String.t, date :: Keyword.t) :: t
  def resource(resource_string, date = [year: _y, month: _m, day: _d]),
    do: %Hashcash{resource: resource_string,
                  rand: rand_generate(),
                  date: date}

  @doc "Create a new %Hashcash with resource_string and today as the date."
  @spec resource(resource_string :: String.t) :: t
  def resource(resource_string),
    do: %Hashcash{resource: resource_string,
                  rand: rand_generate(),
                  date: date_now()}

  @doc "Modify the bits required of a %Hashcash"
  @spec resource_bits(hcash :: t, bits :: integer) :: t
  def resource_bits(hcash = %Hashcash{},bits) when is_integer(bits),
    do: %Hashcash{hcash | bits: bits}

  @doc "Modify the date of a %Hashcash"
  @spec resource_date(hcash :: t,
    y :: integer, m :: integer, d :: integer) :: t
  
  def resource_date(hcash, y, m, d) when is_integer(y) and is_integer(m) and is_integer(d) do
    %Hashcash{hcash | date: %{year: y, month: m, day: d}}
  end

  @spec strip_trailing_char(string :: String.t) :: String.t
  def strip_trailing_char(string) do
    slen = byte_size(string)-1
    <<core::binary-size(slen), _rest::binary>> = string
    core
  end

  @doc "Generate the rand field using a crypto.strong_rand_bytes"
  @spec rand_generate :: String.t
  def rand_generate do
    24
    |> :crypto.strong_rand_bytes
    |> Base.encode64
    |> strip_trailing_char # remove the trailing =
  end

  @doc "Set rand field of %Hashcash to newly generated string"
  @spec resource_rand(stamp :: t) :: t
  def resource_rand(hcash) do
    %Hashcash{hcash | rand: rand_generate()}
  end

  @doc "Generate date string section from date keywords list"
  @spec date_format(date_keywords :: Keyword.t) :: String.t
  def date_format(date_keywords) do
    [y,m,d] = Keyword.values(date_keywords)
    to_string(:io_lib.format("~2..0B~2..0B~2..0B", [rem(y,100),m,d]))
  end

  @doc "Generate date keywords list of now"
  @spec date_now :: Keyword.t
  def date_now do
    %{day: day, month: month, year: year} = DateTime.utc_now
    [year: year, month: month, day: day]
  end

  @doc """
  Generate or return hcash.base from properies
  This excludes the count field so that the generator can use this base
  with successive iterations of new counts by appending just the count.
  """

  @spec resource_format_base(hcash :: t) :: String.t
  def resource_format_base(hcash) do
    if base = hcash.stamp_base do
      base
    else
	      Enum.join([hcash.version,
		               hcash.bits,
		               date_format(hcash.date),
		               hcash.resource,
		               hcash.ext,
		               hcash.rand,
		              ],":")
    end
  end

  @doc "Append the counter to the base to make a full stamp string"
  @spec resource_format_string(base :: String.t ,counter :: integer) :: String.t
  def resource_format_string(base,counter) do
    base <> ":#{counter}"
  end

  @doc "Count leading zero bits in a bitstring"
  @spec count_lead_zeros_in_bitstring(bs :: String.t, count :: integer) :: integer
  def count_lead_zeros_in_bitstring(bs, count \\ 0) do
    <<bh::size(1), rest::bitstring>> = bs
    if bh == 0 do
      count_lead_zeros_in_bitstring(rest,count+1)
    else
      count
    end
  end

  @doc "Count leading zero bits in SHA1 hash of stamp.stamp_string"
  @spec zero_bits_count(hcash :: t) :: integer
  def zero_bits_count(hcash) do
    count_lead_zeros_in_bitstring(:crypto.hash(:sha,hcash.stamp_string))
  end

  @doc "Return %Hashcash with stamp_base and stamp_string set."
  @spec resource_format(hcash :: t) :: t
  def resource_format(hcash) do
    base = resource_format_base(hcash)
    %Hashcash{hcash | stamp_base: base,
	      stamp_string: resource_format_string(base,hcash.counter)}
  end

  @doc "Validate the stamp string proof-of-work only. Use verify for full check"
  @spec validate(hcash :: t) :: tuple
  def validate(hcash) do
    if zero_bits_count(hcash) >= hcash.bits do
      {:ok}
    else
      {:error, :unproven}
    end
  end

  @doc "Generate a full stamp, doing the work"
  @spec generate(hcash :: t) :: t
  def generate(hcash) do
    generate(hcash,System.os_time(:millisecond))
  end

  @spec generate(hcash :: t, began :: integer) :: t
  defp generate(hcash,began) do
    hcash = resource_format(hcash)
    case validate(hcash) do
      {:ok} ->
	      hcash
      {:error, :unproven} ->
	      generate(%Hashcash{hcash | counter: hcash.counter+1},began)
    end
  end
  
  @calendar_base :calendar.date_to_gregorian_days(1970,1,1)
  @spec date_seconds(Keyword.t) :: integer
  defp date_seconds([year: y, month: m, day: d]) do
    (:calendar.date_to_gregorian_days(y,m,d) - @calendar_base) * 86400
  end

  @doc "Verify stamp resource is a valid resource"
  @spec verify_resource(resource :: String.t, valid_resources :: list) :: tuple
  def verify_resource(resource,valid_resources) do
    if resource in valid_resources do
      {:ok}
    else
      {:error, :resource_mismatch}
    end
  end

  @doc "Verify date keyword list is within 2 days"
  @spec verify_time(date :: Keyword.t) :: tuple
  def verify_time(date) do
    if System.os_time(:second) - date_seconds(date) < 86400*2 do
      {:ok}
    else
      {:error, :resource_expired}
    end
  end

  @doc """
  Verfiy all attributes and proof of work against a list
  of acceptable resources or a single resource string
  """
  @spec verify(hcash :: t, valid_resources :: list) :: tuple
  def verify(hcash = %Hashcash{},valid_resources = [_h|_t]) do
    with {:ok} <- verify_resource(hcash.resource,valid_resources),
	 {:ok} <- verify_time(hcash.date),
	 {:ok} <- validate(hcash), do: {:ok, :verified}
  end

  @spec verify(hcash :: t, single_resource :: String.t) :: tuple
  def verify(hcash = %Hashcash{},single_resource) do
    verify(hcash,[single_resource])
  end
end
