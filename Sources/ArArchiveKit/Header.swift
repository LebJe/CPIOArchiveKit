// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import ArchiveTypes

public extension ArArchive {
	/// The `ar` header.
	///
	/// This header is placed atop the contents of a file in the archive to
	/// provide information such as the size of the file, the file's name, it's permissions, etc.
	struct Header: Equatable, Codable, ArchiveHeader {
		/// The file's name. The name will be truncated to 16 characters if the archive's `Variant` is `common`.
		public internal(set) var name: String

		/// The ID of the user the file belonged to when it was on the filesystem.
		public private(set) var userID: Int = 0

		/// The ID of the group the file belonged to when it was on the filesystem.
		public private(set) var groupID: Int = 0

		/// The permissions of the file.
		public private(set) var mode: UInt32 = 0o644

		/// The last time this file was modified.
		///
		/// Use `Int(myDate.timeIntervalSince1970)` to set `modificationTime` from a `Date`.
		public let modificationTime: Int

		/// The size of the file.
		///
		/// This variable is only set when reading in an archive header.
		public internal(set) var size: Int = 0

		/// Bytes index of the header in the archive
		var contentLocation: Int = 0
		var nameSize: Int?
		var startingLocation: Int?
		var endingLocation: Int?

		public init(
			name: String,
			userID: Int = 0,
			groupID: Int = 0,
			mode: UInt32 = 0o644,
			modificationTime: Int
		) {
			self.name = name
			self.userID = userID
			self.groupID = groupID
			self.mode = mode
			self.modificationTime = modificationTime
		}

		init(bytes: [UInt8], archiveType: inout ArArchive.ArchiveType) throws {
			var start = 0
			var name = Array(bytes[start...15]).string

			start = 16

			let modificationTime = Array(bytes[start...(start + 11)]).int()

			start += 12

			let userID = Array(bytes[start...(start + 5)]).int()

			start += 6

			let groupID = Array(bytes[start...(start + 5)]).int()

			start += 6

			let modeBytes = Array(bytes[start...(start + 5)]).filter({ $0 != 32 })
			let mode: UInt32?

			if modeBytes.isEmpty {
				mode = 0
			} else if modeBytes.count > 3, modeBytes[0..<3] == [49, 48, 48] /* 100 */ {
				mode = UInt32(Array(modeBytes.dropFirst(3)).string, radix: 8)
			} else {
				mode = UInt32(modeBytes.string, radix: 8)
			}

			start += 8

			let size = Array(bytes[start...(start + 7)]).int()

			guard
				let mT = modificationTime,
				let u = userID,
				let g = groupID,
				let m = mode,
				let s = size
			else { throw ArArchiveError.invalidHeader }

			var h = Header(name: name, userID: u, groupID: g, mode: m, modificationTime: mT)

			// BSD archive
			if name.hasPrefix("#1/") {
				archiveType = .bsd
				name.removeSubrange(name.startIndex..<name.index(name.startIndex, offsetBy: 3))

				guard let nameSize = Int(name) else { throw ArArchiveError.invalidHeader }

				h.size = s - nameSize
				h.nameSize = nameSize
				// GNU archive
			} else if name.hasSuffix("/"), h.name != "//", h.name != "/" {
				archiveType = .gnu
				h.name = String(h.name.dropLast())
				h.size = s
				// Common archive
			} else {
				h.size = s
			}

			self = h
		}

		func serialize(
			archiveType: ArArchiveVariant,
			contentSize: Int,
			hasLongGNUFilenames: inout Bool,
			longGNUFilenamesEntry: inout ArchiveFile<ArArchive.Header>,
			longGNUFilenamesEntryIndex: inout Int,
			bytesEndIndex: Int
		) -> [UInt8] {
			var header = self
			var data: [UInt8] = []

			switch archiveType {
				case .common: data += header.name.truncate(length: 16).asciiArrayWithPadding(size: 16)
				case .bsd:
					data += (header.name.count <= 16 && !header.name.contains(" ") ? header.name : "#1/\(header.name.count)")
						.asciiArrayWithPadding(size: 16)
				case .gnu:
					if header.name.count > 15 {
						hasLongGNUFilenames = true
						longGNUFilenamesEntry.contents += (header.name + "/\n").utf8Array

						data += "/\(String(longGNUFilenamesEntryIndex))".asciiArrayWithPadding(size: 16)

						longGNUFilenamesEntryIndex += header.name.count + 3
					} else {
						data += (header.name + "\(header.name == "//" ? "" : "/")").asciiArrayWithPadding(size: 16)
					}
			}

			data += header.modificationTime.toBytesWithPadding(size: 12, radix: 10)
			data += header.userID.toBytesWithPadding(size: 6, radix: 10)
			data += header.groupID.toBytesWithPadding(size: 6, radix: 10)
			data += header.mode.toBytesWithPadding(size: 8, radix: 8, prefix: "100")

			switch archiveType {
				case .common, .gnu:
					data += contentSize.toBytesWithPadding(size: 10, radix: 10)
					data += "`\n".asciiArrayWithPadding(size: 2)

				case .bsd:
					if header.name.count > 16 || header.name.contains(" ") {
						data += (contentSize + header.name.count).toBytesWithPadding(size: 10, radix: 10)
						data += "`\n".asciiArrayWithPadding(size: 2)
						data += header.name.asciiArrayWithPadding(size: header.name.count)
					} else {
						data += contentSize.toBytesWithPadding(size: 10, radix: 10)
						data += "`\n".asciiArrayWithPadding(size: 2)
					}
			}

			header.nameSize = header.name.count > 16 || header.name.contains(" ") ? header.name.count : nil
			header.contentLocation = (bytesEndIndex - 1) + contentSize + (contentSize % 2 != 0 ? 1 : 0)

			return data
		}

		enum CodingKeys: String, CodingKey {
			case name, userID, groupID, mode, modificationTime, size
		}
	}
}
