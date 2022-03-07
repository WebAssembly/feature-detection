# Feature Detection Proposal

## Summary

This proposal extends Wasm with the ability to detect supported features at
runtime and gracefully fall back to alternative code paths when a feature is not
supported.

## Motivation

WebAssembly users want to be able to perform WebAssembly feature detection for
many of the same reasons they already use feature detection on native platforms.
Specifically, they want to be able to build a single wasm module that can run on
a variety of different engines, taking advantage of cutting-edge features when
they are available and gracefully falling back to alternative code paths when
they are not. Feature detection is particularly useful when cutting edge
features used in just a few hot functions can materially improve application
performance without unduly increasing the binary size.

## Goals and Non-goals

 * Goal: Support feature detection as used in real-world code bases. This includes:

   - GCC/Clang's [`target` attribute](https://gcc.gnu.org/onlinedocs/gcc/Common-Function-Attributes.html#:~:text=target%20(string%2C%20%E2%80%A6)) and [function multiversioning](https://gcc.gnu.org/onlinedocs/gcc/Function-Multiversioning.html)

   - Programmatic feature querying

 * Goal: Allow graceful fallback when features aren't supported by providing a
   mechanism for skipping decoding of unsupported features in the code section.
   This includes skipping:

   - Unknown instructions

   - Unknown types in type annotations.

* Non-goal: Allow graceful fallback for unknown features outside the code
  section. In practice, feature detection is most useful when it can have a big
  performance benefit for small extra code size. Since gracefully falling back
  to alternative ABIs or compilation schemes would require lots of duplicated
  code, supporting these more general use cases are not as important and not
  worth the extra complexity. For a more general mechanism, see the older
  [conditional sections
  proposal](https://github.com/WebAssembly/conditional-sections).

  It may be worth it to allow graceful fallbacks in the type section, since type
  annotations in the code section may in general refer to the type section, but
  for now we will see how far we can get without that.

## Overview

### Feature detection: `features.supported`

The first new item is a new instruction `features.suported` (name subject to
bikeshedding) that takes an immediate bitmask identifying a feature set and
returns a `1` if the current engine supports that feature set and a `0`
otherwise. The immediate bitmask will be a uleb128 to allow it to scale to an
arbitrary number of features.

### Forward compatibility: `feature_block`

While `features.supported` allows supported features to be detected at runtime,
we still need a way for new instructions to pass validation on older engines on
which they aren't supported. To do this, we introduce a new block-like
construct, `feature_block` (name subject to bikeshedding). Its binary format
syntax is

```
feature_block blocktype feature_bitvec byte_len instr* end
```

`feature_bitvec` is a uleb128 encoding the same kind of feature bitmask used in
`features.supported` and `byte_len` is the byte length of `instr*`. During
decoding, if the engine supports all the features in `feature_bitvec`, the
`feature_block` is decoded as a normal block, i.e. `block blocktype instr* end`.
Otherwise, the `feature_block` is decoded as an `unreachable`, using `byte_len`
to skip its contents entirely without decoding them.

Because it is a decoding-time feature, there is no need for `feature_block` to
appear in WebAssembly's syntax, semantics, or validation algorithm. Similarly,
`features.supported` can be specified as decoding to `i32.const 0` or `i32.const
1` and does not need to appear in the spec outside of the binary format.

### Features

How to specify the available features is an open question, since the current
spec does not have any concept of optional features and does not differentiate
instructions or types based on what proposal they were introduced by.

We expect that some engines will choose not to implement the [SIMD
proposal](https://github.com/WebAssembly/simd) (whether or not that technically
makes them spec-noncompliant), so a feature bit will be allocated to that
proposal and any follow-on SIMD proposals. Whether it would be useful to
allocate feature bits to other proposals such as [bulk memory
operations](https://github.com/WebAssembly/bulk-memory-operations) is not known
and needs to be investigated.

### FAQ

#### Why resolve these instructions during decoding? ([#2](https://github.com/WebAssembly/feature-detection/issues/2))

Adding `feature_block` to the AST would involve inserting arbitrary bytes into the AST and having validation call back into decoding. It's much cleaner to keep the phases separate and resolve `feature_block` (and `features.supported`) during the original decoding.
