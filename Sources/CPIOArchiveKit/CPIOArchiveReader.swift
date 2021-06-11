// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// `CPIOArchiveReader` reads `cpio` files.
public struct CPIOArchiveReader {
	private var data: [UInt8]
	private var currentIndex: Int = 0

	/// The headers that describe the files in this archive.
	///
	/// Use this to find a file in the archive, then use the provided subscript to get the bytes of the file.
	///
	/// ```swift
	/// let bytes = Array<UInt8>(try Data(contentsOf: myURL))
	/// let reader = try CPIOArchiveReader(archive: bytes)
	/// let bytes = reader[header: reader.headers[0]]
	/// // Use bytes...
	/// ```
	///
	public var headers: [Header] = []

	/// The amount of files in this archive.
	public var count: Int { self.headers.count }

	/// The initializer reads all the `cpio` headers in preparation for random access to the header's file contents later.
	///
	/// - Parameters:
	///   - archive: The bytes of the archive you want to read.
	/// - Throws: `ArArchiveError`.
	public init(archive: [UInt8]) throws {
		guard !archive.isEmpty else { throw CPIOArchiveError.emptyArchive }

		self.data = archive

		var index = 0

		// Read all the headers so we can provide random access to the data later.
		while index < (self.data.count - 1), (index + (Constants.headerLength - 1)) < self.data.count - 1 {
			var h = try self.parseHeader(bytes: Array(self.data[index...(index + Constants.headerLength - 1)]))

			// Jump past the header.
			index += Constants.headerLength + h.namePadding - 1

			h.name = String(Array(self.data[index..<(index + h.nameSize - 1)]))

			index += h.nameSize + h.namePadding

			h.contentLocation = index

			if h.mode.isSymlink {
				h.linkName = String(self.data[h.contentLocation..<h.contentLocation + h.size])
			}

			// Jump past the content of the file.
			index += h.size + h.contentPadding

			self.headers.append(h)

			// Some interesting archives have a non-standard amount of unnecessary padding...So we must stop at the `TRAILER!!!` header.
			if h.name == Constants.trailer { break }
		}

		if let last = headers.last {
			if last.name == Constants.trailer {
				self.headers = self.headers.dropLast()
			}
		} else {
			throw CPIOArchiveError.emptyArchive
		}
	}

	private func parseHeader(bytes: [UInt8]) throws -> Header {
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

		var header = Header(
			name: "",
			userID: userID,
			groupID: groupID,
			mode: FileMode(rawValue: mode),
			modificationTime: modTime,
			inode: inode,
			links: links,
			dev: (major: devMajor, minor: devMinor),
			rDev: (major: rDevMajor, minor: rDevMinor),
			checksum: nil
		)

		if hasCheckSum {
			if let c = Int(hex: String(bytes[102..<110])) {
				header.checksum = Checksum(sum: c)
			} else {
				throw CPIOArchiveError.invalidHeader
			}
		}

		header.size = size
		header.nameSize = nameSize

		return header
	}

	/// Retrieves the bytes of the item at `index`, where index is the index of the `header` stored in the `headers` property of the reader.
	///
	/// Internally, the `Header` stored at `index` is used to find the file.
	public subscript(index: Int) -> [UInt8] {
		Array(self.data[self.headers[index].contentLocation..<self.headers[index].contentLocation + self.headers[index].size])
	}

	/// Retrieves the bytes of the file described in `header`.
	///
	/// - Parameter header: The `Header` that describes the file you wish to retrieves.
	///
	/// `header` MUST be a `Header` contained in the `headers` property of this `ArArchiveReader` or else you will get a "index out of range" error.
	public subscript(header header: Header) -> [UInt8] {
		Array(self.data[header.contentLocation..<header.contentLocation + header.size])
	}
}

extension CPIOArchiveReader: IteratorProtocol, Sequence {
	public typealias Element = (Header, [UInt8])

	public mutating func next() -> Element? {
		if self.currentIndex > self.headers.count - 1 {
			return nil
		}

		let bytes = self[self.currentIndex]
		let h = self.headers[self.currentIndex]
		self.currentIndex += 1

		return (h, bytes)
	}
}
