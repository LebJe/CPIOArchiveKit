// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

extension String {
	var utf8Array: [UInt8] {
		Array(self.utf8)
	}

	var asciiArray: [UInt8] {
		Array(self.map({ $0.asciiValue! }))
	}

	/// Initialize `String` from an array of bytes.
	public init(_ ascii: [UInt8]) {
		self = String(ascii.map({ Character(Unicode.Scalar($0)) }))
	}

	/// Initialize `String` from an array of bytes.
	public init(_ ascii: ArraySlice<UInt8>) {
		self = String(ascii.map({ Character(Unicode.Scalar($0)) }))
	}

	func leftPadding(to length: Int, with padding: String = "0") -> String {
		guard length > self.count else { return self }
		return String(repeating: padding, count: length - self.count) + self
	}

	// From https://gist.github.com/budidino/8585eecd55fd4284afaaef762450f98e .
	/// Truncates the string to the specified length number of characters and appends an optional trailing string if
	/// longer.
	/// - Parameter length: Desired maximum lengths of a string
	/// - Parameter trailing: A `String` that will be appended after the truncation.
	/// - Returns: `String` object.
	func truncate(length: Int, trailing: String = "") -> String {
		(self.count > length) ? self.prefix(length) + trailing : self
	}
}

extension BinaryInteger {
	var hex: String { String(self, radix: 16, uppercase: true) }
}

extension FixedWidthInteger {
	init?(hex: String) {
		guard let number = Self(hex, radix: 16) else { return nil }

		self = number
	}
}
