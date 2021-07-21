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

enum ItemType {
	case file, dir, symlink
}

let usage = "USAGE: \(CommandLine.arguments[0]) [--help, -h, -?] <files...>\n\nCreate a cpio archive from a list of files and/or directories."

if CommandLine.argc == 1 {
	print(usage)
	exit(1)
} else if CommandLine.arguments.contains("-h") || CommandLine.arguments.contains("-?") || CommandLine.arguments.contains("--help") {
	print(usage)
	exit(0)
}

let items = Array(CommandLine.arguments.dropFirst())
var writer = CPIOArchiveWriter()

for item in items {
	// Open `item`.
	guard let fp = fopen(item, "rb") else {
		print("Unable to open \(item)")
		exit(2)
	}

	print("Adding \(item) to archive...")

	let fpNumber = fileno(fp)

	var type: ItemType = .file

	// Make sure `item` is a symlink, file, or directory.
	let statPointer = UnsafeMutablePointer<stat>.allocate(capacity: 1)
	fstat(fileno(fp), statPointer)

	switch statPointer.pointee.st_mode & S_IFMT {
		case S_IFREG: type = .file
		case S_IFDIR: type = .dir
		case S_IFLNK: type = .symlink
		default:
			print("\(item) is not a file, directory, or symlink! Only the aforementioned types are supported.")
			exit(3)
	}

	// Load `item` into memory.
	let size = Int(lseek(fpNumber, 0, SEEK_END))
	var bytes: [UInt8] = []

	if type == .symlink {
		let pathBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: size == 0 ? Int(PATH_MAX) : size)

		readlink(item, pathBuffer, size == 0 ? Int(PATH_MAX) : size)

		bytes = Array(String(cString: pathBuffer).utf8)
	} else if type == .file {
		lseek(fpNumber, 0, SEEK_SET)

		let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment)

		read(fpNumber, buf.baseAddress, buf.count)

		let bufferPointer = buf.bindMemory(to: UInt8.self)
		bytes = Array(bufferPointer)
	}

	let stat = statPointer.pointee

	#if os(Linux) || os(Android) || os(Windows)
		let statTime = stat.st_mtim.tv_sec
	#else
		let statTime = stat.st_mtimespec.tv_sec
	#endif

	switch type {
		case .file:
			writer.addFile(
				header: Header(
					name: item,
					userID: Int(stat.st_uid),
					groupID: Int(stat.st_gid),
					mode: FileMode(UInt32(stat.st_mode), modes: [.regular, .setUID, .setGID]),
					modificationTime: Int(statTime),
					inode: Int(stat.st_ino),
					links: Int(stat.st_nlink),
					dev: (major: Int(stat.st_dev & 0xFF), minor: Int(stat.st_dev >> 8 & 0xFF)),
					rDev: (major: Int(stat.st_rdev & 0xFF), minor: Int(stat.st_rdev >> 8 & 0xFF))
				),
				contents: bytes
			)
		case .dir:
			writer.addFile(
				header: Header(
					name: item,
					userID: Int(stat.st_uid),
					groupID: Int(stat.st_gid),
					mode: FileMode(UInt32(stat.st_mode), modes: [.directory, .setUID, .setGID]),
					modificationTime: Int(statTime),
					inode: Int(stat.st_ino),
					links: Int(stat.st_nlink),
					dev: (major: Int(stat.st_dev & 0xFF), minor: Int(stat.st_dev >> 8 & 0xFF)),
					rDev: (major: Int(stat.st_rdev & 0xFF), minor: Int(stat.st_rdev >> 8 & 0xFF))
				),
				contents: []
			)
		case .symlink:
			writer.addFile(
				header: Header(
					name: item,
					userID: Int(stat.st_uid),
					groupID: Int(stat.st_gid),
					mode: FileMode(UInt32(stat.st_mode), modes: [.symlink, .setUID, .setGID]),
					modificationTime: Int(statTime),
					inode: Int(stat.st_ino),
					links: Int(stat.st_nlink),
					dev: (major: Int(stat.st_dev & 0xFF), minor: Int(stat.st_dev >> 8 & 0xFF)),
					rDev: (major: Int(stat.st_rdev & 0xFF), minor: Int(stat.st_rdev >> 8 & 0xFF))
				),
				contents: bytes
			)
	}

	fclose(fp)
}

guard let fp = fopen("output.cpio", "wb") else {
	print("Unable to open output.cpio")
	exit(4)
}

let bytes = writer.finalize()

if bytes.withUnsafeBytes({ write(fileno(fp), $0.baseAddress!, bytes.count) }) != -1 {
	print("Successfully wrote output.cpio!")
	exit(0)
} else {
	print("Unable to write output.cpio")
	exit(6)
}
