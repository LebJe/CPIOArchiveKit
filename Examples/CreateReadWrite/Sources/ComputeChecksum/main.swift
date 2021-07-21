// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

#if os(macOS)
	import Darwin.C
#elseif os(Linux)
	import Glibc
#elseif os(Windows)
	import ucrt
#endif

import CPIOArchiveKit

func parseHelpFlag(_ s: String) -> Bool {
	switch s {
		case "-h": return true
		case "-help": return true
		case "--help": return true
		case "-?": return true
		default:
			return false
	}
}

let usage = """
USAGE: \(CommandLine.arguments[0]) [--help, -h, -?] [-b] [-h] [-d] <file>

Reads `file` and computes the checksum for the file.

-h, --help, -?  Prints this message.
"""

if CommandLine.arguments.count < 2 || parseHelpFlag(CommandLine.arguments[1]) {
	print(usage)
	exit(0)
}

guard let fp = fopen(CommandLine.arguments[1], "rb") else {
	print("Unable to open \(CommandLine.arguments[1])")
	exit(2)
}

let fpNumber = fileno(fp)
let size = Int(lseek(fpNumber, 0, SEEK_END))

lseek(fpNumber, 0, SEEK_SET)

let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment)

read(fpNumber, buf.baseAddress, buf.count)

let bufferPointer = buf.bindMemory(to: UInt8.self)

let bytes = Array(bufferPointer)

let checksum = Checksum(bytes: bytes).sum

print("Checksum (in hexadecimal): " + "0x" + String(checksum, radix: 16, uppercase: true))
print("Checksum (in decimal): " + String(checksum))
print("Checksum (in binary): " + String(checksum, radix: 2))
