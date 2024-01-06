// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import ArchiveTypes

/// ArArchive reads, creates, and edits [ar](https://en.wikipedia.org/wiki/Ar_(Unix)) archives.
///
/// ### Reading Files
///
/// ```swift
///	let bytes = Array<UInt8>(try Data(contentsOf: arFileURL))
/// let archive = try ArArchive(data: bytes)
/// let bytes: [UInt8] = archive.files[0].contents
/// let header: ArArchive.Header = reader.files[0].header
/// ```
///
/// ### Writing Files
///
/// #### Create Header
///
/// ```swift
/// let header1 = Header(
/// 	name: "hello.txt",
/// 	mode: 0o644,
/// 	modificationTime: Int(Date().timeIntervalSince1970)
/// )
///
/// let header1 = Header(
/// 	name: "hello2.txt",
/// 	mode: 0o644,
/// 	modificationTime: Int(Date().timeIntervalSince1970)
/// )
/// ```
///
/// #### Create Archive
///
/// ```swift
/// let archive = ArArchive(archiveType: .gnu, [
/// 	.init(header: header1, contents: "Hello, World!")
/// ])
///
/// archive.files.append(.init(header: header2, contents: "Hello again!"))
/// let bytes: [UInt8] = archive.serialize()
///
/// try Data(bytes).write(to: URL(fileURLWithPath: "myArchive.a"))
/// ```
public struct ArArchive: Archive {
	public typealias ArchiveError = ArArchiveError
	public typealias ArchiveType = ArArchiveVariant

	/// An array of all the files in the archive.
	public var files: [File]

	public let archiveType: ArArchiveVariant

	// public init(archiveType: ArArchiveVariant, _ files: [File]) {
	// 	self.archiveType = archiveType
	// 	self.files = files
	// }

	public init(archiveType: ArArchiveVariant = .common, _ files: [File] = []) {
		// self.init(archiveType: archiveType, files)
		self.archiveType = archiveType
		self.files = files
	}

	/// Parses the `ar` archive in `data`.
	///
	/// - Throws: ``ArArchiveError``
	public init(data: [UInt8]) throws {
		let reader = try Self.ArArchiveReader(archive: data)
		self.files = reader.map(Self.File.init(header:contents:))
		self.archiveType = reader.variant
	}

	/// Generates an ar archive from ``ArArchive/files``.
	///
	/// - Parameter type: Use this parameter to generate an archive of a different type than ``ArArchive/archiveType``.
	/// Leave `nil` to use ``AeArchive/archiveType``.
	/// - Returns: The generated archive.
	public func serialize(as type: ArArchiveVariant? = nil) -> [UInt8] {
		var writer = Self.ArArchiveWriter(variant: type ?? self.archiveType)
		self.files.forEach({ writer.addFile(header: $0.header, contents: $0.contents) })
		return writer.finalize()
	}
}
