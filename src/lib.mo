import Nat "mo:new-base/Nat";
import Int "mo:new-base/Int";
import Iter "mo:new-base/Iter";
import Nat8 "mo:new-base/Nat8";
import Nat16 "mo:new-base/Nat16";
import Nat32 "mo:new-base/Nat32";
import Nat64 "mo:new-base/Nat64";
import Int64 "mo:new-base/Int64";
import Result "mo:new-base/Result";
import Buffer "mo:base/Buffer";

module {

    /// Decodes an unsigned variable-length integer from a byte iterator.
    ///
    /// ```motoko
    /// let bytes : [Nat8] = [0xAC, 0x02]; // 300 encoded as unsigned LEB128
    /// let ?value = LEB128.fromUnsignedBytes(bytes.vals()); // Returns: 300
    /// ```
    public func fromUnsignedBytes(bytes : Iter.Iter<Nat8>) : Result.Result<Nat, Text> {
        var result : Nat64 = 0;
        var shift : Nat64 = 0;
        var bytesRead = 0;

        for (byte in bytes) {
            let byte32 = Nat64.fromNat(Nat8.toNat(byte));
            result := result + ((byte32 % 128) << shift);
            bytesRead += 1;

            if (byte32 < 128) {
                return #ok(Nat64.toNat(result));
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
        var result : Int64 = 0;
        var shift : Int64 = 0;
        var bytesRead = 0;
        var byte : Nat8 = 0;

        for (b in bytes) {
            byte := b;
            let byte64 = Int64.fromNat64(Nat64.fromNat(Nat8.toNat(byte)));
            result := result + ((byte64 % 128) << shift);
            bytesRead += 1;

            if (byte < 128) {
                // Sign extend if the sign bit is set
                if (shift < 64 and (byte & 0x40) != 0) {
                    result := result | ((-1 : Int64) << (shift + 7));
                };
                return #ok(Int64.toInt(result));
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
        let buffer = Buffer.Buffer<Nat8>(10);
        toUnsignedBytesBuffer(buffer, n);
        Buffer.toArray(buffer);
    };

    /// Encodes a signed integer as a variable-length integer.
    ///
    /// ```motoko
    /// let encoded = LEB128.toSignedBytes(-1);
    /// // Returns: [0x7F]
    /// ```
    public func toSignedBytes(n : Int) : [Nat8] {
        let buffer = Buffer.Buffer<Nat8>(10);
        toSignedBytesBuffer(buffer, n);
        Buffer.toArray(buffer);
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
            buffer.add(Nat8.fromNat((value % 128) + 128));
            value := value / 128;
        };
        buffer.add(Nat8.fromNat(value));
    };

    /// Encodes a signed integer as a variable-length integer into a buffer.
    ///
    /// ```motoko
    /// let buffer = Buffer.Buffer<Nat8>(10);
    /// LEB128.toSignedBytesBuffer(buffer, -1);
    /// // buffer now contains: [0x7F]
    /// ```
    public func toSignedBytesBuffer(buffer : Buffer.Buffer<Nat8>, n : Int) {
        var value = Int64.fromInt(n);

        func nat64To8(value : Nat64) : Nat8 = Nat8.fromNat16(Nat16.fromNat32(Nat32.fromNat64(value)));

        label w while (true) {
            let byte = value & 0x7F; // Get the 7 least significant bits
            let byteNat = if (byte >= 0) Int64.toNat64(byte) else Int64.toNat64(byte + 128);
            value := Int64.bitshiftRight(value, 7);
            // Check if this is the last byte
            if ((value == 0 and (byteNat & 0x40) == 0) or (value == -1 and (byteNat & 0x40) != 0)) {
                // Last byte - no continuation bit
                buffer.add(nat64To8(byteNat));
                break w;
            } else {
                // Not last byte - add continuation bit
                buffer.add(nat64To8(byteNat | 0x80));
            };
        };
    };
};
