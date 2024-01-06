// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import ArchiveTypes

public extension CPIOArchive {
	/// The `cpio` header.
	///
	/// This header is placed directly before the contents of a file in the archive to
	/// provide information such as the size of the file, the file's name, it's permissions, etc.
	struct Header: Codable, Equatable, ArchiveHeader {
		/// The file's name.
		public internal(set) var name: String

		/// The ID of the user the file belonged to when it was on the filesystem.
		public internal(set) var userID: Int = 0

		/// The ID of the group the file belonged to when it was on the filesystem.
		public internal(set) var groupID: Int = 0

		/// The permissions and attributes of the file.
		public internal(set) var mode: CPIOFileMode

		/// The last time this file was modified.
		///
		/// Use `Int(myDate.timeIntervalSince1970)` to set `modificationTime` from a `Date`.
		public let modificationTime: Int

		/// The inode (index node) of this file. More information is available on
		/// [Wikipedia](https://en.wikipedia.org/wiki/Inode).
		public internal(set) var inode: Int?

		/// The number of links to this file. Directories always have a
		/// value of at least two here.  Note that hard-linked files include
		/// file data with every copy in the archive.
		///
		/// (Documentation from [https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+12.2-RELEASE](https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+12.2-RELEASE))
		public internal(set) var links: Int = 1

		/// If this `Header` describes a symlink, then `linkName` will contain the name of the linked file.
		public internal(set) var linkName: String?

		/// The device number of this file when it was on the filesystem.
		public internal(set) var dev: (major: Int?, minor: Int?) = (nil, nil)

		/// For block special and character special entries, this field contains the associated device number.
		///
		/// (Documentation from [https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+12.2-RELEASE](https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+12.2-RELEASE))
		public internal(set) var rDev: (major: Int, minor: Int) = (0, 0)

		/// "...[T]he [checksum] field is set to the sum of all bytes in the file data. This sum is computed [by] treating all
		/// bytes as unsigned values and using unsigned arithmetic.
		///  Only the least-significant 32 bits of the sum are stored."
		///
		/// (Documentation from [https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+12.2-RELEASE](https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+12.2-RELEASE))
		public internal(set) var checksum: Checksum?

		/// The size of the file.
		///
		/// This variable is only set when reading in an archive header.
		public internal(set) var size: Int = 0

		var contentLocation: Int = 0
		var nameSize: Int = 0
		var startingLocation: Int?
		var endingLocation: Int?

		var namePadding: Int {
			(4 - ((Constants.headerLength + self.name.count + 1) % 4)) % 4
		}

		var contentPadding: Int {
			(4 - (self.size % 4)) % 4
		}

		public init(
			name: String,
			userID: Int = 0,
			groupID: Int = 0,
			mode: CPIOFileMode,
			modificationTime: Int,
			inode: Int? = nil,
			links: Int = 1,
			dev: (major: Int?, minor: Int?) = (nil, nil),
			rDev: (major: Int, minor: Int) = (0, 0),
			checksum: Checksum? = nil
		) {
			self.name = name
			self.userID = userID
			self.groupID = groupID
			self.mode = mode
			self.modificationTime = modificationTime
			self.inode = inode
			self.links = links
			self.dev = dev
			self.rDev = rDev
			self.checksum = checksum
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			self.name = try container.decode(String.self, forKey: .name)
			self.userID = try container.decode(Int.self, forKey: .userID)
			self.groupID = try container.decode(Int.self, forKey: .groupID)
			self.mode = try CPIOFileMode(rawValue: container.decode(UInt32.self, forKey: .mode))
			self.modificationTime = try container.decode(Int.self, forKey: .modificationTime)
			self.inode = try container.decodeIfPresent(Int.self, forKey: .inode)
			self.links = try container.decode(Int.self, forKey: .links)

			let devContainer = try container.nestedContainer(keyedBy: DevCodingKeys.self, forKey: .dev)
			self.dev.major = try devContainer.decodeIfPresent(Int.self, forKey: .major)
			self.dev.minor = try devContainer.decodeIfPresent(Int.self, forKey: .minor)

			let rDevContainer = try container.nestedContainer(keyedBy: DevCodingKeys.self, forKey: .rDev)
			self.rDev.major = try rDevContainer.decode(Int.self, forKey: .major)
			self.rDev.minor = try rDevContainer.decode(Int.self, forKey: .minor)

			if let sum = try container.decodeIfPresent(Int.self, forKey: .checksum) {
				self.checksum = Checksum(sum: sum)
			}
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: Self.CodingKeys.self)

			if let major = self.dev.major, let minor = self.dev.minor {
				var devContainer = container.nestedContainer(keyedBy: DevCodingKeys.self, forKey: .dev)

				try devContainer.encode(major, forKey: .major)
				try devContainer.encode(minor, forKey: .minor)
			} else {
				var devContainer = container.nestedContainer(keyedBy: DevCodingKeys.self, forKey: .dev)

				try devContainer.encodeNil(forKey: .major)
				try devContainer.encodeNil(forKey: .minor)
			}

			var rDevContainer = container.nestedContainer(keyedBy: DevCodingKeys.self, forKey: .rDev)

