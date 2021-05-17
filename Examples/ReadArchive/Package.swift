// swift-tools-version:5.3

import PackageDescription

let package = Package(
	name: "ReadArchive",
	products: [
		.executable(name: "read", targets: ["ReadArchive"]),
		.executable(name: "chksum", targets: ["ComputeChecksum"]),
	],
	dependencies: [.package(path: "../../")],
	targets: [
		.target(
			name: "ReadArchive",
			dependencies: [
				.product(name: "CPIOArchiveKit", package: "CPIOArchiveKit"),
			]
		),
		.target(
			name: "ComputeChecksum",
			dependencies: [
				.product(name: "CPIOArchiveKit", package: "CPIOArchiveKit"),
			]
		),
		.testTarget(
			name: "ReadArchiveTests",
			dependencies: ["ReadArchive"]
		),
	]
)
