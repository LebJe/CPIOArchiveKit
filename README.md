# CPIOArchiveKit

**A simple, 0-dependency Swift package for reading and writing [`cpio`](https://en.wikipedia.org/wiki/Cpio) archives. Inspired by [go-cpio](https://github.com/cavaliercoder/go-cpio).**

[![Swift 5.5](https://img.shields.io/badge/Swift-5.5-brightgreen?logo=swift)](https://swift.org)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![](https://img.shields.io/github/v/tag/LebJe/CPIOArchiveKit)](https://github.com/LebJe/CPIOArchiveKit/releases)
[![Build and Test](https://github.com/LebJe/CPIOArchiveKit/workflows/Build%20and%20Test/badge.svg)](https://github.com/LebJe/CPIOArchiveKit/actions?query=workflow%3A%22Build+and+Test%22)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FLebJe%2FCPIOArchiveKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/LebJe/CPIOArchiveKit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FLebJe%2FCPIOArchiveKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/LebJe/CPIOArchiveKit)

# Table of Contents

<!--ts-->

-   [CPIOArchiveKit](#cpioarchivekit)
-   [Table of Contents](#table-of-contents)
    -   [Installation](#installation)
        -   [Swift Package Manager](#swift-package-manager)
    -   [Usage](#usage)
        -   [Writing Archives](#writing-archives)
            -   [Checksums](#checksums)
                -   [Computed Checksum](#computed-checksum)
                -   [Pre\-computed Checksum](#pre-computed-checksum)
        -   [Reading Archives](#reading-archives)
            -   [CPIOFileMode](#cpiofilemode)
            -   [File Type](#file-type)
            -   [Permissions](#permissions)
    -   [Examples](#examples)
    -   [Other Platforms](#other-platforms)
        -   [Windows](#windows)
    -   [Contributing](#contributing)

<!-- Added by: lebje, at: Wed Jul 21 10:15:16 EDT 2021 -->

<!--te-->

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc.go)

Documentation is available [here](https://lebje.github.io/CPIOArchiveKit/documentation/cpioarchivekit/).

## Installation

### Swift Package Manager

Add this to the `dependencies` array in `Package.swift`:

```swift
.package(url: "https://github.com/LebJe/CPIOArchiveKit.git", from: "0.2.0")
```

Also add this to the `targets` array in the aforementioned file:

```swift
.product(name: "CPIOArchiveKit", package: "CPIOArchiveKit")
```

## Usage

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

If you have a text file, use the overloaded version of `addFile`:

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

Then, access the archive's files through the `files` property

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

-   `Examples/CreateReadWrite`: This example shows how to use CPIOArchiveKit to read, create, or extract an archive; or compute a checksum for an archive using only `Darwin.C` (macOS), `Glibc` (Linux) or `ucrt` (Windows (not tested)).

## Other Platforms

CPIOArchiveKit doesn't depend on any library, `Foundation`, or `Darwin`/`Glibc`/`ucrt` - only the Swift standard library. It should compile on any platform where the standard library compiles.

### Windows

CPIOArchiveKit is currently being built on Windows, but not tested, as the [Swift Package Manager Resources](https://github.com/apple/swift-evolution/blob/main/proposals/0271-package-manager-resources.md) doesn't seem to work (or isn't available) on Windows.

## Contributing

Before committing, please install [pre-commit](https://pre-commit.com), [swift-format](https://github.com/nicklockwood/SwiftFormat), and [Prettier](https://prettier.io), then install the pre-commit hook:

```bash
$ brew bundle # install the packages specified in Brewfile
$ pre-commit install

# Commit your changes.
```

To install pre-commit on other platforms, refer to the [documentation](https://pre-commit.com/#install).