			try rDevContainer.encode(self.rDev.major, forKey: .major)
			try rDevContainer.encode(self.rDev.minor, forKey: .minor)

			try container.encode(self.name, forKey: .name)
			try container.encode(self.userID, forKey: .userID)
			try container.encode(self.groupID, forKey: .groupID)
			try container.encode(self.mode.rawValue, forKey: .mode)
			try container.encode(self.modificationTime, forKey: .modificationTime)
			if let inode = inode {
				try container.encode(inode, forKey: .inode)
			} else {
				try container.encodeNil(forKey: .inode)
			}

			try container.encode(self.links, forKey: .links)
			if let c = self.checksum {
				try container.encode(c.sum, forKey: .checksum)
			} else {
				try container.encodeNil(forKey: .checksum)
			}
		}

		public static func == (lhs: Header, rhs: Header) -> Bool {
			lhs.name == rhs.name &&
				lhs.userID == rhs.userID &&
				lhs.groupID == rhs.groupID &&
				lhs.mode == rhs.mode &&
				lhs.modificationTime == rhs.modificationTime &&
				lhs.inode == rhs.inode &&
				lhs.links == rhs.links &&
				lhs.linkName == rhs.linkName &&
				lhs.dev == rhs.dev &&
				lhs.rDev == rhs.rDev &&
				lhs.checksum == rhs.checksum &&
				lhs.size == rhs.size
		}

		enum CodingKeys: String, CodingKey {
			case name,
			     userID,
			     groupID,
			     mode,
			     modificationTime,
			     inode,
			     links,
			     dev,
			     rDev,
			     checksum
		}

		enum DevCodingKeys: CodingKey {
			case major
			case minor
		}
	}
}

extension CPIOArchive.Header {
	init(bytes: [UInt8], archiveType: inout CPIOArchiveType) throws {
		let hasCheckSum = bytes[5] == 0x32

		guard
			let inode = Int(hex: String(bytes[6..<14])),
			let mode = UInt32(hex: String(bytes[14..<22])),
			let userID = Int(hex: String(bytes[22..<30])),
			let groupID = Int(hex: String(bytes[30..<38])),
			let links = Int(hex: String(bytes[38..<46])),
			let modTime = Int(hex: String(bytes[46..<54])),
			let size = Int(hex: String(bytes[54..<62])),
			let devMajor = Int(hex: String(bytes[62..<70])),
			let devMinor = Int(hex: String(bytes[70..<78])),
			let rDevMajor = Int(hex: String(bytes[78..<86])),
			let rDevMinor = Int(hex: String(bytes[86..<94])),
			let nameSize = Int(hex: String(bytes[94..<102]))
		else {
			throw CPIOArchiveError.invalidHeader
		}

		self = Self(
			name: "",
			userID: userID,
			groupID: groupID,
			mode: CPIOFileMode(rawValue: mode),
			modificationTime: modTime,
			inode: inode,
			links: links,
			dev: (major: devMajor, minor: devMinor),
			rDev: (major: rDevMajor, minor: rDevMinor),
			checksum: nil
		)

		if hasCheckSum {
			archiveType = .svr4WithCRC
			if let c = Int(hex: String(bytes[102..<110])) {
				self.checksum = Checksum(sum: c)
			} else {
				throw CPIOArchiveError.missingOrInvalidChecksum(self)
			}
		}

		self.size = size
		self.nameSize = nameSize
	}

	func serialize(
		for archiveType: CPIOArchiveType,
		contentSize: Int,
		currentInode: inout Int,
		currentDev: inout (major: Int, minor: Int)
	) -> [UInt8] {
		var headerBytes: [UInt8] = Array(repeating: Character("0").asciiValue!, count: Constants.headerLength)

		switch archiveType {
			case .svr4, .svr4WithCRC:
				var m = archiveType.magicBytes
				m[5] = (self.checksum != nil && self.checksum?.sum != 0) ? 0x32 : m[5]

				headerBytes.replaceSubrange(0..<6, with: m)
				headerBytes.replaceSubrange(6..<14, with: (self.inode ?? currentInode).hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(14..<22, with: self.mode.rawValue.hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(22..<30, with: self.userID.hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(30..<38, with: self.groupID.hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(38..<46, with: self.links.hex.leftPadding(to: 8).asciiArray)

				if self.modificationTime != 0 {
					headerBytes.replaceSubrange(46..<54, with: self.modificationTime.hex.leftPadding(to: 8).asciiArray)
				}

				headerBytes.replaceSubrange(54..<62, with: contentSize.hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(62..<70, with: (self.dev.major ?? currentDev.major).hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(70..<78, with: (self.dev.minor ?? currentDev.minor).hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(78..<86, with: self.rDev.major.hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(86..<94, with: self.rDev.minor.hex.leftPadding(to: 8).asciiArray)
				headerBytes.replaceSubrange(94..<102, with: (self.name.count + 1).hex.leftPadding(to: 8).asciiArray)

				if let checksum = self.checksum, archiveType == .svr4WithCRC {
					headerBytes.replaceSubrange(102..<110, with: checksum.sum.hex.leftPadding(to: 8).asciiArray)
				}

				currentInode += 1
				currentDev.major += 1
				currentDev.minor += 1
				return headerBytes
		}
	}
}
