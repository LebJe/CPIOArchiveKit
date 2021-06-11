// swift-tools-version:5.3

import PackageDescription

let package = Package(
	name: "CPIOArchiveKit",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v13),
		.tvOS(.v12),
		.watchOS(.v7)
	]
	,products: [
		.library(
			name: "CPIOArchiveKit",
			targets: ["CPIOArchiveKit"]
		),
	],
	dependencies: [],
	targets: [
		.target(
			name: "CPIOArchiveKit",
			dependencies: []
		),
		.testTarget(
			name: "CPIOArchiveKitTests",
			dependencies: ["CPIOArchiveKit"],
			resources: [.copy("test-files/")]
		),
	]
)
