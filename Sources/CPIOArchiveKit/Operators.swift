// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

infix operator &^

/// Bitwise AND NOT.
func &^ <T: FixedWidthInteger>(lhs: T, rhs: T) -> T {
	lhs & ~rhs
}
