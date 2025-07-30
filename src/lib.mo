import Nat "mo:core/Nat";
import Int "mo:core/Int";
import Iter "mo:core/Iter";
import Nat8 "mo:core/Nat8";
import Result "mo:core/Result";
import List "mo:core/List";
import Buffer "mo:buffer";

module {

  /// Decodes an unsigned variable-length integer from a byte iterator.
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [0xAC, 0x02]; // 300 encoded as unsigned LEB128
  /// let ?value = LEB128.fromUnsignedBytes(bytes.vals()); // Returns: 300
  /// ```
  public func fromUnsignedBytes(bytes : Iter.Iter<Nat8>) : Result.Result<Nat, Text> {
    var result : Nat = 0;
    var shift : Nat = 0;
    var bytesRead = 0;

    for (byte in bytes) {
      let byteValue = Nat8.toNat(byte);
      let dataBits = byteValue % 128; // Get lower 7 bits

      // Add this byte's contribution: dataBits * (2^shift)
      let contribution = dataBits * (2 ** shift);
      result := result + contribution;
      bytesRead += 1;

      if (byteValue < 128) {
        return #ok(result);
      };
      shift += 7;
    };
    #err("Unexpected end of bytes");
  };

  /// Decodes a signed variable-length integer from a byte iterator.
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [0x7F]; // -1 encoded as signed LEB128
  /// let ?value = LEB128.fromSignedBytes(bytes.vals()); // Returns: -1
  /// ```
  public func fromSignedBytes(bytes : Iter.Iter<Nat8>) : Result.Result<Int, Text> {
    var result : Int = 0;
    var shift : Nat = 0;
    var bytesRead = 0;
    var byte : Nat8 = 0;

    for (b in bytes) {
      byte := b;
      let byteValue = Nat8.toNat(byte);
      let dataBits = byteValue % 128; // Get lower 7 bits

      // Add this byte's contribution: dataBits * (2^shift)
      let contribution = dataBits * (2 ** shift);
      result := result + contribution;
      bytesRead += 1;

      if (byte < 128) {
        // Last byte - check if sign extension needed
        if (dataBits >= 64) {
          // Bit 6 set means negative
          // Sign extend: subtract 2^(shift+7) to make negative
          let signExtension = 2 ** (shift + 7);
          result := result - signExtension;
        };
        return #ok(result);
      };
      shift += 7;
    };
    #err("Unexpected end of bytes");
  };

  /// Encodes an unsigned natural number as a variable-length integer.
  ///
  /// ```motoko
  /// let encoded = LEB128.toUnsignedBytes(300);
  /// // Returns: [0xAC, 0x02]
  /// ```
  public func toUnsignedBytes(n : Nat) : [Nat8] {
    let list = List.empty<Nat8>();
    toUnsignedBytesBuffer(Buffer.fromList<Nat8>(list), n);
    List.toArray(list);
  };

  /// Encodes a signed integer as a variable-length integer.
  ///
  /// ```motoko
  /// let encoded = LEB128.toSignedBytes(-1);
  /// // Returns: [0x7F]
  /// ```
  public func toSignedBytes(n : Int) : [Nat8] {
    let list = List.empty<Nat8>();
    toSignedBytesBuffer(Buffer.fromList<Nat8>(list), n);
    List.toArray(list);
  };

  /// Encodes an unsigned natural number as a variable-length integer into a buffer.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// LEB128.toUnsignedBytesBuffer(buffer, 300);
  /// // buffer now contains: [0xAC, 0x02]
  /// ```
  public func toUnsignedBytesBuffer(buffer : Buffer.Buffer<Nat8>, n : Nat) {
    var value = n;

    while (value >= 128) {
      buffer.write(Nat8.fromNat((value % 128) + 128));
      value := value / 128;
    };
    buffer.write(Nat8.fromNat(value));
  };

  /// Encodes a signed integer as a variable-length integer into a buffer.
  /// Works with infinite precision integers.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(10);
  /// LEB128.toSignedBytesBuffer(buffer, -1);
  /// // buffer now contains: [0x7F]
  /// ```
  public func toSignedBytesBuffer(buffer : Buffer.Buffer<Nat8>, n : Int) {
    var value = n;

    label w while (true) {
      // Get the 7 least significant bits
      var byte = value % 128;
      if (byte < 0) {
        byte := byte + 128; // Handle negative modulo
      };

      // Arithmetic right shift by 7 bits (floor division)
      value := if (value >= 0) {
        value / 128;
      } else {
        (value - 127) / 128 // Proper arithmetic right shift for negative
      };

      // Check if this is the last byte
      // For positive: value == 0 and bit 6 clear (byte < 64)
      // For negative: value == -1 and bit 6 set (byte >= 64)
      if ((value == 0 and byte < 64) or (value == -1 and byte >= 64)) {
        // Last byte - no continuation bit
        buffer.write(Nat8.fromNat(Int.abs(byte)));
        break w;
      } else {
        // Not last byte - add continuation bit
        buffer.write(Nat8.fromNat(Int.abs(byte + 128)));
      };
    };
  };
};
