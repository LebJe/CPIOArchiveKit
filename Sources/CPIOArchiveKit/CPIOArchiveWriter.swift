// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// `CPIOArchiveWriter` creates `cpio` archives.
public struct CPIOArchiveWriter {
	/// The raw bytes of the archive.
	public var bytes: [UInt8] = []

	public let archiveType: CPIOArchiveType

	private var wasFinalized = false

	private var currentInode = 0
	private var currentDev = (major: 0, minor: 0)

	private var trailerHeader = Header(name: "TRAILER!!!", mode: FileMode(rawValue: 0o644), modificationTime: 0, links: 1)

	/// Creates a new `CPIOArchiveWriter`.
	/// - Parameter type: The type of `cpio` archive you would like `CPIOArchiveWriter` to create.
	public init(type: CPIOArchiveType = .svr4) { self.archiveType = type }

	private mutating func createHeader(for type: CPIOArchiveType, header: Header, contentSize: Int) -> [UInt8] {
		var headerBytes: [UInt8] = Array(repeating: Character("0").asciiValue!, count: Constants.headerLength)

		switch type {
			case .svr4:
				var m = Constants.magicBytes
				m[5] = (header.checksum != nil && header.checksum?.sum != 0) ? 0x32 : m[5]

				headerBytes.replaceSubrange(0..<6, with: m)
				headerBytes.replaceSubrange(6..<14, with: (header.inode ?? self.currentInode).hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(14..<22, with: header.mode.rawValue.hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(22..<30, with: header.userID.hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(30..<38, with: header.groupID.hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(38..<46, with: header.links.hex.leftPadding(to: 8).asciiArray)

				if header.modificationTime != 0 {
					headerBytes.replaceSubrange(46..<54, with: header.modificationTime.hex.leftPadding(to: 8).asciiArray)
				}

				headerBytes.replaceSubrange(54..<62, with: contentSize.hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(62..<70, with: (header.dev.major ?? self.currentDev.major).hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(70..<78, with: (header.dev.minor ?? self.currentDev.minor).hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(78..<86, with: header.rDev.major.hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(86..<94, with: header.rDev.minor.hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(94..<102, with: (header.name.count + 1).hex.leftPadding(to: 8).asciiArray)

				if let checksum = header.checksum {
					headerBytes.replaceSubrange(102..<110, with: checksum.sum.hex.leftPadding(to: 8).asciiArray)
				}

				self.currentInode += 1
				self.currentDev.major += 1
				self.currentDev.minor += 1
				return headerBytes
		}
	}

	/// Add a file to the archive.
	/// - Parameters:
	///   - header: The header that describes the file.
	///   - contents: The raw bytes of the file.
	///
	/// ### Symlinks
	/// Add a symlink by setting `header.name` to the name you want the symlink to have, and `contents` to the name of the file you want to link to.
	public mutating func addFile(header: Header, contents: [UInt8]) {
		var h = header

		// Regular files should one or more links.
		h.links = h.links < 1 && h.mode.isRegularFile ? 1 : h.links

		if (h.mode.rawValue &^ FileType.permissions.rawValue) == 0 {
			h.mode.rawValue |= FileType.regular.rawValue
		}

		self.bytes += self.createHeader(for: self.archiveType, header: h, contentSize: contents.count)

		self.bytes += h.name.utf8Array + [0x00]

		// Pad the end of the filename with zero's
		let namePadding = (4 - ((Constants.headerLength + h.name.count + 1) % 4)) % 4

		self.bytes += Array(Array<UInt8>(repeating: 0, count: 4)[0..<namePadding])

		self.bytes += contents

		// Pad the end of the file with zero's
		let filePadding = (4 - (contents.count % 4)) % 4

		self.bytes += Array(Array<UInt8>(repeating: 0, count: 4)[0..<filePadding])
	}

	/// Wrapper function around `CPIOArchiveWriter.addFile(header:contents:)` which allows you to pass in a `String` instead of raw bytes..
	///
	/// ### Symlinks
	/// Add a symlink by setting `header.name` to the name you want the symlink to have, and `contents` to the name of the file you want to link to.
	public mutating func addFile(header: Header, contents: String) {
		self.addFile(header: header, contents: contents.utf8Array)
	}

	public mutating func finalize() {
		if !self.wasFinalized {
			self.wasFinalized = true
		}

		self.addFile(header: self.trailerHeader, contents: [])
	}
}
