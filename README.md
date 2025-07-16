# Motoko LEB128 Encoder/Decoder

[![MOPS](https://img.shields.io/badge/MOPS-leb128-blue)](https://mops.one/leb128)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/edjcase/motoko_leb128/blob/main/LICENSE)

A Motoko library for encoding and decoding variable-length integers using the LEB128 (Little Endian Base 128) format. Supports both unsigned (ULEB128) and signed (SLEB128) variants with infinite precision.

## Package

### MOPS

```bash
mops add leb128
```

To set up MOPS package manager, follow the instructions from the [MOPS Site](https://mops.one)

## Quick Start

### Example 1: Unsigned LEB128 Encoding

```motoko
import LEB128 "mo:leb128";
import Debug "mo:base/Debug";

// Encode a number as unsigned LEB128
let value = 300;
let encoded = LEB128.toUnsignedBytes(value);
Debug.print(debug_show(encoded)); // Output: [172, 2]

// Common multicodec values
let sha256 = LEB128.toUnsignedBytes(0x12);
Debug.print(debug_show(sha256)); // Output: [18]
```

### Example 2: Unsigned LEB128 Decoding

```motoko
import LEB128 "mo:leb128";
import Result "mo:new-base/Result";
import Debug "mo:base/Debug";

// Decode unsigned LEB128 bytes
let bytes : [Nat8] = [172, 2]; // 300 encoded
let result = LEB128.fromUnsignedBytes(bytes.vals());

switch (result) {
  case (#ok(value)) {
    Debug.print("Decoded: " # debug_show(value)); // Output: 300
  };
  case (#err(error)) {
    Debug.print("Error: " # error);
  };
};
```

### Example 3: Signed LEB128 Encoding

```motoko
import LEB128 "mo:leb128";
import Debug "mo:base/Debug";

// Encode positive and negative numbers
let positive = LEB128.toSignedBytes(127);
Debug.print(debug_show(positive)); // Output: [255, 0]

let negative = LEB128.toSignedBytes(-1);
Debug.print(debug_show(negative)); // Output: [127]

let zero = LEB128.toSignedBytes(0);
Debug.print(debug_show(zero)); // Output: [0]
```

### Example 4: Signed LEB128 Decoding

```motoko
import LEB128 "mo:leb128";
import Result "mo:new-base/Result";
import Debug "mo:base/Debug";

// Decode signed LEB128 bytes
let negativeBytes : [Nat8] = [127]; // -1 encoded
let result = LEB128.fromSignedBytes(negativeBytes.vals());

switch (result) {
  case (#ok(value)) {
    Debug.print("Decoded: " # debug_show(value)); // Output: -1
  };
  case (#err(error)) {
    Debug.print("Error: " # error);
  };
};
```

### Example 5: Buffer Operations

```motoko
import LEB128 "mo:leb128";
import Buffer "mo:base/Buffer";

// Encode multiple values into a single buffer
let buffer = Buffer.Buffer<Nat8>(20);

// Add multiple LEB128 encoded values
LEB128.toUnsignedBytesBuffer(buffer, 300);
LEB128.toSignedBytesBuffer(buffer, -64);
```

### Example 6: Large Number Support

```motoko
import LEB128 "mo:leb128";
import Debug "mo:base/Debug";

// Works with arbitrarily large numbers
let largeNumber = 123456789012345678901234567890;
let encoded = LEB128.toUnsignedBytes(largeNumber);
Debug.print("Large number encoded: " # debug_show(encoded));

// Round-trip verification
let decoded = switch (LEB128.fromUnsignedBytes(encoded.vals())) {
  case (#ok(value)) value;
  case (#err(_)) 0;
};
Debug.print("Round-trip successful: " # debug_show(decoded == largeNumber));
```

## Use Cases

• **Multicodec/Multihash**: Encoding codec and hash identifiers
• **Protocol Buffers**: Variable-length integer encoding
• **DWARF Debug Info**: Encoding debug information
• **WebAssembly**: Encoding instruction operands and module data
• **Bitcoin**: Variable-length integer encoding in transactions
• **Efficient Serialization**: Compact representation of integers

## API Reference

### Unsigned LEB128 Functions

```motoko
// Convert a natural number to unsigned LEB128 bytes
public func toUnsignedBytes(n : Nat) : [Nat8];

// Convert a natural number to unsigned LEB128 bytes in a buffer
public func toUnsignedBytesBuffer(buffer : Buffer.Buffer<Nat8>, n : Nat);

// Decode unsigned LEB128 bytes to a natural number
public func fromUnsignedBytes(bytes : Iter.Iter<Nat8>) : Result.Result<Nat, Text>;
```

### Signed LEB128 Functions

```motoko
// Convert an integer to signed LEB128 bytes
public func toSignedBytes(n : Int) : [Nat8];

// Convert an integer to signed LEB128 bytes in a buffer
public func toSignedBytesBuffer(buffer : Buffer.Buffer<Nat8>, n : Int);

// Decode signed LEB128 bytes to an integer
public func fromSignedBytes(bytes : Iter.Iter<Nat8>) : Result.Result<Int, Text>;
```

## Format Details

**Unsigned LEB128 (ULEB128)**:

- Encodes non-negative integers
- Each byte uses 7 bits for data, 1 bit for continuation
- Most significant bit indicates if more bytes follow
- Little-endian byte order

**Signed LEB128 (SLEB128)**:

- Encodes signed integers using two's complement
- Same byte structure as unsigned variant
- Sign extension for proper negative number representation
- Supports infinite precision positive and negative values

## Testing

```bash
mops test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
