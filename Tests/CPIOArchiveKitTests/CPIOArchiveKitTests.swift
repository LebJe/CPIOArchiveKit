// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

@testable import CPIOArchiveKit
import XCTest

final class CPIOArchiveKitTests: XCTestCase {
	func testWriteArchive() throws {
		let archive = CPIOArchive([
			.init(
				header:
				CPIOArchive.Header(
					name: "hello.txt",
					mode: CPIOFileMode(0o644),
					modificationTime: 1620311816,
					links: 1
				),
				contents: "Hello, World!\n"
			),
			.init(
				header: CPIOArchive.Header(
					name: "hello2.txt",
					mode: CPIOFileMode(0o655),
					modificationTime: 1620311816,
					links: 1
				),
				contents: "Hello, Again!\n"
			),

			.init(
				header: CPIOArchive.Header(
					name: "symlink.txt",
					mode: CPIOFileMode(0o644, modes: [.symlink]),
					modificationTime: 1620311816,
					links: 1
				),
				contents: "hello.txt"
			),

			.init(
				header: CPIOArchive.Header(
					name: "directory/",
					mode: CPIOFileMode(0o644, modes: [.directory]),
					modificationTime: 1620311816,
					links: 1
				)
			),
		])

		XCTAssertEqual(
			Data(archive.serialize()),
			try Data(contentsOf: Bundle.module.url(forResource: "test-files/archive", withExtension: "cpio")!)
		)
	}

	func testReadArchive() throws {
		let headers = [
			CPIOArchive.Header(
				name: "hello.txt",
				mode: CPIOFileMode(0o644, modes: [.regular]),
				modificationTime: 1620311816,
				inode: 0,
				links: 1,
				dev: (major: 0, minor: 0),
				checksum: Checksum(sum: 0x473)
			),
			CPIOArchive.Header(
				name: "hello2.txt",
				mode: CPIOFileMode(0o655, modes: [.regular]),
				modificationTime: 1620311816,
				inode: 1,
				links: 1,
				dev: (major: 1, minor: 1),
				checksum: Checksum(sum: 0x44B)
			),
			CPIOArchive.Header(
				name: "symlink.txt",
				mode: CPIOFileMode(0o644, modes: [.symlink]),
				modificationTime: 1620311816,
				inode: 2,
				links: 1,
				dev: (major: 2, minor: 2)
			),
			CPIOArchive.Header(
				name: "directory/",
				mode: CPIOFileMode(0o644, modes: [.directory]),
				modificationTime: 1620311816,
				inode: 3,
				links: 1,
				dev: (major: 3, minor: 3)
			),
		]
		let archive = try CPIOArchive(data: Array(Data(contentsOf: Bundle.module.url(
			forResource: "test-files/archive",
			withExtension: "cpio"
		)!)))

		XCTAssertEqual(archive.files.count, headers.count)

		for i in 0..<headers.count {
			XCTAssertEqual(archive.files[i].header.name, headers[i].name)
			XCTAssertEqual(archive.files[i].header.mode, headers[i].mode)
			XCTAssertEqual(archive.files[i].header.userID, headers[i].userID)
			XCTAssertEqual(archive.files[i].header.groupID, headers[i].groupID)
			XCTAssertEqual(archive.files[i].header.modificationTime, headers[i].modificationTime)
			XCTAssertEqual(archive.files[i].header.inode, headers[i].inode)
			XCTAssertEqual(archive.files[i].header.dev.major, headers[i].dev.major)
			XCTAssertEqual(archive.files[i].header.dev.minor, headers[i].dev.minor)
			XCTAssertEqual(archive.files[i].header.rDev.major, headers[i].rDev.major)
			XCTAssertEqual(archive.files[i].header.rDev.minor, headers[i].rDev.minor)
			if let checksum = headers[i].checksum {
				XCTAssertEqual(Checksum(bytes: archive.files[i].contents).sum, checksum.sum)
			}
		}
	}

	func testReadBIGArchive() throws {
		let header = CPIOArchive.Header(
			name: "large.txt",
			userID: 0,
			groupID: 0,
			mode: CPIOFileMode(0o644, modes: [.regular]),
			modificationTime: 1621215500,
			inode: 32430807,
			links: 1,
			dev: (major: 0, minor: 121)
		)

		let archive = try CPIOArchive(data: Array(Data(contentsOf: Bundle.module.url(
			forResource: "test-files/big",
			withExtension: "cpio"
		)!)))

		XCTAssertEqual(archive.files[0].header.name, header.name)
		XCTAssertEqual(archive.files[0].header.mode, header.mode)
		XCTAssertEqual(archive.files[0].header.userID, header.userID)
		XCTAssertEqual(archive.files[0].header.groupID, header.groupID)
		XCTAssertEqual(archive.files[0].header.mode, header.mode)
		XCTAssertEqual(archive.files[0].header.modificationTime, header.modificationTime)
		XCTAssertEqual(archive.files[0].header.inode, header.inode)
		XCTAssertEqual(archive.files[0].header.dev.major, header.dev.major)
		XCTAssertEqual(archive.files[0].header.dev.minor, header.dev.minor)
		XCTAssertEqual(archive.files[0].header.rDev.major, header.rDev.major)
		XCTAssertEqual(archive.files[0].header.rDev.minor, header.rDev.minor)
	}
}
