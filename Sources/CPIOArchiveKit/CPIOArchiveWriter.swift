// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

extension CPIOArchive {
	/// `CPIOArchiveWriter` creates `cpio` archives.
	///
	/// ```swift
	/// let writer = CPIOArchiveWriter()
	///
	/// let header = Header(
	/// 	name: "hello.txt",
	/// 	mode: CPIOFileMode(0o644),
	/// 	modificationTime: Int(Date().timeIntervalSince1970)
	/// )
	/// writer.addFile(header: header, contents: "Hello World!")
	/// writer.finalize()
	/// // Use `writer.bytes`.
	/// ```
	struct CPIOArchiveWriter {
		/// The raw bytes of the archive.
		private var bytes: [UInt8] = []

		/// The type of archive that `CPIOArchiveWriter` will create.
		let archiveType: CPIOArchiveType

		private var currentInode = 0
		private var currentDev = (major: 0, minor: 0)

		private var trailerHeader = Header(
			name: "TRAILER!!!",
			mode: CPIOFileMode(rawValue: 0o644),
			modificationTime: 0,
			links: 1
		)

		/// Creates a new `CPIOArchiveWriter`.
		/// - Parameter type: The type of `cpio` archive you would like `CPIOArchiveWriter` to create.
		init(type: CPIOArchiveType = .svr4) { self.archiveType = type }

		/// Add a file to the archive.
		/// - Parameters:
		///   - header: The header that describes the file.
		///   - contents: The raw bytes of the file.
		///
		/// ### Symlinks
		/// Add a symlink by setting `header.name` to the name you want the symlink to have, and `contents` to the name of the
		/// file you want to link to.
		mutating func addFile(header: Header, contents: [UInt8] = []) {
			var h = header

			// Regular files should have one or more links.
			h.links = h.links < 1 && h.mode.is(.regular) ? 1 : h.links

			// Make sure the file type is set.
			// From
			// [go-cpio](https://github.com/cavaliercoder/go-cpio/blob/925f9528c45e5b74f52963bd11f1988ad99a95a5/writer.go#L77).
			if (h.mode.rawValue &^ CPIOFileType.permissions.rawValue) == 0 {
				h.mode.rawValue |= CPIOFileType.regular.rawValue
			}

			self.bytes += h.serialize(
				for: self.archiveType,
				contentSize: contents.count,
				currentInode: &self.currentInode,
				currentDev: &self.currentDev
			)

			self.bytes += h.name.utf8Array + [0x00]

			// Pad the end of the filename with zeros
			let namePadding = (4 - ((Constants.headerLength + h.name.count + 1) % 4)) % 4

			self.bytes += Array(Array<UInt8>(repeating: 0, count: 4)[0..<namePadding])

			self.bytes += contents

			// Pad the end of the file with zeros
			let filePadding = (4 - (contents.count % 4)) % 4

			self.bytes += Array(Array<UInt8>(repeating: 0, count: 4)[0..<filePadding])
		}

		/// Wrapper function around `CPIOArchiveWriter.addFile(header:contents:)` which allows you to pass in a `String`
		/// instead of raw bytes.
		///
		/// ### Symlinks
		/// Add a symlink by setting `header.name` to the name you want the symlink to have, and `contents` to the name of the
		/// file you want to link to.
		mutating func addFile(header: Header, contents: String) {
			self.addFile(header: header, contents: contents.utf8Array)
		}

		/// Creates the archive and returns the bytes of the archive.
		mutating func finalize(clear: Bool = false) -> [UInt8] {
			self.addFile(header: self.trailerHeader)

			if !clear {
				return self.bytes
			} else {
				let b = self.bytes
				self.bytes = []

				return b
			}
		}
	}
}
