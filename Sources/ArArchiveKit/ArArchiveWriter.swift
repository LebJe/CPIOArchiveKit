// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

extension ArArchive {
	/// `ArArchiveWriter` creates `ar` files.
	///
	/// ```swift
	/// import Foundation
	///
	/// var writer = ArArchiveWriter()
	/// writer.addFile(header: Header(name: "hello.txt", modificationTime: Int(Date().timeIntervalSince1970)), contents:
	/// "Hello, World!")
	/// let data = Data(writer.finalize())
	/// ```
	struct ArArchiveWriter {
		/// The raw bytes of the archive.
		private var bytes: [UInt8] = []

		public let variant: ArArchiveVariant

		private var headers: [Header] = []
		private var files: [[UInt8]] = []

		/// The archive entry used in GNU `ar` to store filenames longer the 15 characters.
		private var longGNUFilenamesEntry: File = .init(header: Header(name: "//", modificationTime: 0))

		private var hasLongGNUFilenames = false
		private var longGNUFilenamesEntryIndex = 0

		public init(variant: ArArchiveVariant = .common) {
			self.variant = variant
		}

		private mutating func write(_ newBytes: [UInt8]) {
			self.bytes += newBytes
			if newBytes.count % 2 != 0 {
				self.bytes += "\n".asciiArray
			}
		}

		private mutating func addMagicBytes() {
			self.write(Constants.globalHeader.asciiArray)
		}

		/// Adds a `Header` to the archive.
		private mutating func addHeader(header: Header, contentSize: Int) {
			var header = header
			header.size = contentSize
			self.headers.append(header)
		}

		/// Add a file to the archive.
		/// - Parameters:
		///   - header: The header that describes the file.
		///   - contents: The raw bytes of the file.
		public mutating func addFile(header: Header, contents: [UInt8]) {
			if self.variant == .gnu, header.name.count > 15 {
				self.hasLongGNUFilenames = true
			}
			self.addHeader(header: header, contentSize: contents.count)
			self.files.append(contents)
		}

		/// Wrapper function around `ArArchiveWriter.addFile(header:contents:)` which allows you to pass in a `String` instead
		/// of raw bytes.
		public mutating func addFile(header: Header, contents: String) {
			self.addFile(header: header, contents: Array(contents.utf8))
		}

		/// Creates an archive and returns the bytes of the created archive.
		/// - Parameter clear: Whether the data in `self.bytes` and `self.headers` should be cleared. If `clear` is `true`,
		/// then you can reuse this `ArArchiveWriter`.
		/// - Returns: The bytes of the created archive.
		public mutating func finalize(clear: Bool = true) -> [UInt8] {
			self.addMagicBytes()

			var headerBytes: [[UInt8]] = []

			for i in 0..<self.headers.count {
				headerBytes.append(self.headers[i].serialize(
					archiveType: self.variant,
					contentSize: self.headers[i].size,
					hasLongGNUFilenames: &self.hasLongGNUFilenames,
					longGNUFilenamesEntry: &self.longGNUFilenamesEntry,
					longGNUFilenamesEntryIndex: &self.longGNUFilenamesEntryIndex,
					bytesEndIndex: self.bytes.endIndex
				))
			}

			// Add the `//` entry if there are long filenames.
			if self.variant == .gnu, self.hasLongGNUFilenames {
				self.bytes += self.longGNUFilenamesEntry.header.serialize(
					archiveType: self.variant,
					contentSize: self.longGNUFilenamesEntry.contents.count,
					hasLongGNUFilenames: &self.hasLongGNUFilenames,
					longGNUFilenamesEntry: &self.longGNUFilenamesEntry,
					longGNUFilenamesEntryIndex: &self.longGNUFilenamesEntryIndex,
					bytesEndIndex: self.bytes.endIndex
				)
				self.bytes += self.longGNUFilenamesEntry.contents
			}

			for i in 0..<headerBytes.count {
				self.bytes += headerBytes[i]
				self.write(self.files[i])
			}

			if clear {
				let b = self.bytes

				self.bytes = []
				self.headers = []

				return b
			} else {
				return self.bytes
			}
		}
	}
}
