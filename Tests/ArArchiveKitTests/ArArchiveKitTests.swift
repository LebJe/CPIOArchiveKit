// Copyright (c) 2024 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

@testable import ArArchiveKit
import Foundation
import XCTest

final class ArArchiveKitTests: XCTestCase {
	func testWriteSingleArchive() throws {
		let data = try Data(contentsOf: Bundle.module.url(forResource: "test-files/archive", withExtension: "a")!)

		var archive = ArArchive()
		archive.files.append(
			.init(
				header: .init(
					name: "hello.txt",
					userID: 501,
					groupID: 20,
					mode: 0o644,
					modificationTime: 1615990791
				),
				contents: "Hello, World!"
			)
		)

		XCTAssertEqual(archive.serialize(), Array(data))
	}

	func testWriteLargeMultiArchive() throws {
		var archive = ArArchive()
		archive.files.append(
			.init(
				header: .init(
					name: "hello.txt",
					userID: 501,
					groupID: 20,
					mode: 0o644,
					modificationTime: 1615990791
				),
				contents: "Hello, World!"
			)
		)

		// Generate a BIG archive.
		for i in 0..<99 {
			archive.files.append(
				.init(
					header: .init(
						name: "hello\(i).txt",
						userID: 501,
						groupID: 20,
						mode: 0o644,
						modificationTime: 1615990791
					),
					contents: Array(repeating: "Hello, World!", count: 200).joined(separator: "\n")
				)
			)
		}

		let data = try Data(contentsOf: Bundle.module.url(forResource: "test-files/multi-archive", withExtension: "a")!)

		XCTAssertEqual(Data(archive.serialize()), data)
	}

	func testReadLargeArchive() throws {
		let bytes = try Array<UInt8>(Data(contentsOf: Bundle.module.url(
			forResource: "test-files/multi-archive",
			withExtension: "a"
		)!))
		let archive = try ArArchive(data: bytes)

		XCTAssertEqual(archive.files.count, 100)
		XCTAssertEqual(String(archive.files[0].contents), "Hello, World!")
	}

	func testReadArchive() throws {
		let bytes = try Array<UInt8>(Data(contentsOf: Bundle.module.url(
			forResource: "test-files/archive",
			withExtension: "a"
		)!))
		let archive = try ArArchive(data: bytes)

		let h = archive.files[0].header

		XCTAssertEqual(h.name, "hello.txt")
		XCTAssertEqual(h.userID, 501)
		XCTAssertEqual(h.groupID, 20)
		XCTAssertEqual(h.mode, 0o644)
		XCTAssertEqual(h.modificationTime, 1615990791)
		XCTAssertEqual(h.size, 13)
	}

	func testReadBSDArchiveWithLongFilenames() throws {
		let bytes = try Array<UInt8>(Data(contentsOf: Bundle.module.url(
			forResource: "test-files/bsd-archive",
			withExtension: "a"
		)!))
		let archive = try ArArchive(data: bytes)

		let h = archive.files[0].header
		let h2 = archive.files[1].header

		let expectedHeaders: [ArArchive.Header] = [
			.init(
				name: "VeryLongFilename With Spaces.txt",
				userID: 501,
				groupID: 20,
				mode: 0o644,
				modificationTime: 1617373995
			),
			.init(
				name: "VeryLongFilenameWithoutSpaces.txt",
				userID: 501,
				groupID: 20,
				mode: 0o644,
				modificationTime: 1617373995
			),
		]

		// First header.
		XCTAssertEqual(String(archive.files[0].contents), "Contents of the first file.")
		XCTAssertEqual(h.name, expectedHeaders[0].name)
		XCTAssertEqual(h.userID, expectedHeaders[0].userID)
		XCTAssertEqual(h.groupID, expectedHeaders[0].groupID)
		XCTAssertEqual(h.mode, expectedHeaders[0].mode)
		XCTAssertEqual(h.modificationTime, expectedHeaders[0].modificationTime)
		XCTAssertEqual(h.size, 27)

		// Second header.
		XCTAssertEqual(String(archive.files[1].contents), "Contents of the second file.")
		XCTAssertEqual(h2.name, expectedHeaders[1].name)
		XCTAssertEqual(h2.userID, expectedHeaders[1].userID)
		XCTAssertEqual(h2.groupID, expectedHeaders[1].groupID)
		XCTAssertEqual(h2.mode, expectedHeaders[1].mode)
		XCTAssertEqual(h2.modificationTime, expectedHeaders[1].modificationTime)
		XCTAssertEqual(h2.size, 28)
	}

