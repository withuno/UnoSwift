//
// Copyright 2021 WithUno, Inc.
// SPDX-License-Identifier: AGPL-3.0-only
//


#ifndef uno_ffi_h
#define uno_ffi_h

#pragma once

//
// ⚠️ Warning!
//
// This file is auto-generated by cbindgen. Modifications must be made to the
// source Rust extern "C" interface specified in the ~uno/identity/ffi crate.
//
// Do not manually modify this file.
//


#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>


#define UNO_ERR_SUCCESS 0

#define UNO_ERR_ILLEGAL_ARG 1

#define UNO_ERR_SPLIT 2

#define UNO_ERR_COMBINE 3

#define UNO_ERR_SHARE_ID 4

#define UNO_ERR_SHARE_MISS 5

#define UNO_ERR_CHECKSUM 6

#define UNO_ERR_MNEMONIC 7

/**
 * And uno identity newtype.
 */
typedef struct Id Id;

/**
 *
 * Opaque array containing share metadata. Get a member share by index using
 * `uno_get_member_share_by_index`.
 *
 */
typedef struct UnoMemberSharesVec UnoMemberSharesVec;

/**
 *
 * A SplitResult is the output of successfully running `uno_s39_split` on an
 * UnoId. The structure represents an opaque array of UnoGroupSplit structs.
 *
 */
typedef struct UnoSplitResult UnoSplitResult;

/**
 *
 * 32 bytes of seed entropy. See uno::Id.
 *
 */
typedef Id UnoId;

/**
 *
 * UnoByteSlice can be treated like an array of uint8_t bytes on the C side.
 * You may not modify the bytes and the struct must be freed once it is no
 * longer needed.
 *
 */
typedef struct
{
  const uint8_t *ptr;
  size_t len;
  size_t _cap;
} UnoByteSlice;

/**
 *
 * A GroupSpec is a tuple of (threshold, total) shares in a given s39 group
 * split. For instance, if you want a group to be split into 3 pieces, two
 * of which are requred to reconstitute the group secret, you'd pass (2, 3).
 *
 */
typedef struct
{
  uint8_t threshold;
  uint8_t total;
} UnoGroupSpec;

/**
 *
 * A GroupSplit contains metadata related to one of the groups of shares
 * requested during the split call. The actual shares are contained in the
 * opaque UnoMemberSharesVec struct.
 *
 */
typedef struct
{
  uint16_t group_id;
  uint8_t iteration_exponent;
  uint8_t group_index;
  uint8_t group_threshold;
  uint8_t group_count;
  /**
   * The number of shares from this group required to reconstitue the group
   * secret.
   */
  uint8_t member_threshold;
  /**
   * Total number of member_shares
   */
  size_t share_count;
  /**
   * Opaque reference to the constituent member shares. Acquire one of the
   * shares with `uno_get_member_share_by_index`.
   */
  const UnoMemberSharesVec *member_shares;
} UnoGroupSplit;

/**
 *
 * Share mnemonic string. Obtained by index from an UnoGroupSplit type using
 * `uno_get_s39_share_by_index`. The mnemonic share data is a c string
 * reference and can be handled in a read-only (const) fashion using the
 * standard c string api. An UnoShare must be freed using `uno_free_s39_share`
 * when you are done using it.
 *
 */
typedef struct
{
  const char *mnemonic;
} UnoShare;

/**
 *
 * Share metadata struct. Metadata about a share can be obtained by calling
 * `uno_get_share_metadata` with an UnoS39Share.
 *
 */
typedef struct
{
  /**
   * Random 15 bit value which is the same for all shares and is used to
   * verify that the shares belong together; it is also used as salt in the
   * encryption of the master secret. (15 bits)
   */
  uint16_t identifier;
  /**
   * Indicates the total number of iterations to be used in PBKDF2. The
   * number of iterations is calculated as 10000x2^e. (5 bits)
   */
  uint8_t iteration_exponent;
  /**
   * The x value of the group share (4 bits)
   */
  uint8_t group_index;
  /**
   * indicates how many group shares are needed to reconstruct the master
   * secret. The actual value is endoded as Gt = GT - 1, so a value of 0
   * indicates that a single group share is needed (GT = 1), a value of 1
   * indicates that two group shares are needed (GT = 2) etc. (4 bits)
   */
  uint8_t group_threshold;
  /**
   * indicates the total number of groups. The actual value is encoded as
   * g = G - 1 (4 bits)
   */
  uint8_t group_count;
  /**
   * Member index, or x value of the member share in the given group (4 bits)
   */
  uint8_t member_index;
  /**
   * indicates how many member shares are needed to reconstruct the group
   * share. The actual value is encoded as t = T − 1. (4 bits)
   */
  uint8_t member_threshold;
  /**
   * corresponds to a list of the SSS part's fk(x) values 1 ≤ k ≤ n. Each
   * fk(x) value is encoded as a string of eight bits in big-endian order.
   * The concatenation of these bit strings is the share value. This value is
   * left-padded with "0" bits so that the length of the padded share value
   * in bits becomes the nearest multiple of 10. (padding + 8n bits)
   */
  UnoByteSlice share_value;
  /**
   * an RS1024 checksum of the data part of the share
   * (that is id || e || GI || Gt || g || I || t || ps). The customization
   * string (cs) of RS1024 is "shamir". (30 bits)
   */
  uint32_t checksum;
} UnoShareMetadata;

