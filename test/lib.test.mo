import Multiformats "../src"; // Adjust path to your multiformats module
import Debug "mo:base/Debug";
import { test } "mo:test";

func testLEB128(
  value : Nat,
  expectedBytes : [Nat8],
) {
  testLEB128Encoding(value, expectedBytes);
  testLEB128Decoding(expectedBytes, value);
  testLEB128Roundtrip(value);
};

func testLEB128Encoding(
  value : Nat,
  expectedBytes : [Nat8],
) {
  let actualBytes = Multiformats.LEB128.toBytes(value);

  if (actualBytes != expectedBytes) {
    Debug.trap(
      "LEB128 encoding mismatch for " # debug_show (value) #
      "\nExpected: " # debug_show (expectedBytes) #
      "\nActual:   " # debug_show (actualBytes)
    );
  };
};

func testLEB128Decoding(
  bytes : [Nat8],
  expectedValue : Nat,
) {
  let actualValue = switch (Multiformats.LEB128.fromBytes(bytes.vals())) {
    case (#ok(value)) value;
    case (#err(err)) Debug.trap("LEB128 decoding failed for: " # debug_show (bytes) # "\nError: " # err);
  };

  if (actualValue != expectedValue) {
    Debug.trap(
      "LEB128 decoding mismatch for " # debug_show (bytes) #
      "\nExpected: " # debug_show (expectedValue) #
      "\nActual:   " # debug_show (actualValue)
    );
  };
};

func testLEB128Roundtrip(value : Nat) {
  let encoded = Multiformats.LEB128.toBytes(value);
  let decoded = switch (Multiformats.LEB128.fromBytes(encoded.vals())) {
    case (#ok(value)) value;
    case (#err(err)) Debug.trap("Round-trip decode failed for: " # debug_show (value) # "\nError: " # err);
  };

  if (decoded != value) {
    Debug.trap(
      "LEB128 round-trip mismatch for " # debug_show (value) #
      "\nOriginal: " # debug_show (value) #
      "\nDecoded:  " # debug_show (decoded)
    );
  };
};

func testLEB128Error(invalidBytes : [Nat8]) {
  switch (Multiformats.LEB128.fromBytes(invalidBytes.vals())) {
    case (#ok(value)) Debug.trap("Expected LEB128 decode error for " # debug_show (invalidBytes) # " but got: " # debug_show (value));
    case (#err(_)) {}; // Expected error
  };
};

// =============================================================================
// Single Byte Values (0-127)
// =============================================================================

test(
  "LEB128: Single byte values",
  func() {
    testLEB128(0, [0x00]);
    testLEB128(1, [0x01]);
    testLEB128(127, [0x7F]);
  },
);

// =============================================================================
// Two Byte Values (128-16383)
// =============================================================================

test(
  "LEB128: Two byte values",
  func() {
    testLEB128(128, [0x80, 0x01]);
    testLEB128(129, [0x81, 0x01]);
    testLEB128(300, [0xAC, 0x02]);
    testLEB128(16383, [0xFF, 0x7F]);
  },
);

// =============================================================================
// Three Byte Values (16384+)
// =============================================================================

test(
  "LEB128: Three byte values",
  func() {
    testLEB128(16384, [0x80, 0x80, 0x01]);
    testLEB128(65536, [0x80, 0x80, 0x04]);
    testLEB128(2097151, [0xFF, 0xFF, 0x7F]);
  },
);

// =============================================================================
// Multicodec Examples (Real-world values)
// =============================================================================

test(
  "LEB128: Multicodec values",
  func() {
    // Common multicodec values
    testLEB128(0x12, [0x12]); // SHA-256
    testLEB128(0x55, [0x55]); // Raw
    testLEB128(0x70, [0x70]); // DAG-PB
    testLEB128(0x71, [0x71]); // DAG-CBOR
    testLEB128(0xed, [0xED, 0x01]); // Ed25519 public key
    testLEB128(0xe7, [0xE7, 0x01]); // secp256k1 public key
    testLEB128(0x1200, [0x80, 0x24]); // P-256 public key
    testLEB128(0xb220, [0xA0, 0xE4, 0x02]); // Blake2b-256
  },
);

// =============================================================================
// Large Values
// =============================================================================

test(
  "LEB128: Large values",
  func() {
    testLEB128(268435455, [0xFF, 0xFF, 0xFF, 0x7F]); // 4 bytes
    testLEB128(1000000, [0xC0, 0x84, 0x3D]); // 1 million
    testLEB128(4294967295, [0xFF, 0xFF, 0xFF, 0xFF, 0x0F]); // Max 32-bit
  },
);

// =============================================================================
// Round-trip Edge Cases
// =============================================================================

test(
  "LEB128: Round-trip edge cases",
  func() {
    testLEB128Roundtrip(0);
    testLEB128Roundtrip(127);
    testLEB128Roundtrip(128);
    testLEB128Roundtrip(16383);
    testLEB128Roundtrip(16384);
    testLEB128Roundtrip(2097151);
    testLEB128Roundtrip(2097152);
    testLEB128Roundtrip(268435455);
  },
);

// =============================================================================
// Error Cases
// =============================================================================

test(
  "LEB128: Error cases",
  func() {
    // Empty input
    testLEB128Error([]);

    // Incomplete LEB128 (missing continuation)
    testLEB128Error([0x80]); // Indicates more bytes but none follow
    testLEB128Error([0x80, 0x80]); // Still incomplete
  },
);

// =============================================================================
// Protocol Buffer Compatibility Examples
// =============================================================================

test(
  "LEB128: Protocol Buffer compatibility",
  func() {
    // These should match protobuf LEB128 encoding
    testLEB128(1, [0x01]);
    testLEB128(150, [0x96, 0x01]);
    testLEB128(3, [0x03]);
    testLEB128(270, [0x8E, 0x02]);
    testLEB128(86942, [0x9E, 0xA7, 0x05]);
  },
);

// =============================================================================
// Boundary Values
// =============================================================================

test(
  "LEB128: Boundary values",
  func() {
    // Powers of 2 minus 1 (common boundaries)
    testLEB128(127, [0x7F]); // 2^7 - 1
    testLEB128(128, [0x80, 0x01]); // 2^7
    testLEB128(16383, [0xFF, 0x7F]); // 2^14 - 1
    testLEB128(16384, [0x80, 0x80, 0x01]); // 2^14

    // Multicodec boundary cases
    testLEB128(255, [0xFF, 0x01]); // One byte in most systems
    testLEB128(256, [0x80, 0x02]); // Two bytes needed
  },
);
