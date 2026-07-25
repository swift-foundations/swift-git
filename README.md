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

## Error Handling

`Git.Client` operations throw a typed `Git.Client.Error`:

```
Git.Client.Error
├── .execution                          // git executable could not be launched
├── .command(arguments:termination:     // git exited non-zero; carries argv,
│            stdout:stderr:)            //   termination, and captured output
├── .advertisement(Git.Ref.Advertisement.Error)  // malformed ref advertisement
├── .status(Git.Status.Error)          // `git status` output could not be parsed
├── .object(String)                    // unexpected object output
├── .count(String)                     // unexpected rev-count output
└── .missing(Git.Ref.Name)             // requested ref not present
```

```swift
do {
    let clean = try git.status(at: repository).isEmpty
    _ = clean
} catch .execution {
    // git is not installed or could not be launched
} catch .command(let arguments, let termination, _, let stderr) {
    _ = (arguments, termination, stderr)
} catch .advertisement(let error) {
    _ = error
} catch .status(let error) {
    _ = error
} catch .object(let detail) {
    _ = detail
} catch .count(let detail) {
    _ = detail
} catch .missing(let ref) {
    _ = ref
}
```

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at the first public release.*
<!-- END: discussion -->

---

## License

Apache 2.0. See [LICENSE](LICENSE.md).
