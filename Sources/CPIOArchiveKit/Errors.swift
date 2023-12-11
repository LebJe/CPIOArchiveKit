// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// Errors that may occur while writing or reading CPIO archives.
public enum CPIOArchiveError: Error {
	/// The archive was invalid. It may not contain a global header,
	/// the file headers may be ill formatted, or something else may be wrong.
	case invalidArchive

	/// The archive did not contain the correct sequence of bytes that identifies it as a `cpio` archive.
	case invalidMagicBytes

	/// The archive did not contain the sequence of bytes that identifies it as a `cpio` archive.
	case missingMagicBytes

	/// The header may contain invalid characters and/or bytes, or may be missing certain fields.
	case invalidHeader

	/// The CRC checksum was invalid, or the archive's magic bytes stated that a checksum should exist for each header, but
	/// said checksum was missing.
	///
	/// The header is provided to help determine which entry in the archive is invalid.
	case missingOrInvalidChecksum(CPIOArchive.Header)
}
