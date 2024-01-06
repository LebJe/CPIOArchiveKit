// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

extension ArArchive {
	/// `ArArchiveReader` reads `ar` files.
	///
	/// ```swift
	/// let archiveData: Data = ...
	/// let reader = ArArchiveReader(archive: Array(archiveData))
	///
	/// print("Name: \(reader.headers[0])")
	/// print("Contents:\n \(String(reader[0]))")
	/// ```
	struct ArArchiveReader {
		private var data: [UInt8]
		private var currentIndex: Int = 0

		/// The headers that describe the files in this archive.
		///
		/// Use this to find a file in the archive, then use the provided subscript to get the bytes of the file.
		///
		/// ```swift
		/// let bytes = Array<UInt8>(try Data(contentsOf: myURL))
		/// let reader = try ArArchiveReader(archive: bytes)
		/// let bytes = reader[header: reader.headers[0]]
		/// // Use bytes...
		/// ```
		///
		var headers: [Header] = []

		/// The amount of files in this archive.
		var count: Int { self.headers.count }

		/// The `Variant` of this archive.
		var variant: ArArchiveVariant

		/// The initializer reads all the `ar` headers in preparation for random access to the header's file contents later.
		///
		/// - Parameters:
		///   - archive: The bytes of the archive you want to read.
		/// - Throws: `ArArchiveError`.
		init(archive: [UInt8]) throws {
			// Validate archive.
			if archive.isEmpty {
				throw ArArchiveError.emptyArchive
			} else if archive.count < 8 {
				// The global header is missing.
				throw ArArchiveError.missingMagicBytes
			} else if Array(archive[0...7]) != Constants.globalHeader.asciiArray {
				// The global header is invalid.
				throw ArArchiveError.invalidMagicBytes
			}

			// Remove the global header from the byte array.
			self.data = Array(archive[8...])

			if self.data.isEmpty {
				throw ArArchiveError.noEntries
			}

			var index = 0

			self.variant = .common

			// Read all the headers so we can provide random access to the data later.
			while index < (self.data.count - 1), (index + (Constants.headerSize - 1)) < self.data.count - 1 {
				var h = try Header(bytes: Array(self.data[index...(index + Constants.headerSize - 1)]), archiveType: &self.variant)

				h.contentLocation = (index + Constants.headerSize) + (h.nameSize != nil ? h.nameSize! : 0)

				// Jump past the header.
				index += Constants.headerSize

				h.name = h.nameSize != nil ? String(Array(self.data[h.contentLocation - h.nameSize!..<h.contentLocation])) : h.name

				// Jump past the content of the file.
				index += (h.size % 2 != 0 ? h.size + 1 : h.size) + (h.nameSize != nil ? h.nameSize! : 0)

				self.headers.append(h)
			}

			let nameTableHeaderIndex: Int? = self.headers[0].name == "//" ? 0 : self.headers.count >= 2 ? self.headers[1]
				.name == "//" ? 1 : nil : nil

			if let nameTableHeaderIndex = nameTableHeaderIndex {
				let offsets = String(self[nameTableHeaderIndex]).asGNUNamesTable

				self.variant = .gnu

				for i in 0..<self.headers.count {
					if self.headers[i].name.first == "/", let offset = Int(String(self.headers[i].name.dropFirst())) {
						self.headers[i].name = offsets[offset] ?? self.headers[i].name
					}
				}

				self.headers.remove(at: nameTableHeaderIndex)
			}

			if self.headers[0].name == "/" {
				self.headers.remove(at: 0)
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

extension ArArchive.ArArchiveReader: Sequence {
	func makeIterator() -> ArArchiveReaderIterator {
		ArArchiveReaderIterator(archive: self)
	}
}

struct ArArchiveReaderIterator: IteratorProtocol {
	typealias Element = (ArArchive.Header, [UInt8])

	let archive: ArArchive.ArArchiveReader
	var currentIndex = 0

	mutating func next() -> (ArArchive.Header, [UInt8])? {
		if self.currentIndex > self.archive.headers.count - 1 {
			return nil
		}

		let bytes = self.archive[self.currentIndex]
		let h = self.archive.headers[self.currentIndex]
		self.currentIndex += 1

		return (h, bytes)
	}
}
