// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

extension CPIOArchive {
	/// `CPIOArchiveReader` reads `cpio` files.
	///
	/// ```swift
	///	let bytes = Array<UInt8>(try Data(contentsOf: myURL))
	/// let reader = try CPIOArchiveReader(archive: bytes)
	/// let bytes = reader[0]
	/// let header = reader.headers[0]
	/// ```
	struct CPIOArchiveReader {
		private var data: [UInt8] = []
		private var currentIndex: Int = 0
		var archiveType: CPIOArchiveType

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
		var headers: [Header] = []

		/// The amount of files in this archive.
		var count: Int { self.headers.count }

		/// The initializer reads all the `cpio` headers in preparation for random access to the header's file contents later.
		///
		/// - Parameters:
		///   - archive: The bytes of the archive you want to read.
		/// - Throws: `CPIOArchiveError`.
		init(archive: [UInt8]) throws {
			self.data = archive
			self.archiveType = .svr4

			var index = 0

			// Read all the headers so we can provide random access to the data later.
			while index < (self.data.count - 1), (index + (Constants.headerLength - 1)) < self.data.count - 1 {
				var h = try Header(
					bytes: Array(self.data[index...(index + Constants.headerLength - 1)]),
					archiveType: &self.archiveType
				)

				// Jump past the header.
				index += Constants.headerLength + h.namePadding - 1

				h.name = String(Array(self.data[index..<(index + h.nameSize - 1)]))

				index += h.nameSize + h.namePadding

				h.contentLocation = index

				if h.mode.is(.symlink) {
					h.linkName = String(self.data[h.contentLocation..<h.contentLocation + h.size])
				}

				// Jump past the content of the file.
				index += h.size + h.contentPadding

				self.headers.append(h)

				// Some interesting archives have a non-standard amount of unnecessary padding...So we must stop at the `TRAILER!!!`
				// header.
				if h.name == Constants.trailer { break }
			}

			if let last = headers.last {
				if last.name == Constants.trailer {
					self.headers = self.headers.dropLast()
				}
			}
		}

		/// Retrieves the bytes of the item at `index`, where index is the index of the `header` stored in the `headers`
		/// property of the reader.
		///
		/// Internally, the `Header` stored at `index` is used to find the file.
		subscript(index: Int) -> [UInt8] {
			Array(
				self
					.data[self.headers[index].contentLocation..<self.headers[index].contentLocation + self.headers[index].size]
			)
		}

		/// Retrieves the bytes of the file described in `header`.
		///
		/// - Parameter header: The `Header` that describes the file you wish to retrieves.
		///
		/// `header` MUST be a `Header` contained in the `headers` property of this `ArArchiveReader` or else you will get a
		/// "index out of range" error.
		subscript(header header: Header) -> [UInt8] {
			Array(self.data[header.contentLocation..<header.contentLocation + header.size])
		}
	}
}

extension CPIOArchive.CPIOArchiveReader: Sequence {
	func makeIterator() -> CPIOArchiveReaderIterator {
		CPIOArchiveReaderIterator(archive: self)
	}
}

struct CPIOArchiveReaderIterator: IteratorProtocol {
	typealias Element = (CPIOArchive.Header, [UInt8])

	let archive: CPIOArchive.CPIOArchiveReader
	var currentIndex = 0

	mutating func next() -> Element? {
		if self.currentIndex > self.archive.headers.count - 1 {
			return nil
		}

		let bytes = self.archive[self.currentIndex]
		let h = self.archive.headers[self.currentIndex]
		self.currentIndex += 1

		return (h, bytes)
	}
}
