
/// CPIOArchive reads, creates, and edits CPIO archives.
///
/// ### Reading Files
///
/// ```swift
///	let bytes = Array<UInt8>(try Data(contentsOf: cpioFileURL))
/// let archive = try CPIOArchive(data: bytes)
/// let bytes: [UInt8] = reader.files[0].contents
/// let header: CPIOArchive.Header = reader.files[0].header
/// ```
///
/// ### Writing Files
///
/// #### Create Header
///
/// ```swift
/// let header1 = Header(
/// 	name: "hello.txt",
/// 	mode: CPIOFileMode(0o644),
/// 	modificationTime: Int(Date().timeIntervalSince1970),
/// 	checksum: Checksum(bytes: Array("Hello, World!".utf8))
/// )
///
/// let header2 = Header(
/// 	name: "dir/",
/// 	mode: CPIOFileMode(0o644, modes: [.directory]),
/// 	modificationTime: Int(Date().timeIntervalSince1970)
/// )
///
/// let header3 = Header(
/// 	name: "dir/hello.txt",
/// 	mode: CPIOFileMode(0o644),
/// 	modificationTime: Int(Date().timeIntervalSince1970)
/// )
/// ```
///
/// #### Create Archive
///
/// ```swift
/// let archive = CPIOArchive(archiveType: .svr4WithCRC, [
/// 	.init(header: header1, contents: "Hello, World!"),
/// 	.init(header: header2)
/// ])
///
/// archive.files.append(.init(header: header3, contents: "Hello, Again!"))
/// let bytes: [UInt8] = archive.serialize()
///
/// try Data(bytes).write(to: URL(fileURLWithPath: "myArchive.cpio"))
/// ```
public struct CPIOArchive {
	/// An array of all the files in the archive.
	public var files: [Self.File] = []

	public var archiveType: CPIOArchiveType

	/// Create a new archive.
	public init(archiveType: CPIOArchiveType = .svr4, _ files: [Self.File] = []) {
		self.archiveType = archiveType
		self.files = files
	}

	/// Parses the `cpio` archive in `data`.
	///
	/// - Throws: ``CPIOArchiveError``
	public init(data: [UInt8]) throws {
		let reader = try Self.CPIOArchiveReader(archive: data)
		self.files = reader.map(Self.File.init(header:contents:))
		self.archiveType = reader.archiveType
	}

	/// Generates a CPIO archive from ``CPIOArchive/files``.
	public func serialize() -> [UInt8] {
		var writer = Self.CPIOArchiveWriter(type: self.archiveType)
		self.files.forEach({ writer.addFile(header: $0.header, contents: $0.contents) })
		return writer.finalize()
	}

	/// Represents a file stored in a CPIO archive.
	public struct File {
		/// The ``CPIOArchive/Header`` describing the file.
		public let header: Header

		/// The contents of the file.
		public let contents: [UInt8]

		public init(header: Header, contents: [UInt8] = []) {
			self.header = header
			self.contents = contents
		}

		/// Convenience initializer to create a file from a `String`.
		public init(header: Header, contents: String) {
			self.header = header
			self.contents = contents.utf8Array
		}
	}
}
