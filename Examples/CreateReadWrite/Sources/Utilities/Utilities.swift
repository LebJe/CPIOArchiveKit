// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import enum CPIOArchiveKit.CPIOFileType

public func description(of type: CPIOFileType?) -> String? {
	switch type {
		case .setUID: break
		case .setGID: break
		case .sticky: break
		case .directory: return "Directory"
		case .namedPipe: return "Named Pipe"
		case .regular: return "File"
		case .symlink: return "Symbolic Link"
		case .device: return "Block Special Device"
		case .charDevice: return "Character Special Device"
		case .socket: return "Socket"
		case .type: break
		case .permissions: break
		case .none: break
	}

	return nil
}
