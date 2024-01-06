// swift-tools-version:5.5

import PackageDescription

let package = Package(
	name: "ArchiveKit",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v13),
		.tvOS(.v12),
		.watchOS(.v7),
	],
	products: [
		.library(
			name: "CPIOArchiveKit",
			targets: ["CPIOArchiveKit"]
		),
		.library(
			name: "ArArchiveKit",
			targets: ["ArArchiveKit"]
		),
	],
	dependencies: [],
	targets: [
		.target(
			name: "CPIOArchiveKit",
			dependencies: ["ArchiveTypes"]
		),
		.target(
			name: "ArArchiveKit",
			dependencies: ["ArchiveTypes"]
		),
		.target(name: "ArchiveTypes"),
		.testTarget(
			name: "CPIOArchiveKitTests",
			dependencies: ["CPIOArchiveKit"],
			resources: [.copy("test-files/")]
		),
		.testTarget(
			name: "ArArchiveKitTests",
			dependencies: ["ArArchiveKit"],
			resources: [.copy("test-files/")]
		),
	]
)
