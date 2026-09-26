# MoonFuse

MoonFuse is a pure MoonBit implementation of an immutable, approximate
membership filter. It uses a deterministic three-segment Binary-Fuse-style
construction: build once from non-negative, distinct integer hashes, then
query in constant time with no false negatives for successfully built input.

This is intentionally not an exact set. A query that was not present during
construction can return `true`; choose 8-bit fingerprints for lower memory or
16-bit fingerprints for a lower expected false-positive rate.

## Use

```moonbit
let filter = @fuse.BinaryFuseFilter::build([101, 202, 303]).unwrap()
assert_true(filter.contains(202))
assert_false(filter.contains(404)) // a miss is expected, but not guaranteed
```

Run the checks and demo locally:

```text
moon check --deny-warn
moon test --deny-warn
moon run cmd/demo
```

## Guarantees and boundaries

- Input hashes must be non-negative and unique. The caller owns object/string
  hashing and collision policy.
- Construction is deterministic and has a bounded retry budget; failure is a
  `ConstructionFailed` error, never an unbounded loop.
- `contains` has no false negatives for the input that built a successfully
  validated filter. It may have false positives for other hashes.
- `encode_words` / `decode_words` and compact `encode_bytes` / `decode_bytes`
  are versioned and reject malformed shape, width and out-of-range data.
- `encode_word_transport` wraps any non-negative word codec in a versioned,
  checksummed byte transport; it detects accidental corruption but is not a
  cryptographic authenticity mechanism.
- The current implementation optimizes reliability before density. It does
  not implement insert, delete, merging, cryptographic hashing or persistence
  beyond the checked word codec.

## Provenance

MoonFuse is independently written in MoonBit. The algorithm family is informed
by the Binary Fuse Filters paper and public projects such as
[FastFilter/xorfilter](https://github.com/FastFilter/xorfilter); no upstream
source, tests or generated data are copied. MoonFuse itself is MIT licensed.
