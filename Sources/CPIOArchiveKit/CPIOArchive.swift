// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import ArchiveTypes

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
///
/// #### Symlinks
/// Add a symlink by setting `CPIOArchive/Header/name` to the name you want the symlink to have, and
/// `CPIOArchive/File/contents` to the name of the
/// file you want to link to.
public struct CPIOArchive: Archive {
	public typealias ArchiveError = CPIOArchiveError
	public typealias ArchiveType = CPIOArchiveType

	/// An array of all the files in the archive.
	public var files: [File]

	public let archiveType: CPIOArchiveType

	// public init(archiveType: CPIOArchiveType, _ files: [File]) {
	// 	self.archiveType = archiveType
	// 	self.files = files
	// }

	public init(archiveType: CPIOArchiveType = .svr4, _ files: [File] = []) {
		// self.init(archiveType: archiveType, files)
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
	///
	/// - Parameter type: Use this parameter to generate an archive of a different type than ``CPIOArchive/archiveType``.
	/// Leave `nil` to use ``CPIOArchive/archiveType``.
	/// - Returns: The generated archive.
	public func serialize(as type: CPIOArchiveType? = nil) -> [UInt8] {
		var writer = Self.CPIOArchiveWriter(type: type ?? self.archiveType)
		writer.files = self.files
		return writer.serialize()
	}
}
