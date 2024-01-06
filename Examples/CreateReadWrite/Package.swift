// swift-tools-version:5.5

import PackageDescription

let package = Package(
	name: "CreateReadWrite",
	platforms: [.macOS(.v10_15)],
	products: [
		.executable(name: "create", targets: ["CreateArchive"]),
		.executable(name: "read", targets: ["ReadArchive"]),
		.executable(name: "extract", targets: ["ExtractArchive"]),
		.executable(name: "chksum", targets: ["ComputeChecksum"]),
	],
	dependencies: [.package(name: "ArchiveKit", path: "../../")],
	targets: [
		.target(
			name: "Utilities",
			dependencies: [
				.product(name: "CPIOArchiveKit", package: "ArchiveKit"),
			]
		),
		.target(
			name: "CreateArchive",
			dependencies: [
				"Utilities",
				.product(name: "CPIOArchiveKit", package: "ArchiveKit"),
				.product(name: "ArArchiveKit", package: "ArchiveKit"),
			]
		),
		.target(
			name: "ReadArchive",
			dependencies: [
				"Utilities",
				.product(name: "CPIOArchiveKit", package: "ArchiveKit"),
				.product(name: "ArArchiveKit", package: "ArchiveKit"),
			]
		),
		.target(
			name: "ExtractArchive",
			dependencies: [
				"Utilities",
				.product(name: "CPIOArchiveKit", package: "ArchiveKit"),
				.product(name: "ArArchiveKit", package: "ArchiveKit"),
			]
		),
		.target(
			name: "ComputeChecksum",
			dependencies: [
				.product(name: "CPIOArchiveKit", package: "ArchiveKit"),
			]
		),
	]
)
