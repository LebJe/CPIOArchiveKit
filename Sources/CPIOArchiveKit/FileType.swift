// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// `FileType` specifies the type of file in an archive.
///
/// Documentation comments are taken from [FreeBSD's man pages](https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+13.0-current).
public enum FileType: UInt32 {
	/// SUID bit.
	case setUID = 0o4000

	/// SGID bit.
	case setGID = 0o2000

	/// Sticky bit.  On some systems, this modifies the behavior of executables and/or directories.
	case sticky = 0o1000

	/// File type value for directories.
	case dir = 0o40000

	/// File type value for named pipes or FIFOs.
	case namedPipe = 0o10000

	/// File type value for regular files.
	case regular = 0o100000

	/// File type value for symbolic links.  For symbolic links, the link body is stored as file data.
	case symlink = 0o120000

	/// File type value for block special devices.
	case device = 0o60000

	/// File type value for character special devices.
	case charDevice = 0o20000

	/// File type value for sockets.
	case socket = 0o140000

	/// This masks the file type bits.
	case type = 0o170000

	/// The lower	9 bits specify read/write/execute permissions
	/// for world, group,	and user following standard POSIX conventions.
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
	///   - modes: Attributes that describe the file. For example, if you wanted to specify that this file is actually a directory, you would add the `.dir` attribute. If it is also a symlink, you would add the `.symlink` attribute.
	public init(_ permissions: UInt32, modes: [FileType] = []) {
		self.rawValue = permissions
		modes.forEach({ self.rawValue |= $0.rawValue })
	}

	/// Whether this `FileMode` describes a directory.
	public var isDirectory: Bool {
		(self.rawValue & FileType.dir.rawValue) != 0
	}

	/// Whether this `FileMode` describes a symlink.
	var isSymlink: Bool {
		(self.rawValue &^ FileType.permissions.rawValue) == FileType.symlink.rawValue
	}

	/// Whether this `FileMode` describes a regular file (not a symlink, directory, etc).
	public var isRegularFile: Bool {
		(self.rawValue &^ FileType.permissions.rawValue) == FileType.regular.rawValue
	}

	/// The UNIX permissions of this `FileMode`.
	public var permissions: FileMode {
		FileMode(rawValue: self.rawValue & FileType.permissions.rawValue)
	}
}
