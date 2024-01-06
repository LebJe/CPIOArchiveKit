// Copyright (c) 2024 Jeff Lebrun
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

	/// if `self` is smaller than `size`, `self` is padded with spaces until `size` is reached. Then an ASCII array of the
	/// padded string is returned
	func asciiArrayWithPadding(size: Int) -> [UInt8] {
		var s = self

		while s.count < size {
			s = s + " "
		}

		return s.asciiArray
	}

	/// Extracts the filenames from the GNU archive name table in this String and generates the offsets to those filenames.
	///
	/// - Returns: A `Dictionary<Int, String>`, whose keys are the filename offsets, and whose values are the filenames.
	///
	/// Before:
	///
	/// ```
	/// Very Long Filename With Spaces.txt/
	/// Very Long Filename With Spaces 2.txt/
	/// ```
	///
	/// After:
	///
	/// ```swift
	/// [
	///     0: "Very Long Filename With Spaces.txt",
	///     36: "Very Long Filename With Spaces 2.txt"
	/// ]
	/// ```
	var asGNUNamesTable: [Int: String] {
		var offsetsAndNames: [Int: String] = [:]
		var offset = 0
		var names: [String] = []
		var currentName = ""
		var skipNextChar = false

		// Collect all the names.
		for i in 0..<self.count {
			if skipNextChar {
				skipNextChar = false
				continue
			}

			if
				self[self.index(self.startIndex, offsetBy: i)] == "/",
				let index = self.index(self.startIndex, offsetBy: i + 1, limitedBy: self.endIndex),
				self[index] == "\n"
			{
				skipNextChar = true
				names.append(currentName)
				currentName = ""
			} else {
				currentName.append(self[self.index(self.startIndex, offsetBy: i)])
			}
		}

		for name in names {
			offsetsAndNames[offset] = name

			offset += name.count + 3
		}

		return offsetsAndNames
	}

	/// Initialize `String` from an array of bytes.
	public init(_ bytes: [UInt8]) {
		self = String(bytes.map({ Character(Unicode.Scalar($0)) }))
	}

	// From https://gist.github.com/budidino/8585eecd55fd4284afaaef762450f98e .
	///
	/// Truncates the string to the specified length number of characters and appends an optional trailing string if
	/// longer.
	/// - Parameter length: Desired maximum lengths of a string
	/// - Parameter trailing: A 'String' that will be appended after the truncation.
	///
	/// - Returns: 'String' object.
	func truncate(length: Int, trailing: String = "") -> String {
		(self.count > length) ? self.prefix(length) + trailing : self
	}
}

extension BinaryInteger {
	///
	func toBytesWithPadding(size: Int, radix: Int? = nil, prefix: String? = nil) -> [UInt8] {
		if let r = radix {
			return ((prefix != nil ? prefix! : "") + String(self, radix: r)).asciiArrayWithPadding(size: size)
		} else {
			return ((prefix != nil ? prefix! : "") + String(self)).asciiArrayWithPadding(size: size)
		}
	}
}

extension Array where Self.Element == UInt8 {
	var string: String {
		/// From [blakesmith/ar/reader.go: line
		/// 62](https://github.com/blakesmith/ar/blob/809d4375e1fb5bb262c159fc3ec2e7a86a8bfd28/reader.go#L62).

		if self.count == 1 {
			return String(Character(Unicode.Scalar(self[0])))
		}

		var i = self.count - 1

		while i > 0, self[i] == 32 /* ASCII space character */ {
			i -= 1
		}

		return String(self[0...i].map({ Character(Unicode.Scalar($0)) }))
	}

	func int(radix: Int? = nil) -> Int? {
		var s = self.string.filter({ $0 != " " })
		if s == "" { s = "0" }

		if let r = radix {
			return Int(s, radix: r)
		} else {
			return Int(s)
		}
	}
}
