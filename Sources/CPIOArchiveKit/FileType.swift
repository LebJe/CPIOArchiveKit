// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// `FileType` specifies the type of file in an archive.
///
/// Documentation comments are taken from [FreeBSD's man pages](https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+13.0-current).
public enum FileType: UInt32, Codable, Equatable, CaseIterable {
	/// SUID bit.
	case setUID = 0o4000

	/// SGID bit.
	case setGID = 0o2000

	/// Sticky bit. On some systems, this modifies the behavior of executables and/or directories.
	case sticky = 0o1000

	/// File type value for directories.
	case directory = 0o40000

	/// File type value for named pipes or FIFOs.
	case namedPipe = 0o10000

	/// File type value for regular files.
	case regular = 0o100000

	/// File type value for symbolic links. For symbolic links, the link body is stored as file data.
	case symlink = 0o120000

	/// File type value for block special devices.
	case device = 0o60000

	/// File type value for character special devices.
	case charDevice = 0o20000

	/// File type value for sockets.
	case socket = 0o140000

	/// This masks the file type bits.
	///
	/// ```swift
	/// if (reader.headers[0].mode.rawValue & FileType.type.rawValue) == FileType.regular.rawValue {
	/// 	// reader.headers[0] describes a file.
	/// }
	/// ```
	case type = 0o170000

	/// The lower 9 bits specify read/write/execute permissions
	/// for world, group, and user following standard POSIX conventions.
	case permissions = 0o777
}

/// A `FileMode` contains a file's permissions and file type.
public struct FileMode: RawRepresentable, Equatable {
	public typealias RawValue = UInt32

	public var rawValue: UInt32

	public init(rawValue: UInt32) { self.rawValue = rawValue }

	/// Creates a `FileMode`.
	/// - Parameters:
	///   - permissions: The UNIX file permissions.
	///   - modes: `FileType`s that describe the file.
	/// 	For example, if you wanted to specify that this `FileMode` describes a directory, you would add the `.dir` type. If it is also a symlink, you would add the `.symlink` type.
	public init(_ permissions: UInt32, modes: Set<FileType> = [.regular]) {
		self.rawValue = permissions
		modes.forEach({ self.rawValue |= $0.rawValue })
	}

	/// Check whether this `FileMode` is `type`.
	///
	/// ```swift
	/// if myHeader.mode.is(.directory) {
	///     // myHeader describes a directory.
	/// } else if myHeader.mode.is(.file) {
	///     // myHeader describes a file.
	/// } else if ...
	/// ```
	public func `is`(_ type: FileType) -> Bool {
		(self.withoutPermissions & FileType.type.rawValue) == type.rawValue
	}

	/// The UNIX permissions of this `FileMode`.
	public var permissions: UInt32 {
		self.rawValue & FileType.permissions.rawValue
	}

	/// The `FileType` of `self`.
	///
	/// ```swift
	/// switch header.mode.type {
	/// 	case .directory: // Directory.
	/// 	case .regular: // Regular File.
	/// 	case .symlink: // Symbolic Link.
	///		...
	/// 	case nil:
	/// 		// unknown type.
	/// }
	/// ```
	public var type: FileType? {
		FileType(rawValue: self.rawType)
	}

	/// The file type bits in `self.rawValue`, or, in other words, the raw version of `self.type`.
	public var rawType: UInt32 {
		self.withoutPermissions & FileType.type.rawValue
	}

	/// `self.rawValue` without the UNIX permissions.
	private var withoutPermissions: UInt32 {
		self.rawValue &^ FileType.permissions.rawValue
	}
}
