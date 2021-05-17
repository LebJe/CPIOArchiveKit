// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

enum Constants {
	/// `070701`: the magic number for the CPIO archive.
	static let magicBytes: [UInt8] = [0x30, 0x37, 0x30, 0x37, 0x30, 0x31]
	static let headerLength = 110
	static let nameSize = 4096
	static let MaxFileSize = 4294967295
	static let trailer = "TRAILER!!!"
}
