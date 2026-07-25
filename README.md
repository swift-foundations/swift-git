# swift-git

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Foundation-free Git repository inspection and safe mutation through the installed Git executable.

---

## Quick Start

```swift
import Git

let git = Git.Client()
let branch = try git.branch(at: "/path/to/repository")
let clean = try git.status(at: "/path/to/repository").isEmpty
let main = try Git.Ref.Name("refs/heads/main")
let remote = try git.probe("https://github.com/example/package.git", ref: main)

print(branch, clean, remote.object)
```

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-git.git", branch: "main")
]
```

Add the product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Git", package: "swift-git")
    ]
)
```

### Requirements

- Swift 6.3+
- macOS 26+
- An installed Git executable

---

## Architecture

`Git.Client` composes [swift-process](https://github.com/swift-foundations/swift-process) with the typed representations in [swift-git-standard](https://github.com/swift-standards/swift-git-standard). It exposes repository probes, ref advertisement, status parsing, clone, fetch, fast-forward merge, branch switching, and upstream tracking without importing Foundation.

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at the first public release.*
<!-- END: discussion -->

---

## License

Apache 2.0. See [LICENSE](LICENSE.md).
