// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// The `cpio` header.
///
/// This header is placed directly before the contents of a file in the archive to
/// provide information such as the size of the file, the file's name, it's permissions, etc.
public struct Header {
	/// The file's name.
	public internal(set) var name: String

	/// The ID of the user the file belonged to when it was on the filesystem.
	public internal(set) var userID: Int = 0

	/// The ID of the group the file belonged to when it was on the filesystem.
	public internal(set) var groupID: Int = 0

	/// The permissions and attributes of the file.
	public internal(set) var mode: FileMode

	/// The last time this file was modified.
	///
	/// Use `Int(myDate.timeIntervalSince1970)` to set `modificationTime` from a `Date`.
	public let modificationTime: Int

	/// The inode (index node) of this file. More information is available on [Wikipedia](https://en.wikipedia.org/wiki/Inode).
	public internal(set) var inode: Int?

	/// The number of links to this file. Directories always have a
	/// value of at least two here.  Note that hardlinked files include
	/// file data with every copy in the archive.
	///
	/// (Documentation from [https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+12.2-RELEASE](https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+12.2-RELEASE))
	public internal(set) var links: Int = 1

	/// If this `Header` describes a symlink, then `linkName` will contain the name of the linked file.
	public internal(set) var linkName: String?

	/// The device number of this file when it was on the filesystem.
	public internal(set) var dev: (major: Int?, minor: Int?) = (nil, nil)

	/// For block special and character special entries, this field contains the associated device number.
	///
	/// (Documentation from [https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+12.2-RELEASE](https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+12.2-RELEASE))
	public internal(set) var rDev: (major: Int, minor: Int) = (0, 0)

	/// "...[T]he [checksum] field is set to the sum of all bytes in the file data. This sum is computed [by] treating all bytes as unsigned values and using unsigned arithmetic.
	///  Only the least-significant 32 bits of the sum are stored."
	///
	/// (Documentation from [https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+12.2-RELEASE](https://www.freebsd.org/cgi/man.cgi?query=cpio&sektion=5&manpath=FreeBSD+12.2-RELEASE))
	public internal(set) var checksum: Checksum?

	/// The size of the file.
	///
	/// This variable is only set when reading in an archive header.
	public internal(set) var size: Int = 0

	internal var contentLocation: Int = 0
	internal var nameSize: Int = 0
	internal var startingLocation: Int?
	internal var endingLocation: Int?

	internal var namePadding: Int {
		(4 - ((Constants.headerLength + self.name.count + 1) % 4)) % 4
	}

	internal var contentPadding: Int {
		(4 - (self.size % 4)) % 4
	}

	public init(
		name: String,
		userID: Int = 0,
		groupID: Int = 0,
		mode: FileMode,
		modificationTime: Int,
		inode: Int? = nil,
		links: Int = 1,
		dev: (major: Int?, minor: Int?) = (nil, nil),
		rDev: (major: Int, minor: Int) = (0, 0),
		checksum: Checksum? = nil
	) {
		self.name = name
		self.userID = userID
		self.groupID = groupID
		self.mode = mode
		self.modificationTime = modificationTime
		self.inode = inode
		self.links = links
		self.dev = dev
		self.rDev = rDev
		self.checksum = checksum
	}
}
