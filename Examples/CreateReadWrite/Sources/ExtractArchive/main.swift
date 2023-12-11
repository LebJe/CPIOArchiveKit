// Copyright (c) 2023 Jeff Lebrun
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

enum ExitCode: Int32 {
	case invalidArgument = 7
	case cpioParserError = 8
	case otherError = 9
}

enum ExtractorError: Error {
	case invalidArgument(arg: String)
	case unableToMakeDirectory(directory: String)
	case unsupportedFileType(type: CPIOFileType?)
	case unableToCreateFile(path: String)
	case unableToWriteFile(path: String)

	var description: String {
		switch self {
			case let .invalidArgument(arg): return "The argument \"\(arg)\" provided to \(CommandLine.arguments[0]) was invalid."
			case let .unableToMakeDirectory(dir): return "Unable to create directory \"\(dir)\"."
			case let .unsupportedFileType(type): return "The file type \"\(Utilities.description(of: type) ?? "Unknown")\" is invalid."
			case let .unableToCreateFile(path): return "Unable to create a file at \"\(path)\"."
			case let .unableToWriteFile(path): return "Unable to write to the file at \"\(path)\"."
		}
	}

	var exitCode: Int32 {
		switch self {
			case .invalidArgument: return 2
			case .unableToMakeDirectory: return 3
			case .unsupportedFileType: return 4
			case .unableToCreateFile: return 5
			case .unableToWriteFile: return 6
		}
	}
}

func makeDirectoryRecursive(path: String, mode: UInt32, chmodMode: mode_t) throws {
	var path = path

	// Remove "./" from path.
	if path.starts(with: [".", "/"]) { path = String(path.dropFirst(2)) }

	let components = path.split(separator: "/")

	for i in 0..<components.count {
		var name: String
		if i != 0 {
			name = Array(components[0..<i]).joined(separator: "/")
		} else {
			name = components.joined(separator: "/")
		}

		// Make the directory and set the permissions.
		if mkdir(name, mode_t(mode)) != 0, chmod(name, mode_t(chmodMode)) != 0, errno != EEXIST {
			throw ExtractorError.unableToMakeDirectory(directory: name)
		}
	}
}

func main() throws {
	if CommandLine.argc < 2 {
		print("USAGE: \(CommandLine.arguments[0]) <cpio-archive>\n\nExtracts files from cpio archives.")
		exit(1)
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

	let archive = try CPIOArchive(data: Array(buf.bindMemory(to: UInt8.self)))

	for file in archive.files {
		switch file.header.mode.type {
			case .regular:
				// The file is inside one or more directories.
				if file.header.name.contains("/") {
					var name = file.header.name

					// Remove "./" from the name.
					if name.starts(with: [".", "/"]) {
						name = String(name.dropFirst(2))
					}
					name = name.split(separator: "/").dropLast().dropLast().joined(separator: "/")

					// Check if the directories leading up to this file exists. if they don't, then create them.
					let statPointer = UnsafeMutablePointer<stat>.allocate(capacity: 1)
					if stat(name, statPointer) == -1 {
						try makeDirectoryRecursive(
							path: name,
							mode: file.header.mode.permissions,
							chmodMode: mode_t(file.header.mode.rawType)
						)
					}
				}

				guard let fp = fopen(file.header.name, "wb") else {
					throw ExtractorError.unableToCreateFile(path: file.header.name)
				}

				if file.contents.withUnsafeBytes({ write(fileno(fp), $0.baseAddress!, file.contents.count) }) != -1, chmod(
					file.header.name,
					mode_t(file.header.mode.permissions)
				) == 0, fclose(fp) == 0 {
					print("Successfully wrote \"\(file.header.name)\"!")
				} else {
					throw ExtractorError.unableToWriteFile(path: file.header.name)
				}

			case .directory:
				try makeDirectoryRecursive(
					path: file.header.name,
					mode: file.header.mode.permissions,
					chmodMode: mode_t(file.header.mode.permissions)
				)
				print("Made directory \"\(file.header.name)\".")

			case .symlink: break // TODO: Support Symbolic Links.
			case .none: throw ExtractorError.unsupportedFileType(type: nil)
			default: throw ExtractorError.unsupportedFileType(type: file.header.mode.type)
		}
	}
}

do {
	try main()
} catch CPIOArchiveError.invalidHeader {
	fputs("One of the headers in \"\(CommandLine.arguments[0])\" is invalid.", stderr)
	exit(ExitCode.cpioParserError.rawValue)
} catch CPIOArchiveError.invalidArchive {
	fputs("The archive \"\(CommandLine.arguments[0])\" is invalid.", stderr)
	exit(ExitCode.cpioParserError.rawValue)
} catch let error as ExtractorError {
	fputs("\(error.description)", stderr)
	exit(error.exitCode)
} catch {
	fputs("An error occurred: \(error)", stderr)
	exit(ExitCode.otherError.rawValue)
}
