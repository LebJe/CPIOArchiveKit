// swift-tools-version:5.3

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
	dependencies: [.package(name: "CPIOArchiveKit", path: "../../")],
	targets: [
		.target(
			name: "Utilities",
			dependencies: [
				.product(name: "CPIOArchiveKit", package: "CPIOArchiveKit"),
			]
		),
		.target(
			name: "CreateArchive",
			dependencies: [
				"Utilities",
				.product(name: "CPIOArchiveKit", package: "CPIOArchiveKit"),
			]
		),
		.target(
			name: "ReadArchive",
			dependencies: [
				"Utilities",
				.product(name: "CPIOArchiveKit", package: "CPIOArchiveKit"),
			]
		),
		.target(
			name: "ExtractArchive",
			dependencies: [
				"Utilities",
				.product(name: "CPIOArchiveKit", package: "CPIOArchiveKit"),
			]
		),
		.target(
			name: "ComputeChecksum",
			dependencies: [
				.product(name: "CPIOArchiveKit", package: "CPIOArchiveKit"),
			]
		),
	]
)
