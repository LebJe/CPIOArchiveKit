// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

public protocol Archive {
	associatedtype ArchiveError: Error
	associatedtype Header: ArchiveHeader
	associatedtype ArchiveType
	typealias File = ArchiveFile<Header>

	/// An array of all the files in the archive.
	var files: [File] { get set }

	/// The type of the archive.
	var archiveType: ArchiveType { get }

	/// Create a new archive
	init(archiveType: ArchiveType, _ files: [File])

	/// Parses the archive in `data`.
	///
	/// - Throws: ``ArchiveError``
	init(data: [UInt8]) throws

	/// Generates an archive from ``Archive/files``.
	///
	/// - Parameter type: Use this parameter to generate an archive of a different type than ``Archive/archiveType``. Leave
	/// `nil` to use ``Archive/archiveType``.
	/// - Returns: The generated archive.
	func serialize(as type: ArchiveType?) -> [UInt8]
}

public extension Archive {
	init(archiveType: ArchiveType, _ files: [File] = []) {
		self.init(archiveType: archiveType, files)
	}

	/// Generates an archive from ``Archive/files``.
	///
	/// - Parameter type: Use this parameter to generate an archive of a different type than ``Archive/archiveType``. Leave
	/// `nil` to use ``Archive/archiveType``.
	/// - Returns: The generated archive.
	func serialize(as type: ArchiveType? = nil) -> [UInt8] {
		self.serialize(as: nil)
	}
}

/// Represents a file stored in an archive.
public struct ArchiveFile<Header: ArchiveHeader> {
	/// The ``ArchiveHeader`` describing the file.
	public let header: Header

	/// The contents of the file.
	public var contents: [UInt8]

	public init(header: Header, contents: [UInt8] = []) {
		self.header = header
		self.contents = contents
	}

	/// Convenience initializer to create a file from a `String`.
	public init(header: Header, contents: String) {
		self.header = header
		self.contents = Array(contents.utf8)
	}
}

public protocol ArchiveHeader: Codable, Equatable {}
