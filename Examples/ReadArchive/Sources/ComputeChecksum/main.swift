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

Reads `file` And computes the checksum for the file.

-h, --help, -?  Prints this message.
"""

var printInBinary = false
var printInHex = true
var printInDecimal = false

if CommandLine.arguments.count < 2 || parseHelpFlag(CommandLine.arguments[1]) {
	print(usage)
	exit(0)
}

let fd = open(CommandLine.arguments[1], O_RDONLY)

let size = Int(lseek(fd, 0, SEEK_END))

lseek(fd, 0, SEEK_SET)

let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment)

read(fd, buf.baseAddress, buf.count)

let bufferPointer = buf.bindMemory(to: UInt8.self)

let bytes = Array(bufferPointer)

let checksum = Checksum(bytes: bytes).sum

print("Checksum (in hexadecimal): " + "0x" + String(checksum, radix: 16, uppercase: true))
print("Checksum (in decimal): " + String(checksum))
print("Checksum (in binary): " + String(checksum, radix: 2))
