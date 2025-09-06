import LEB128 "../src";
import { test } "mo:test";
import Blob "mo:core@1/Blob";
import Runtime "mo:core@1/Runtime";

// =============================================================================
// Unsigned Test Functions
// =============================================================================

func testUnsignedLEB128(
  value : Nat,
  expectedBytes : Blob,
) {
  testUnsignedLEB128Encoding(value, expectedBytes);
  testUnsignedLEB128Decoding(expectedBytes, value);
  testUnsignedLEB128Roundtrip(value);
};

func testUnsignedLEB128Encoding(
  value : Nat,
  expectedBytes : Blob,
) {
  let actualBytes = Blob.fromArray(LEB128.toUnsignedBytes(value));

  if (actualBytes != expectedBytes) {
    Runtime.trap(
      "Unsigned LEB128 encoding mismatch for " # debug_show (value) #
      "\nExpected: " # debug_show (expectedBytes) #
      "\nActual:   " # debug_show (actualBytes)
    );
  };
};

func testUnsignedLEB128Decoding(
  bytes : Blob,
  expectedValue : Nat,
) {
  let actualValue = switch (LEB128.fromUnsignedBytes(bytes.vals())) {
    case (#ok(value)) value;
    case (#err(err)) Runtime.trap("Unsigned LEB128 decoding failed for: " # debug_show (bytes) # "\nError: " # err);
  };

  if (actualValue != expectedValue) {
    Runtime.trap(
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
    case (#err(err)) Runtime.trap("Unsigned round-trip decode failed for: " # debug_show (value) # "\nError: " # err);
  };

  if (decoded != value) {
    Runtime.trap(
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
  expectedBytes : Blob,
) {
  testSignedLEB128Encoding(value, expectedBytes);
  testSignedLEB128Decoding(expectedBytes, value);
  testSignedLEB128Roundtrip(value);
};

func testSignedLEB128Encoding(
  value : Int,
  expectedBytes : Blob,
) {
  let actualBytes = Blob.fromArray(LEB128.toSignedBytes(value));

  if (actualBytes != expectedBytes) {
    Runtime.trap(
      "Signed LEB128 encoding mismatch for " # debug_show (value) #
      "\nExpected: " # debug_show (expectedBytes) #
      "\nActual:   " # debug_show (actualBytes)
    );
  };
};

func testSignedLEB128Decoding(
  bytes : Blob,
  expectedValue : Int,
) {
  let actualValue = switch (LEB128.fromSignedBytes(bytes.vals())) {
    case (#ok(value)) value;
    case (#err(err)) Runtime.trap("Signed LEB128 decoding failed for: " # debug_show (bytes) # "\nError: " # err);
  };

  if (actualValue != expectedValue) {
    Runtime.trap(
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
    case (#err(err)) Runtime.trap("Signed round-trip decode failed for: " # debug_show (value) # "\nError: " # err);
  };

  if (decoded != value) {
    Runtime.trap(
      "Signed LEB128 round-trip mismatch for " # debug_show (value) #
      "\nOriginal: " # debug_show (value) #
      "\nDecoded:  " # debug_show (decoded)
    );
  };
};

// =============================================================================
// Error Test Functions
// =============================================================================

func testUnsignedLEB128Error(invalidBytes : Blob) {
  switch (LEB128.fromUnsignedBytes(invalidBytes.vals())) {
    case (#ok(value)) Runtime.trap("Expected unsigned LEB128 decode error for " # debug_show (invalidBytes) # " but got: " # debug_show (value));
    case (#err(_)) {}; // Expected error
  };
};

func testSignedLEB128Error(invalidBytes : Blob) {
  switch (LEB128.fromSignedBytes(invalidBytes.vals())) {
    case (#ok(value)) Runtime.trap("Expected signed LEB128 decode error for " # debug_show (invalidBytes) # " but got: " # debug_show (value));
    case (#err(_)) {}; // Expected error
  };
};

// =============================================================================
// Unsigned LEB128 Tests
// =============================================================================

test(
  "Unsigned LEB128: Single byte values",
  func() {
    testUnsignedLEB128(0, "\00");
    testUnsignedLEB128(1, "\01");
    testUnsignedLEB128(127, "\7F");
  },
);

test(
  "Unsigned LEB128: Two byte values",
  func() {
    testUnsignedLEB128(128, "\80\01");
    testUnsignedLEB128(129, "\81\01");
    testUnsignedLEB128(300, "\AC\02");
    testUnsignedLEB128(16383, "\FF\7F");
  },
);

test(
  "Unsigned LEB128: Three byte values",
  func() {
    testUnsignedLEB128(16384, "\80\80\01");
    testUnsignedLEB128(65536, "\80\80\04");
    testUnsignedLEB128(2097151, "\FF\FF\7F");
  },
);

test(
  "Unsigned LEB128: Multicodec values",
  func() {
    testUnsignedLEB128(0x12, "\12"); // SHA-256
    testUnsignedLEB128(0x55, "\55"); // Raw
    testUnsignedLEB128(0x70, "\70"); // DAG-PB
    testUnsignedLEB128(0x71, "\71"); // DAG-CBOR
    testUnsignedLEB128(0xed, "\ED\01"); // Ed25519 public key
    testUnsignedLEB128(0xe7, "\E7\01"); // secp256k1 public key
    testUnsignedLEB128(0x1200, "\80\24"); // P-256 public key
    testUnsignedLEB128(0xb220, "\A0\E4\02"); // Blake2b-256
  },
);

test(
  "Unsigned LEB128: Large values",
  func() {
    testUnsignedLEB128(268435455, "\FF\FF\FF\7F"); // 4 bytes
    testUnsignedLEB128(1000000, "\C0\84\3D"); // 1 million
    testUnsignedLEB128(4294967295, "\FF\FF\FF\FF\0F"); // Max 32-bit
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
    testUnsignedLEB128(1, "\01");
    testUnsignedLEB128(150, "\96\01");
    testUnsignedLEB128(3, "\03");
    testUnsignedLEB128(270, "\8E\02");
    testUnsignedLEB128(86942, "\9E\A7\05");
  },
);

test(
  "Unsigned LEB128: Boundary values",
  func() {
    testUnsignedLEB128(127, "\7F"); // 2^7 - 1
    testUnsignedLEB128(128, "\80\01"); // 2^7
    testUnsignedLEB128(16383, "\FF\7F"); // 2^14 - 1
    testUnsignedLEB128(16384, "\80\80\01"); // 2^14
    testUnsignedLEB128(255, "\FF\01"); // One byte in most systems
    testUnsignedLEB128(256, "\80\02"); // Two bytes needed
  },
);

// =============================================================================
// Signed LEB128 Tests
// =============================================================================

test(
  "Signed LEB128: Positive single byte values",
  func() {
    testSignedLEB128(0, "\00");
    testSignedLEB128(1, "\01");
    testSignedLEB128(63, "\3F"); // Largest positive in 1 byte
  },
);

test(
  "Signed LEB128: Negative single byte values",
  func() {
    testSignedLEB128(-1, "\7F");
    testSignedLEB128(-2, "\7E");
    testSignedLEB128(-64, "\40"); // Smallest negative in 1 byte
  },
);

test(
  "Signed LEB128: Positive multi-byte values",
  func() {
    testSignedLEB128(64, "\C0\00"); // Need 2 bytes
    testSignedLEB128(127, "\FF\00");
    testSignedLEB128(128, "\80\01");
    testSignedLEB128(8191, "\FF\3F"); // 2^13 - 1
    testSignedLEB128(8192, "\80\C0\00"); // 2^13
  },
);

test(
  "Signed LEB128: Negative multi-byte values",
  func() {
    testSignedLEB128(-65, "\BF\7F"); // Need 2 bytes
    testSignedLEB128(-128, "\80\7F");
    testSignedLEB128(-129, "\FF\7E");
    testSignedLEB128(-8192, "\80\40"); // -2^13
    testSignedLEB128(-8193, "\FF\BF\7F"); // -2^13 - 1
  },
);

test(
  "Signed LEB128: Large positive values",
  func() {
    testSignedLEB128(1000000, "\C0\84\3D");
    testSignedLEB128(2147483647, "\FF\FF\FF\FF\07"); // Max 32-bit signed
  },
);

test(
  "Signed LEB128: Large negative values",
  func() {
    testSignedLEB128(-1000000, "\C0\FB\42");
    testSignedLEB128(-2147483648, "\80\80\80\80\78"); // Min 32-bit signed
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
    testSignedLEB128(2, "\02");
    testSignedLEB128(-2, "\7E");
    testSignedLEB128(127, "\FF\00");
    testSignedLEB128(-127, "\81\7F");
    testSignedLEB128(128, "\80\01");
    testSignedLEB128(-128, "\80\7F");
  },
);

// =============================================================================
// Error Cases
// =============================================================================

test(
  "LEB128: Error cases",
  func() {
    // Empty input
    testUnsignedLEB128Error("");
    testSignedLEB128Error("");

    // Incomplete LEB128 (missing continuation)
    testUnsignedLEB128Error("\80"); // Indicates more bytes but none follow
    testUnsignedLEB128Error("\80\80"); // Still incomplete
    testSignedLEB128Error("\80"); // Indicates more bytes but none follow
    testSignedLEB128Error("\80\80"); // Still incomplete
  },
);

// =============================================================================
// Infinite Precision Tests (Beyond 64-bit)
// =============================================================================

test(
  "Unsigned LEB128: Beyond 64-bit values",
  func() {
    testUnsignedLEB128(18446744073709551616, "\80\80\80\80\80\80\80\80\80\02");
    testUnsignedLEB128(36893488147419103232, "\80\80\80\80\80\80\80\80\80\04");
    testUnsignedLEB128(1180591620717411303424, "\80\80\80\80\80\80\80\80\80\80\01");
    testUnsignedLEB128(123456789012345678901234567890, "\D2\95\FC\F1\E4\9D\F8\B9\C3\ED\BF\C8\EE\31");
  },
);

test(
  "Signed LEB128: Beyond 64-bit positive values",
  func() {
    testSignedLEB128(9223372036854775808, "\80\80\80\80\80\80\80\80\80\01");
    testSignedLEB128(18446744073709551616, "\80\80\80\80\80\80\80\80\80\02");
    testSignedLEB128(123456789012345678901234567890, "\D2\95\FC\F1\E4\9D\F8\B9\C3\ED\BF\C8\EE\31");
  },
);

test(
  "Signed LEB128: Beyond 64-bit negative values",
  func() {
    testSignedLEB128(-9223372036854775809, "\FF\FF\FF\FF\FF\FF\FF\FF\FF\7E");
    testSignedLEB128(-18446744073709551616, "\80\80\80\80\80\80\80\80\80\7E");
    testSignedLEB128(-123456789012345678901234567890, "\AE\EA\83\8E\9B\E2\87\C6\BC\92\C0\B7\91\4E");
  },
);

test(
  "LEB128: Infinite precision round-trip tests",
  func() {
    // Test very large values round-trip correctly
    testUnsignedLEB128Roundtrip(340282366920938463463374607431768211455); // 2^128 - 1
    testSignedLEB128Roundtrip(170141183460469231731687303715884105727); // 2^127 - 1
    testSignedLEB128Roundtrip(-170141183460469231731687303715884105728); // -2^127

    // Arbitrary large values
    testUnsignedLEB128Roundtrip(999999999999999999999999999999999999999);
    testSignedLEB128Roundtrip(999999999999999999999999999999999999999);
    testSignedLEB128Roundtrip(-999999999999999999999999999999999999999);
  },
);
