// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

@testable import CPIOArchiveKit
import XCTest

final class CPIOArchiveKitTests: XCTestCase {
	func testWriteArchive() throws {
		var writer = CPIOArchiveWriter()

		writer.addFile(
			header: Header(
				name: "hello.txt",
				mode: FileMode(rawValue: 0o644),
				modificationTime: 1620311816,
				links: 1
			),
			contents: "Hello, World!\n"
		)

		writer.addFile(
			header: Header(
				name: "hello2.txt",
				mode: FileMode(rawValue: 0o655),
				modificationTime: 1620311816,
				links: 1
			),
			contents: "Hello, Again!\n"
		)

		writer.addFile(
			header: Header(
				name: "symlink.txt",
				mode: FileMode(0o644, modes: [.symlink]),
				modificationTime: 1620311816,
				links: 1
			),
			contents: "hello.txt"
		)

		writer.finalize()

		XCTAssertEqual(Data(writer.bytes), try Data(contentsOf: Bundle.module.url(forResource: "test-files/archive", withExtension: "cpio")!))
	}

	func testReadArchive() throws {
		let headers = [
			Header(
				name: "hello.txt",
				mode: FileMode(rawValue: 0o644),
				modificationTime: 1620311816,
				inode: 0,
				links: 1,
				dev: (major: 0, minor: 0),
				checksum: Checksum(sum: 0x473)
			),
			Header(
				name: "hello2.txt",
				mode: FileMode(rawValue: 0o655),
				modificationTime: 1620311816,
				inode: 1,
				links: 1,
				dev: (major: 1, minor: 1),
				checksum: Checksum(sum: 0x44B)
			),
			Header(
				name: "symlink.txt",
				mode: FileMode(0o644, modes: [.symlink]),
				modificationTime: 1620311816,
				inode: 2,
				links: 1,
				dev: (major: 2, minor: 2)
			),
		]
		let reader = try CPIOArchiveReader(archive: Array(Data(contentsOf: Bundle.module.url(forResource: "test-files/archive", withExtension: "cpio")!)))

		XCTAssertEqual(reader.headers[0].name, headers[0].name)
		XCTAssertEqual(reader.headers[0].userID, headers[0].userID)
		XCTAssertEqual(reader.headers[0].groupID, headers[0].groupID)
		XCTAssertEqual(reader.headers[0].modificationTime, headers[0].modificationTime)
		XCTAssertEqual(reader.headers[0].inode, headers[0].inode)
		XCTAssertEqual(reader.headers[0].dev.major, headers[0].dev.major)
		XCTAssertEqual(reader.headers[0].dev.minor, headers[0].dev.minor)
		XCTAssertEqual(reader.headers[0].rDev.major, headers[0].rDev.major)
		XCTAssertEqual(reader.headers[0].rDev.minor, headers[0].rDev.minor)
		XCTAssertEqual(headers[0].checksum!.sum, Checksum(bytes: reader[0]).sum)

		XCTAssertEqual(reader.headers[1].name, headers[1].name)
		XCTAssertEqual(reader.headers[1].userID, headers[1].userID)
		XCTAssertEqual(reader.headers[1].groupID, headers[1].groupID)
		XCTAssertEqual(reader.headers[1].modificationTime, headers[1].modificationTime)
		XCTAssertEqual(reader.headers[1].inode, headers[1].inode)
		XCTAssertEqual(reader.headers[1].dev.major, headers[1].dev.major)
		XCTAssertEqual(reader.headers[1].dev.minor, headers[1].dev.minor)
		XCTAssertEqual(reader.headers[1].rDev.major, headers[1].rDev.major)
		XCTAssertEqual(reader.headers[1].rDev.minor, headers[1].rDev.minor)
		XCTAssertEqual(headers[1].checksum!.sum, Checksum(bytes: reader[1]).sum)

		XCTAssertEqual(reader.headers[2].name, headers[2].name)
		XCTAssertEqual(reader.headers[2].userID, headers[2].userID)
		XCTAssertEqual(reader.headers[2].groupID, headers[2].groupID)
		XCTAssertEqual(reader.headers[2].modificationTime, headers[2].modificationTime)
		XCTAssertEqual(reader.headers[2].inode, headers[2].inode)
		XCTAssertEqual(reader.headers[2].dev.major, headers[2].dev.major)
		XCTAssertEqual(reader.headers[2].dev.minor, headers[2].dev.minor)
		XCTAssertEqual(reader.headers[2].rDev.major, headers[2].rDev.major)
		XCTAssertEqual(reader.headers[2].rDev.minor, headers[2].rDev.minor)
	}

	func testReadBIGArchive() throws {
		let header = Header(
			name: "large.txt",
			userID: 0,
			groupID: 0,
			mode: FileMode(rawValue: 0o100644),
			modificationTime: 1621215500,
			inode: 32430807,
			links: 1,
			dev: (major: 0, minor: 121)
		)

		let reader = try CPIOArchiveReader(archive: Array(Data(contentsOf: Bundle.module.url(forResource: "test-files/big", withExtension: "cpio")!)))

		XCTAssertEqual(reader.headers[0].name, header.name)
		XCTAssertEqual(reader.headers[0].userID, header.userID)
		XCTAssertEqual(reader.headers[0].groupID, header.groupID)
		XCTAssertEqual(reader.headers[0].mode, header.mode)
		XCTAssertEqual(reader.headers[0].modificationTime, header.modificationTime)
		XCTAssertEqual(reader.headers[0].inode, header.inode)
		XCTAssertEqual(reader.headers[0].dev.major, header.dev.major)
		XCTAssertEqual(reader.headers[0].dev.minor, header.dev.minor)
		XCTAssertEqual(reader.headers[0].rDev.major, header.rDev.major)
		XCTAssertEqual(reader.headers[0].rDev.minor, header.rDev.minor)
	}

	func testReaderIterator() throws {
		let reader = try CPIOArchiveReader(archive: Array(Data(contentsOf: Bundle.module.url(forResource: "test-files/archive", withExtension: "cpio")!)))

		for (_, _) in reader {
			// This shouldn't crash
		}
	}

	static var allTests = [
		("Test Writing An Archive", testWriteArchive),
		("Test Reading An Archive", testReadArchive),
		("Test Reading A BIG Archive", testReadBIGArchive),
		("Test Iterator", testReaderIterator),
	]
}
