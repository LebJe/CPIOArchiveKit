// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import ArchiveTypes

extension CPIOArchive {
	/// `CPIOArchiveWriter` creates `cpio` archives.
	///
	/// ```swift
	/// let writer = CPIOArchiveWriter()
	///
	/// let header = CPIOArchive.Header(
	/// 	name: "hello.txt",
	/// 	mode: CPIOFileMode(0o644),
	/// 	modificationTime: Int(Date().timeIntervalSince1970)
	/// )
	/// writer.files.append(.init(header: header, contents: "Hello World!"))
	/// writer.serialize()
	/// // Use `writer.bytes`.
	/// ```
	///
	/// ### Symlinks
	/// Add a symlink by setting `header.name` to the name you want the symlink to have, and `contents` to the name of the
	/// file you want to link to.
	struct CPIOArchiveWriter {
		/// The type of archive that `CPIOArchiveWriter` will create.
		let archiveType: CPIOArchiveType

		/// Inoe and dev that are used if a header does not have one.
		private var currentInode = 0
		private var currentDev = (major: 0, minor: 0)

		private var trailerHeader = Header(
			name: "TRAILER!!!",
			mode: CPIOFileMode(rawValue: 0o644),
			modificationTime: 0,
			links: 1
		)

		var files: [File] = []

		/// Creates a new `CPIOArchiveWriter`.
		/// - Parameter type: The type of `cpio` archive you would like `CPIOArchiveWriter` to create.
		init(type: CPIOArchiveType = .svr4) { self.archiveType = type }

		/// Creates the archive and returns the bytes of the archive.
		mutating func serialize() -> [UInt8] {
			self.files.serialize(archiveType: self.archiveType)
		}
	}
}

extension ArchiveTypes.ArchiveFile where Header == CPIOArchive.Header {
	func serialize(
		to bytes: inout [UInt8],
		archiveType: CPIOArchiveType,
		currentDev: inout (major: Int, minor: Int),
		currentInode: inout Int
	) {
		var h = self.header

		// Regular files should have one or more links.
		h.links = h.links < 1 && h.mode.is(.regular) ? 1 : h.links

		// Make sure the file type is set.
		// From
		// [go-cpio](https://github.com/cavaliercoder/go-cpio/blob/925f9528c45e5b74f52963bd11f1988ad99a95a5/writer.go#L77).
		if (h.mode.rawValue &^ CPIOFileType.permissions.rawValue) == 0 {
			h.mode.rawValue |= CPIOFileType.regular.rawValue
		}

		bytes += h.serialize(
			for: archiveType,
			contentSize: contents.count,
			currentInode: &currentInode,
			currentDev: &currentDev
		)

		bytes += h.name.utf8Array + [0x00]

		// Pad the end of the filename with zeros
		let namePadding = (4 - ((Constants.headerLength + h.name.count + 1) % 4)) % 4

		bytes += Array(Array<UInt8>(repeating: 0, count: 4)[0..<namePadding])

		bytes += contents

		// Pad the end of the file with zeros
		let filePadding = (4 - (contents.count % 4)) % 4

		bytes += Array(Array<UInt8>(repeating: 0, count: 4)[0..<filePadding])
	}
}

extension Array where Self.Element == ArchiveFile<CPIOArchive.Header> {
	func serialize(archiveType: CPIOArchiveType, withTrailer: Bool = true) -> [UInt8] {
		var bytes: [UInt8] = []
		/// Inode and dev that are used if a header does not have one.
		var currentInode = 0
		var currentDev = (major: 0, minor: 0)

		let trailerHeader = CPIOArchive.Header(
			name: "TRAILER!!!",
			mode: CPIOFileMode(rawValue: 0o644),
			modificationTime: 0,
			links: 1
		)
		for file in self + (withTrailer ? [.init(header: trailerHeader)] : []) {
			file.serialize(to: &bytes, archiveType: archiveType, currentDev: &currentDev, currentInode: &currentInode)
		}
		return bytes
	}
}
