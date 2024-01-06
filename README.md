# ArchiveKit

**A simple, 0-dependency Swift package for reading and writing [`cpio`](https://en.wikipedia.org/wiki/Cpio) and [`ar`](<https://en.wikipedia.org/wiki/Ar_(Unix)>) archives. Inspired by [go-cpio](https://github.com/cavaliercoder/go-cpio) and [ar](https://github.com/blakesmith/ar).**

[![Swift 5.5](https://img.shields.io/badge/Swift-5.5-brightgreen?logo=swift)](https://swift.org)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![](https://img.shields.io/github/v/tag/LebJe/CPIOArchiveKit)](https://github.com/LebJe/CPIOArchiveKit/releases)
[![Build and Test](https://github.com/LebJe/ArchiveKit/workflows/Build%20and%20Test/badge.svg)](https://github.com/LebJe/CPIOArchiveKit/actions?query=workflow%3A%22Build+and+Test%22)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FLebJe%2FArchiveKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/LebJe/CPIOArchiveKit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FLebJe%2FArchiveKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/LebJe/ArchiveKit)

# Table of Contents

<!--ts-->

-   [ArchiveKit](#archivekit)
-   [Table of Contents](#table-of-contents)
    -   [Documentation](#documentation)
    -   [Installation](#installation)
        -   [Swift Package Manager](#swift-package-manager)
    -   [Ar Archives (ArArchiveKit)](#ar-archives-ararchivekit)
        -   [Writing Archives](#writing-archives)
        -   [Reading Archives](#reading-archives)
    -   [CPIO Archives (CPIOArchiveKit)](#cpio-archives-cpioarchivekit)
        -   [Writing Archives](#writing-archives-1)
            -   [Checksums](#checksums)
                -   [Computed Checksum](#computed-checksum)
                -   [Pre-computed Checksum](#pre-computed-checksum)
        -   [Reading Archives](#reading-archives-1)
            -   [CPIOFileMode](#cpiofilemode)
            -   [File Type](#file-type)
            -   [Permissions](#permissions)
    -   [Examples](#examples)
    -   [Contributing](#contributing)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->
<!-- Added by: lebje, at: Fri Jan  5 19:38:07 EST 2024 -->

<!--te-->

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc.go)

## Documentation

[Documentation for CPIOArchiveKit](https://swiftpackageindex.com/LebJe/ArchiveKit/0.3.0/documentation/cpioarchivekit)
[Documentation for ArArchiveKit](https://swiftpackageindex.com/LebJe/ArchiveKit/0.3.0/documentation/cpioarchivekit)

## Installation

### Swift Package Manager

Add this to the `dependencies` array in `Package.swift`:

```swift
.package(url: "https://github.com/LebJe/ArchiveKit.git", from: "0.2.0")
```

Also add this to the `targets` array in the aforementioned file:

```swift
// CPIO Archives
.product(name: "CPIOArchiveKit", package: "ArchiveKit")

// AR Archives
.product(name: "ArArchiveKit", package: "ArchiveKit")
```

## Ar Archives (ArArchiveKit)

## `ar` Variations

ArArchiveKit supports the "Common", BSD, and SVR4/GNU variations of `ar` as described in [FreeBSD manpages](https://www.freebsd.org/cgi/man.cgi?query=ar&sektion=5).

Support for symbol tables may come soon.

### Writing Archives

To write archives, create a `ArArchive`:

```swift
// Use either `.common`, `.bsd`, or `.gnu`
var archive = ArArchive(archiveType: .common)
```

Next, create a `Header`, that describes the file you wish to add to your archive:

```swift
var time: Int = 1615929568

// You can also use Date
let date: Date = ...
time = Int(date.timeIntervalSince1970)

let header = Header(
	// `name` will be truncated to 16 characters.
	name: "hello.txt",
	modificationTime: time
)
```

Once you have your `Header`, you can write it, along with the contents of your file, to the archive:

```swift
// Without Foundation
var contents = Array("Hello".utf8)

// With Foundation

let myData: Data = "Hello".data(using .utf8)!

contents = Array<UInt8>(myData)

archive.files.append(.init(header: header, contents: contents))
```

If you have a text file, use the overloaded version of `addFile`:

```swift
archive.files.append(.init(header: header, contents: "Hello"))
```

Once you have added your files, you can get the archive like this:

```swift
// Call `serialize` to get the binary representation (Array<UInt8>) of the archive.
let bytes = archive.serialize()

// You convert it to data like this:
let data = Data(bytes)

// And write it:
try data.write(to: URL(fileURLWithPath: "myArchive.a"))
```

### Reading Archives

To read archives, call `ArArchive.init(data:)`:

```swift
// myData is the bytes of the archive.
let archiveData: Data = ...

let archive = ArArchive(data: Array<UInt8>(archiveData))
```

Then, access the archive's files through the `files` property.

```swift
for file in archive.files {
   print("Name: \(file.header.name)")
   print("Modification Time: \(file.header.modificationTime)")
   print("Size: \(file.header.size)")
   print("Contents: \(file.contents)")
}
```

## CPIO Archives (CPIOArchiveKit)

### Writing Archives

To write archives, create a `CPIOArchive`:

```swift
/// Use `.svr4WithCRC` if you are adding files with checksums.
var archive = CPIOArchive(archiveType: .svr4)
```

Next, create a `Header`, that describes the file you wish to add to your archive:

```swift
var time: Int = 1615929568

// You can also use date
let date: Date = ...
time = Int(date.timeIntervalSince1970)

// File
let header = CPIOArchive.Header(
   name: "hello.txt",
   mode: CPIOFileMode(0o644, modes: [.regular]),
   modificationTime: time
)

// Directory
let header = CPIOArchive.Header(
   name: "dir/",
   mode: CPIOFileMode(0o644, modes: [.directory]),
   modificationTime: time
)
```

#### Checksums

If you would like to provide a `cpio` checksum with the `Header` you created above, there are two ways to do so.

##### Computed Checksum

```swift
// Compute the checksum.
let fileContents: [UInt8] = ...
let checksum = Checksum(bytes: fileContents)
```

##### Pre-computed Checksum

```swift
let preComputedChecksum = 123
let checksum = Checksum(sum: preComputedChecksum)
l
```

Once you have a `checksum`, add it to the checksum parameter of your `Header`:

```swift
CPIOArchive.Header(..., checksum: checksum, ...)
```

Once you have your `Header`, you can add it, along with the contents of your file, to the archive:

```swift
// Without Foundation
var contents = Array("Hello".utf8)

// With Foundation
let myData: Data = "Hello".data(using .utf8)!
contents = Array<UInt8>(myData)

writer.files.append(CPIOArchive.File(header: header, contents: contents))
```

If you have a text file, use the overloaded version of `CPIOArchive.File.init`:

```swift
writer.files.append(CPIOArchive.File(header: header, contents: "Hello"))
```

> For directories, omit the `contents` parameter in `CPIOArchive.File.init`. For symlinks, set the `contents` parameter to the file or directory the link points to.

Once you have added your files, call `serialize()` to create the archive and return the data:

```swift
// Generate the`cpio` archive.
let bytes = archive.serialize()

// You can convert it to `Data` like this:
let data = Data(bytes)

// And write it:
try data.write(to: URL(fileURLWithPath: "myArchive.cpio"))
```

### Reading Archives

To read archives, call `CPIOArchive.init(data:)`:

```swift
// myData is the bytes of the archive.
let myData: Data = ...

let archive = CPIOArchive(data: Array<UInt8>(myData))
```

Then, access the archive's files through the `files` property.

#### `CPIOFileMode`

Once you have retrieved a `CPIOFileMode` from a `Header` in a `CPIOArchive.File`, you can access the file's type and UNIX permissions.

#### File Type

```swift
let type = header.mode.type

switch type {
	case .regular: // Regular file.
	case .directory: // Directory.
	case .symlink: // Symbolic link.
	...
}
```

#### Permissions

To access the UNIX permissions, use the `permissions` variable in `CPIOFileMode`.

## Examples

-   `Examples/CreateReadWrite`: This example shows how to use ArchiveKit to read, create, or extract an archive; or compute a checksum for an archive using only `Darwin.C` (macOS), `Glibc` (Linux) or `ucrt` (Windows (not tested)).

## Contributing

Before committing, please install [pre-commit](https://pre-commit.com), [swift-format](https://github.com/nicklockwood/SwiftFormat), and [Prettier](https://prettier.io), then install the pre-commit hook:

```bash
$ brew bundle # install the packages specified in Brewfile
$ pre-commit install

# Commit your changes.
```

To install pre-commit on other platforms, refer to the [documentation](https://pre-commit.com/#install).