	func testWriteBSDArchiveWithLongFilenames() throws {
		var archive = ArArchive(archiveType: .bsd)

		archive.files.append(
			.init(
				header:
				.init(
					name: "VeryLongFilename With Spaces.txt",
					userID: 501,
					groupID: 20,
					mode: 0o644,
					modificationTime: 1617373995
				),
				contents: "Contents of the first file."
			)
		)

		archive.files.append(
			.init(
				header:
				.init(
					name: "VeryLongFilenameWithoutSpaces.txt",
					userID: 501,
					groupID: 20,
					mode: 0o644,
					modificationTime: 1617373995
				),
				contents: "Contents of the second file."
			)
		)

		let data = try Data(contentsOf: Bundle.module.url(forResource: "test-files/bsd-archive", withExtension: "a")!)

		XCTAssertEqual(Data(archive.serialize()), data)
	}

	func testWriteGNUArchive() throws {
		var archive = ArArchive(archiveType: .gnu)

		archive.files.append(
			.init(
				header: .init(name: "Very Long Filename With Spaces.txt", modificationTime: 1626214982),
				contents: "Hello, World!"
			)
		)

		archive.files.append(
			.init(
				header: .init(name: "Very Long Filename With Spaces 2.txt", modificationTime: 1626214982),
				contents: "Hello, Again!"
			)
		)

		archive.files.append(
			.init(
				header: .init(name: "ShortName.txt", modificationTime: 1626214982),
				contents: "Hello!"
			)
		)

		let data = try Data(contentsOf: Bundle.module.url(forResource: "test-files/gnu-archive", withExtension: "a")!)

		XCTAssertEqual(Data(archive.serialize()), data)
	}

	func testReadGNUArchive() throws {
		let data = try Array(Data(contentsOf: Bundle.module.url(forResource: "test-files/gnu-archive", withExtension: "a")!))
		let archive = try ArArchive(data: data)
		let expectedHeaders: [ArArchive.Header] = [
			.init(name: "Very Long Filename With Spaces.txt", userID: 0, groupID: 0, mode: 420, modificationTime: 1626214982),
			.init(name: "Very Long Filename With Spaces 2.txt", userID: 0, groupID: 0, mode: 420, modificationTime: 1626214982),
			.init(name: "ShortName.txt", userID: 0, groupID: 0, mode: 420, modificationTime: 1626214982),
		]

		XCTAssertEqual(archive.files[0].header.name, expectedHeaders[0].name)
		XCTAssertEqual(archive.files[0].header.userID, expectedHeaders[0].userID)
		XCTAssertEqual(archive.files[0].header.groupID, expectedHeaders[0].groupID)
		XCTAssertEqual(archive.files[0].header.mode, expectedHeaders[0].mode)
		XCTAssertEqual(archive.files[0].header.modificationTime, expectedHeaders[0].modificationTime)

		XCTAssertEqual(archive.files[1].header.name, expectedHeaders[1].name)
		XCTAssertEqual(archive.files[1].header.userID, expectedHeaders[1].userID)
		XCTAssertEqual(archive.files[1].header.groupID, expectedHeaders[1].groupID)
		XCTAssertEqual(archive.files[1].header.mode, expectedHeaders[1].mode)
		XCTAssertEqual(archive.files[1].header.modificationTime, expectedHeaders[1].modificationTime)

		XCTAssertEqual(archive.files[2].header.name, expectedHeaders[2].name)
		XCTAssertEqual(archive.files[2].header.userID, expectedHeaders[2].userID)
		XCTAssertEqual(archive.files[2].header.groupID, expectedHeaders[2].groupID)
		XCTAssertEqual(archive.files[2].header.mode, expectedHeaders[2].mode)
		XCTAssertEqual(archive.files[2].header.modificationTime, expectedHeaders[2].modificationTime)
	}

	// func testArchiveReaderSubscripts() throws {
	// 	let bytes = try Array<UInt8>(Data(contentsOf: Bundle.module.url(
	// 		forResource: "test-files/medium-archive",
	// 		withExtension: "a"
	// 	)!))
	// 	var archive = try ArArchive(data: bytes)

	// 	// Shouldn't crash
	// 	_ = reader[header: reader.headers[2]]

	// 	// Shouldn't crash
	// 	_ = reader[2]
	// }

	// func testIterateArchiveContents() throws {
	// 	let bytes = try Array<UInt8>(Data(contentsOf: Bundle.module.url(
	// 		forResource: "test-files/multi-archive",
	// 		withExtension: "a"
	// 	)!))
	// 	var archive = try ArArchive(data: bytes)

	// 	for (_, _) in reader {
	// 		// This shouldn't crash.
	// 	}
	// }
}
