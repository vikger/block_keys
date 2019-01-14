defmodule BlockKeys.Bip32Mnemonic do
  @pad_length_mnemonic 8
  @pad_length_phrase 11

  def generate_phrase do
    entropy = SecureRandom.random_bytes(32)

    entropy
      |> entropy_hash()
      |> extract_checksum()
      |> append_checksum(entropy)
      |> :binary.bin_to_list()
      |> Enum.map(fn byte -> to_bitstring(byte, @pad_length_mnemonic) end)
      |> Enum.join()
      |> mnemonic()
  end

  # hash the initial entropy
  defp entropy_hash(sequence), do: :libsecp256k1.sha256(sequence)

  # extract the first byte (8bits)
  defp extract_checksum(<< checksum :: size(8), _bits :: bitstring >>), do: checksum

  # append the checksum to initial entropy
  defp append_checksum(checksum, entropy), do: entropy <> << checksum >>

  # convert a byte to a bitstring (8bits)
  def to_bitstring(byte, pad_length) do
    byte
    |> Integer.to_string(2)
    |> String.pad_leading(pad_length, "0")
  end

  # split the 264bit string into groups of 11, convert to base 10 integer, map it to word list
  def mnemonic(entropy) do
    Regex.scan(~r/.{11}/, entropy)
    |> List.flatten()
    |> Enum.map(fn binary -> 
      word_index(binary, words())
    end)
    |> Enum.join(" ")
  end

  def word_index(binary, words) do
    binary
    |> String.to_integer(2)
    |> element_at_index(words)
  end

  defp element_at_index(index, words), do: Kernel.elem(words, index)

  def words do
    "./assets/english.txt"
    |> File.stream!
    |> Stream.map(&String.trim/1)
    |> Enum.to_list
    |> List.to_tuple
  end

  # convert the phrase to entropy
  def entropy_from_phrase(phrase) do
    phrase
    |> phrase_to_list
    |> word_indexes(words())
    |> Enum.map(fn index -> to_bitstring(index, @pad_length_phrase) end)
    |> Enum.join()
    |> remove_checksum
    |> entropy()
  end

  def entropy(bitstring) do
    Regex.scan(~r/.{8}/, bitstring)
    |> List.flatten
    |> Enum.map(&String.to_integer(&1, 2))
    |> :binary.list_to_bin()
  end

  def remove_checksum(bitstring), do: String.slice(bitstring, 0..255)

  def phrase_to_list(phrase) do
    phrase
    |> String.split()
    |> Enum.map(&String.trim/1)
  end

  def word_indexes(phrase_list, words) do
    phrase_list
    |> Enum.map(fn phrase_word ->
      words
      |> Tuple.to_list
      |> Enum.find_index(fn el -> el === phrase_word end)
    end)
  end
end