/**
 *
 * Get a description for the provided error code. The lifetime of the returned
 * string does not need to be managed by the caller.
 *
 */
const char *uno_get_msg_from_err(int err);

/**
 *
 * Create an uno id struct from a 32 byte seed data array. The caller is
 * responsible calling `uno_free_id` on the returned struct once finished.
 *
 */
int uno_get_id_from_bytes(const uint8_t *bytes, size_t len, const UnoId **out);

/**
 *
 * Copy the raw 32 bytes backing an uno Id into caller-owned memory.
 *
 */
int uno_copy_id_bytes(const UnoId *uno_id, uint8_t *bytes, size_t len);

/**
 *
 * Free a previously allocated UnoId from `uno_get_id_from_bytes`.
 *
 */
void uno_free_id(UnoId *id);

/**
 *
 * Get the raw bytes backing an uno Id.
 *
 */
int uno_get_bytes_from_id(const UnoId *uno_id, UnoByteSlice *out);

/**
 *
 * Free the backing array on an UnoByteSlice from a function that returns an
 * allocated UnoByteSlice, e.g. `uno_get_id_bytes`.
 *
 */
void uno_free_byte_slice(UnoByteSlice byte_slice);

/**
 *
 * See s39::split.
 *
 * Rather than an array of tuples, the caller provides an array of GroupSpec
 * structs. The group_threshold is fixed at 1 so this parameter is currently
 * unused.
 *
 * Upon success, the SplitResult represents an array of UnoGroupSplits of
 * length group_total.
 *
 */
int uno_s39_split(const UnoId *uno_id,
                  size_t _group_threshold,
                  const UnoGroupSpec *group_specs,
                  size_t group_total,
                  const UnoSplitResult **out);

/**
 *
 * Free a previously allocated UnoSplitResult from `uno_s39_split`.
 *
 */
void uno_free_split_result(UnoSplitResult *split_result);

/**
 *
 * Get an UnoGroupSplit by index from an opaque UnoSplitResult.
 *
 */
int uno_get_group_from_split_result(const UnoSplitResult *split_result,
                                    size_t index,
                                    UnoGroupSplit *out);

/**
 *
 * Free a previously allocated GroupSplit returned by
 * `uno_get_group_from_split_result`.
 *
 */
void uno_free_group_split(UnoGroupSplit group_split);

/**
 *
 * Returns the actual member share by index.
 *
 */
int uno_get_s39_share_by_index(UnoGroupSplit group_split,
                               uint8_t index,
                               UnoShare *out);

/**
 *
 * Convert a mnemonic string of 33 space separated words to an internal share
 * representation.
 *
 */
int uno_get_s39_share_from_mnemonic(const char *ptr, UnoShare *out);

/**
 *
 * Free a previously allocated share returned by `uno_get_s39_share_by_index`
 * or `uno_get_s39_share_from_mnemonic`.
 *
 */
void uno_free_s39_share(UnoShare share);

/**
 *
 * Get the share metadata from an UnoShare.
 *
 */
int uno_get_s39_share_metadata(UnoShare share, UnoShareMetadata *out);

/**
 *
 * Free a previously allocated ShareMetadata returned by
 * `uno_get_s39_share_metadata`.
 *
 */
void uno_free_s39_share_metadata(UnoShareMetadata metadata);

/**
 *
 * See s39::combine.
 *
 * Provided an array of c-stirng s39 shamir's shares, recombine and recover
 * the original UnoId. The returned UnoId must be freed using `uno_free_id`.
 *
 */
int uno_s39_combine(const char *const *share_nmemonics,
                    size_t total_shares,
                    const UnoId **out);

#endif /* uno_ffi_h */
