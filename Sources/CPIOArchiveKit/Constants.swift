// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

enum Constants {
	static let headerLength = 110
	static let nameSize = 4096
	static let maxFileSize = 4294967295

	/// The name of the last file in an archive.
	static let trailer = "TRAILER!!!"
}
