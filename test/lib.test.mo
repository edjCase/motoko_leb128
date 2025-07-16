import LEB128 "../src"; // Adjust path to your multiformats module
import Debug "mo:base/Debug";
import { test } "mo:test";

// =============================================================================
// Unsigned Test Functions
// =============================================================================

func testUnsignedLEB128(
  value : Nat,
  expectedBytes : [Nat8],
) {
  testUnsignedLEB128Encoding(value, expectedBytes);
  testUnsignedLEB128Decoding(expectedBytes, value);
  testUnsignedLEB128Roundtrip(value);
};

func testUnsignedLEB128Encoding(
  value : Nat,
  expectedBytes : [Nat8],
) {
  let actualBytes = LEB128.toUnsignedBytes(value);

  if (actualBytes != expectedBytes) {
    Debug.trap(
      "Unsigned LEB128 encoding mismatch for " # debug_show (value) #
      "\nExpected: " # debug_show (expectedBytes) #
      "\nActual:   " # debug_show (actualBytes)
    );
  };
};

func testUnsignedLEB128Decoding(
  bytes : [Nat8],
  expectedValue : Nat,
) {
  let actualValue = switch (LEB128.fromUnsignedBytes(bytes.vals())) {
    case (#ok(value)) value;
    case (#err(err)) Debug.trap("Unsigned LEB128 decoding failed for: " # debug_show (bytes) # "\nError: " # err);
  };

  if (actualValue != expectedValue) {
    Debug.trap(
      "Unsigned LEB128 decoding mismatch for " # debug_show (bytes) #
      "\nExpected: " # debug_show (expectedValue) #
      "\nActual:   " # debug_show (actualValue)
    );
  };
};

func testUnsignedLEB128Roundtrip(value : Nat) {
  let encoded = LEB128.toUnsignedBytes(value);
  let decoded = switch (LEB128.fromUnsignedBytes(encoded.vals())) {
    case (#ok(value)) value;
    case (#err(err)) Debug.trap("Unsigned round-trip decode failed for: " # debug_show (value) # "\nError: " # err);
  };

  if (decoded != value) {
    Debug.trap(
      "Unsigned LEB128 round-trip mismatch for " # debug_show (value) #
      "\nOriginal: " # debug_show (value) #
      "\nDecoded:  " # debug_show (decoded)
    );
  };
};

// =============================================================================
// Signed Test Functions
// =============================================================================

func testSignedLEB128(
  value : Int,
  expectedBytes : [Nat8],
) {
  testSignedLEB128Encoding(value, expectedBytes);
  testSignedLEB128Decoding(expectedBytes, value);
  testSignedLEB128Roundtrip(value);
};

func testSignedLEB128Encoding(
  value : Int,
  expectedBytes : [Nat8],
) {
  let actualBytes = LEB128.toSignedBytes(value);

  if (actualBytes != expectedBytes) {
    Debug.trap(
      "Signed LEB128 encoding mismatch for " # debug_show (value) #
      "\nExpected: " # debug_show (expectedBytes) #
      "\nActual:   " # debug_show (actualBytes)
    );
  };
};

func testSignedLEB128Decoding(
  bytes : [Nat8],
  expectedValue : Int,
) {
  let actualValue = switch (LEB128.fromSignedBytes(bytes.vals())) {
    case (#ok(value)) value;
    case (#err(err)) Debug.trap("Signed LEB128 decoding failed for: " # debug_show (bytes) # "\nError: " # err);
  };

  if (actualValue != expectedValue) {
    Debug.trap(
      "Signed LEB128 decoding mismatch for " # debug_show (bytes) #
      "\nExpected: " # debug_show (expectedValue) #
      "\nActual:   " # debug_show (actualValue)
    );
  };
};

func testSignedLEB128Roundtrip(value : Int) {
  let encoded = LEB128.toSignedBytes(value);
  let decoded = switch (LEB128.fromSignedBytes(encoded.vals())) {
    case (#ok(value)) value;
    case (#err(err)) Debug.trap("Signed round-trip decode failed for: " # debug_show (value) # "\nError: " # err);
  };

  if (decoded != value) {
    Debug.trap(
      "Signed LEB128 round-trip mismatch for " # debug_show (value) #
      "\nOriginal: " # debug_show (value) #
      "\nDecoded:  " # debug_show (decoded)
    );
  };
};

// =============================================================================
// Error Test Functions
// =============================================================================

func testUnsignedLEB128Error(invalidBytes : [Nat8]) {
  switch (LEB128.fromUnsignedBytes(invalidBytes.vals())) {
    case (#ok(value)) Debug.trap("Expected unsigned LEB128 decode error for " # debug_show (invalidBytes) # " but got: " # debug_show (value));
    case (#err(_)) {}; // Expected error
  };
};

func testSignedLEB128Error(invalidBytes : [Nat8]) {
  switch (LEB128.fromSignedBytes(invalidBytes.vals())) {
    case (#ok(value)) Debug.trap("Expected signed LEB128 decode error for " # debug_show (invalidBytes) # " but got: " # debug_show (value));
    case (#err(_)) {}; // Expected error
  };
};

// =============================================================================
// Unsigned LEB128 Tests
// =============================================================================

test(
  "Unsigned LEB128: Single byte values",
  func() {
    testUnsignedLEB128(0, [0x00]);
    testUnsignedLEB128(1, [0x01]);
    testUnsignedLEB128(127, [0x7F]);
  },
);

test(
  "Unsigned LEB128: Two byte values",
  func() {
    testUnsignedLEB128(128, [0x80, 0x01]);
    testUnsignedLEB128(129, [0x81, 0x01]);
    testUnsignedLEB128(300, [0xAC, 0x02]);
    testUnsignedLEB128(16383, [0xFF, 0x7F]);
  },
);

test(
  "Unsigned LEB128: Three byte values",
  func() {
    testUnsignedLEB128(16384, [0x80, 0x80, 0x01]);
    testUnsignedLEB128(65536, [0x80, 0x80, 0x04]);
    testUnsignedLEB128(2097151, [0xFF, 0xFF, 0x7F]);
  },
);

test(
  "Unsigned LEB128: Multicodec values",
  func() {
    testUnsignedLEB128(0x12, [0x12]); // SHA-256
    testUnsignedLEB128(0x55, [0x55]); // Raw
    testUnsignedLEB128(0x70, [0x70]); // DAG-PB
    testUnsignedLEB128(0x71, [0x71]); // DAG-CBOR
    testUnsignedLEB128(0xed, [0xED, 0x01]); // Ed25519 public key
    testUnsignedLEB128(0xe7, [0xE7, 0x01]); // secp256k1 public key
    testUnsignedLEB128(0x1200, [0x80, 0x24]); // P-256 public key
    testUnsignedLEB128(0xb220, [0xA0, 0xE4, 0x02]); // Blake2b-256
  },
);

test(
  "Unsigned LEB128: Large values",
  func() {
    testUnsignedLEB128(268435455, [0xFF, 0xFF, 0xFF, 0x7F]); // 4 bytes
    testUnsignedLEB128(1000000, [0xC0, 0x84, 0x3D]); // 1 million
    testUnsignedLEB128(4294967295, [0xFF, 0xFF, 0xFF, 0xFF, 0x0F]); // Max 32-bit
  },
);

test(
  "Unsigned LEB128: Round-trip edge cases",
  func() {
    testUnsignedLEB128Roundtrip(0);
    testUnsignedLEB128Roundtrip(127);
    testUnsignedLEB128Roundtrip(128);
    testUnsignedLEB128Roundtrip(16383);
    testUnsignedLEB128Roundtrip(16384);
    testUnsignedLEB128Roundtrip(2097151);
    testUnsignedLEB128Roundtrip(2097152);
    testUnsignedLEB128Roundtrip(268435455);
  },
);

test(
  "Unsigned LEB128: Protocol Buffer compatibility",
  func() {
    testUnsignedLEB128(1, [0x01]);
    testUnsignedLEB128(150, [0x96, 0x01]);
    testUnsignedLEB128(3, [0x03]);
    testUnsignedLEB128(270, [0x8E, 0x02]);
    testUnsignedLEB128(86942, [0x9E, 0xA7, 0x05]);
  },
);

test(
  "Unsigned LEB128: Boundary values",
  func() {
    testUnsignedLEB128(127, [0x7F]); // 2^7 - 1
    testUnsignedLEB128(128, [0x80, 0x01]); // 2^7
    testUnsignedLEB128(16383, [0xFF, 0x7F]); // 2^14 - 1
    testUnsignedLEB128(16384, [0x80, 0x80, 0x01]); // 2^14
    testUnsignedLEB128(255, [0xFF, 0x01]); // One byte in most systems
    testUnsignedLEB128(256, [0x80, 0x02]); // Two bytes needed
  },
);

// =============================================================================
// Signed LEB128 Tests
// =============================================================================

test(
  "Signed LEB128: Positive single byte values",
  func() {
    testSignedLEB128(0, [0x00]);
    testSignedLEB128(1, [0x01]);
    testSignedLEB128(63, [0x3F]); // Largest positive in 1 byte
  },
);

test(
  "Signed LEB128: Negative single byte values",
  func() {
    testSignedLEB128(-1, [0x7F]);
    testSignedLEB128(-2, [0x7E]);
    testSignedLEB128(-64, [0x40]); // Smallest negative in 1 byte
  },
);

test(
  "Signed LEB128: Positive multi-byte values",
  func() {
    testSignedLEB128(64, [0xC0, 0x00]); // Need 2 bytes
    testSignedLEB128(127, [0xFF, 0x00]);
    testSignedLEB128(128, [0x80, 0x01]);
    testSignedLEB128(8191, [0xFF, 0x3F]); // 2^13 - 1
    testSignedLEB128(8192, [0x80, 0xC0, 0x00]); // 2^13
  },
);

test(
  "Signed LEB128: Negative multi-byte values",
  func() {
    testSignedLEB128(-65, [0xBF, 0x7F]); // Need 2 bytes
    testSignedLEB128(-128, [0x80, 0x7F]);
    testSignedLEB128(-129, [0xFF, 0x7E]);
    testSignedLEB128(-8192, [0x80, 0x40]); // -2^13
    testSignedLEB128(-8193, [0xFF, 0xBF, 0x7F]); // -2^13 - 1
  },
);

test(
  "Signed LEB128: Large positive values",
  func() {
    testSignedLEB128(1000000, [0xC0, 0x84, 0xBD, 0x00]);
    testSignedLEB128(2147483647, [0xFF, 0xFF, 0xFF, 0xFF, 0x07]); // Max 32-bit signed
  },
);

test(
  "Signed LEB128: Large negative values",
  func() {
    testSignedLEB128(-1000000, [0xC0, 0xFB, 0xC2, 0x7F]);
    testSignedLEB128(-2147483648, [0x80, 0x80, 0x80, 0x80, 0x78]); // Min 32-bit signed
  },
);

test(
  "Signed LEB128: Round-trip edge cases",
  func() {
    testSignedLEB128Roundtrip(0);
    testSignedLEB128Roundtrip(63);
    testSignedLEB128Roundtrip(64);
    testSignedLEB128Roundtrip(-1);
    testSignedLEB128Roundtrip(-64);
    testSignedLEB128Roundtrip(-65);
    testSignedLEB128Roundtrip(8191);
    testSignedLEB128Roundtrip(8192);
    testSignedLEB128Roundtrip(-8192);
    testSignedLEB128Roundtrip(-8193);
  },
);

test(
  "Signed LEB128: DWARF compatibility",
  func() {
    // Common DWARF LEB128 values
    testSignedLEB128(2, [0x02]);
    testSignedLEB128(-2, [0x7E]);
    testSignedLEB128(127, [0xFF, 0x00]);
    testSignedLEB128(-127, [0x81, 0x7F]);
    testSignedLEB128(128, [0x80, 0x01]);
    testSignedLEB128(-128, [0x80, 0x7F]);
  },
);

// =============================================================================
// Error Cases
// =============================================================================

test(
  "LEB128: Error cases",
  func() {
    // Empty input
    testUnsignedLEB128Error([]);
    testSignedLEB128Error([]);

    // Incomplete LEB128 (missing continuation)
    testUnsignedLEB128Error([0x80]); // Indicates more bytes but none follow
    testUnsignedLEB128Error([0x80, 0x80]); // Still incomplete
    testSignedLEB128Error([0x80]); // Indicates more bytes but none follow
    testSignedLEB128Error([0x80, 0x80]); // Still incomplete
  },
);
