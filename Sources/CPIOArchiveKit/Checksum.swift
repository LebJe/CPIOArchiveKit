// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// Checksum is the sum of all bytes in the file data.
/// This sum is computed treating all bytes as unsigned values and using unsigned arithmetic.
/// Only the least-significant 32 bits of the sum are stored.
/// (From [go-cpio's documentation](https://github.com/cavaliercoder/go-cpio/blob/925f9528c45e5b74f52963bd11f1988ad99a95a5/header.go#L60)).
///
/// Use ``Checksum/init(bytes:)`` to compute the checksum of a file you will add to the archive.
public struct Checksum: Codable, Equatable {
	/// The sum of all the bytes in the file.
	public var sum: Int = 0

	/// Compute the checksum of `bytes`.
	public init(bytes: [UInt8]) { bytes.forEach({ self.sum += Int($0 & 0xFF) }) }

	/// Set ``Checksum/sum`` to a pre-computed checksum.
	public init(sum: Int) { self.sum = sum }
}
