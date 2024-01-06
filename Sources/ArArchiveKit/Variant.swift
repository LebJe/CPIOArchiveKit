// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// The different formats of the `ar` archive.
public enum ArArchiveVariant {
	/// The "common" format. This format is used by Debian `deb` packages.
	case common

	/// Used by the BSD and MacOS implementation of the `ar` command. This format is backwards-compatible with the "common"
	/// format.
	case bsd

	/// The System V (or GNU) variant. Used by the GNU implementation of the `ar` command, and on Windows.
	/// This format is **not** backwards-compatible with the "common" format.
	case gnu
}
