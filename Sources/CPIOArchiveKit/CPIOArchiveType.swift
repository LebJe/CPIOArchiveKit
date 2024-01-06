// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// The format of a CPIO archive.
public enum CPIOArchiveType {
	/// The SVR4 (without CRC) format. Also known as "NEWC" or "New ASCII".
	case svr4

	/// The SVR4 (with CRC) format. Also known as "NEWC", "New ASCII" or "New CRC".
	case svr4WithCRC

	var magicBytes: [UInt8] {
		switch self {
			case .svr4: return [0x30, 0x37, 0x30, 0x37, 0x30, 0x31]
			case .svr4WithCRC: return [0x30, 0x37, 0x30, 0x37, 0x30, 0x32]
		}
	}
}
