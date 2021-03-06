# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0](https://github.com/LebJe/CPIOArchiveKit/releases/tag/0.1.0) - 2021-07-21

### Added

-   Added `FileMode.type` to get the `FileType` from `FileMode`.
-   Added `FileMode.rawType` to get the file type bits from `FileMode`.
-   Added a `clear` parameter to `CPIOArchiveWriter.finalize`, if set, this will reset the state of the writer so it can be used again.
-   Added CreateArchive, WriteArchive, and ExtractArchive to the examples.

### Removed

-   Removed `FileType.dir`. It has been renamed to `directory`.

### Migration Guide

Use `FileMode.is(_:)` instead of `isSymlink`, and `isRegularFile`:

```swift
// Before
if header.mode.isSymlink {
	// `header` describes a symbolic link.
}

// After
if header.mode.is(.symlink) {
	// `header` describes a symbolic link.
}
```

## [0.0.3](https://github.com/LebJe/CPIOArchiveKit/releases/tag/0.0.3) - 2021-06-22

### Added

-   Added `CPIOArchiveReaderIterator`.

## [0.0.2](https://github.com/LebJe/CPIOArchiveKit/releases/tag/0.0.2) - 2021-06-11

### Added

-   `Header` now conforms to `Codable` and `Equatable`.
-   `CPIOArchiveReader` now has a `count` property.

## [0.0.1](https://github.com/LebJe/CPIOArchiveKit/releases/tag/0.0.1) - 2021-05-16

### Added

Support reading and writing `cpio` archives.
