// Copyright (c) 2024 Jeff Lebrun
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
import Utilities

// MARK: - Extensions

// From: https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
extension Array {
	func chunked(into size: Int) -> [[Element]] {
		stride(from: 0, to: self.count, by: size).map {
			Array(self[$0..<Swift.min($0 + size, self.count)])
		}
	}
}

// MARK: - Exit Codes and Errors

enum ExitCode: Int32 {
	case invalidArgument = 1
	case cpioParserError = 2
	case otherError = 3
}

// MARK: - Arguments

enum Format: String {
	case binary, hexadecimal = "hex"
}

var shouldPrintFile = false
var printInBinary = false
var width: Int = 30
var amountOfBytes = -1
var format: Format = .hexadecimal

// MARK: - Argument Parsing

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
USAGE: \(CommandLine.arguments[0]) [--help, -h, -?] [-p] [-b] [-w <value>] [-a <value>] <file>

Reads the archive at `file` and prints information about each file in the archive.

-h, --help, -?             Prints this message.
-p                         Print the contents of the files in the archive.
-b                         Print the binary representation of the files in the archive.
-w <value> (default: \(
	width
))   The amount of characters shown horizontally when printing the contents of a file in binary or ASCII/Unicode.
-a <value> (default: \(
	amountOfBytes
))   The amount of characters/bytes you want print from each file in the archive. Use \"-1\" (with the quotes) to print the full file. If the number is greater than the amount of bytes in the file, then it will equal the amount of bytes in the file.
-f <value> (default: \(format.rawValue))  The format you want the file to be printed in. you can choose either \(
	Format
		.binary.rawValue
) or \(Format.hexadecimal.rawValue).
"""

func parseArgs() {
	if CommandLine.arguments.count < 2 || parseHelpFlag(CommandLine.arguments[1]) {
		print(usage)
		exit(0)
	}

	if CommandLine.arguments.firstIndex(of: "-p") != nil {
		shouldPrintFile = true
	}

	if CommandLine.arguments.firstIndex(of: "-b") != nil {
		printInBinary = true
	}

	if let index = CommandLine.arguments.firstIndex(of: "-w") {
		if let w = Int(CommandLine.arguments[index + 1]) {
			width = w
		} else {
			print("\"\(CommandLine.arguments[index + 1])\" is not valid value for -w.")
			exit(ExitCode.invalidArgument.rawValue)
		}
	}

	if let index = CommandLine.arguments.firstIndex(of: "-a") {
		if let a = Int(CommandLine.arguments[index + 1]) {
			amountOfBytes = a
		} else {
			print("\"\(CommandLine.arguments[index + 1])\" is not valid value for -a.")
			exit(ExitCode.invalidArgument.rawValue)
		}
	}

	if let index = CommandLine.arguments.firstIndex(of: "-f") {
		if let f = Format(rawValue: CommandLine.arguments[index + 1]) {
			format = f
		} else {
			print("\"\(CommandLine.arguments[index + 1])\" is not valid value for -f.")
			exit(ExitCode.invalidArgument.rawValue)
		}
	}
}

// MARK: - Main Code

func printContents(from bytes: [UInt8]) {
	if printInBinary {
		bytes
			.chunked(into: width)
			.forEach({
				$0.forEach({ byte in
					switch format {
						case .binary:
							print(String(byte, radix: 2), terminator: " ")
						case .hexadecimal:
							print("0x\(String(byte, radix: 16))", terminator: " ")
					}
				})

				print()
			})
	} else {
		print(String(bytes))
	}
}

func main() throws {
	guard let fp = fopen(CommandLine.arguments[1], "rb") else {
		print("Unable to open \(CommandLine.arguments[1])")
		exit(2)
	}

	let fpNumber = fileno(fp)
	let size = Int(lseek(fpNumber, 0, SEEK_END))

	lseek(fpNumber, 0, SEEK_SET)

	let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment)

	read(fpNumber, buf.baseAddress, buf.count)

	let bytes = Array(buf.bindMemory(to: UInt8.self))
	let archive = try CPIOArchive(data: bytes)

	for file in archive.files {
		print("---------------------------")

		print("Name: " + file.header.name)
		print("User ID: " + String(file.header.userID))
		print("Group ID: " + String(file.header.groupID))
		print("Links: " + String(file.header.links))
		print("Inode: " + (file.header.inode != nil ? String(file.header.inode!) : "No Inode"))

		print("Dev (major): " + (file.header.dev.major != nil ? String(file.header.dev.major!) : "No Dev"))
		print("Dev (minor): " + (file.header.dev.minor != nil ? String(file.header.dev.minor!) : "No Dev"))
		print("rDev (major): " + String(file.header.rDev.major))
		print("rDev (minor): " + String(file.header.rDev.minor))

		print("File Permissions (In Octal): " + String(file.header.mode.permissions, radix: 8))
		print("File Type: " + description(of: file.header.mode))
		print("File Size: " + String(file.header.size))
		print("File Modification Time: " + String(file.header.modificationTime))

		if let c = file.header.checksum {
			print("Checksum (In Hexadecimal): 0x" + String(c.sum, radix: 16, uppercase: true))
		}

		if shouldPrintFile {
			print("Contents:\n")
			if amountOfBytes != -1 {
				amountOfBytes = amountOfBytes > file.contents.count ? file.contents.count : amountOfBytes
				printContents(from: Array(file.contents[0..<amountOfBytes]))
			} else {
				printContents(from: file.contents)
			}
		}
	}

	print("---------------------------")
}

func description(of mode: CPIOFileMode) -> String {
	var descriptions: [String] = []

	for type in CPIOFileType.allCases {
		if mode.is(type) {
			if let d = description(of: type) {
				descriptions.append(d)
			}
		}
	}

	return descriptions.joined(separator: ", ")
}

do {
	parseArgs()
	try main()
} catch CPIOArchiveError.invalidHeader {
	fputs("One of the headers in \"\(CommandLine.arguments[1])\" is invalid.", stderr)
	exit(ExitCode.cpioParserError.rawValue)
} catch CPIOArchiveError.invalidArchive {
	fputs("The archive \"\(CommandLine.arguments[1])\" is invalid.", stderr)
	exit(ExitCode.cpioParserError.rawValue)
} catch {
	fputs("An error occurred: \(error)", stderr)
	exit(ExitCode.otherError.rawValue)
}
