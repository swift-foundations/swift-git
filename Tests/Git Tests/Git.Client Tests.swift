import Foundation
import Testing

@testable import Git_Foundation

extension Git.Client {
    @Suite
    struct Test {
        @Test
        func `repository state and status use typed operations`() throws {
            let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            // swift-linter:disable:next try optional
            // REASON: Foundation.FileManager.removeItem(at:) is an untyped cross-module throwing API.
            defer { try? FileManager.default.removeItem(at: root) }
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

            let client = Git.Client()
            try client.initialize(at: root.path, bare: false)

            #expect(try client.repository(at: root.path))
            #expect(try client.status(at: root.path).isEmpty)

            let top = try client.top(at: root.path)
            // `git rev-parse --show-toplevel` may spell the repository root
            // differently from `URL.path`: forward slashes and long-form
            // names on Windows (where the runner's temporary directory is an
            // 8.3 short name), a `/private` prefix on macOS. The claim is
            // that `top` names the same directory, not how it is spelled, so
            // identity is proven through the filesystem: a sentinel written
            // at the root must be visible through `top`.
            let sentinel = "Sentinel-\(UUID().uuidString).txt"
            try "sentinel\n".write(
                to: root.appending(path: sentinel),
                atomically: true,
                encoding: .utf8
            )
            #expect(FileManager.default.fileExists(atPath: "\(top)/\(sentinel)"))
        }

        @Test
        func `isolated fetch compares refs without changing source metadata`() throws {
            let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            let source = root.appending(path: "source.git")
            let probe = root.appending(path: "probe.git")
            // swift-linter:disable:next try optional
            // REASON: Foundation.FileManager.removeItem(at:) is an untyped cross-module throwing API.
            defer { try? FileManager.default.removeItem(at: root) }
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

            let client = Git.Client()
            try client.initialize(at: source.path, bare: true)
            try client.initialize(at: probe.path, bare: true)

            let ref = try Git.Ref.Name("refs/heads/main")
            let destination = try Git.Ref.Name("refs/probe/local")
            #expect(throws: Git.Client.Error.self) {
                try client.fetch(source.path, ref: ref, into: destination, at: probe.path)
            }
        }

        @Test
        func `isolated clone proves ancestry and exact object fetch`() throws {
            let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            let source = root.appending(path: "source")
            let remote = root.appending(path: "remote.git")
            let probe = root.appending(path: "probe.git")
            // swift-linter:disable:next try optional
            // REASON: Foundation.FileManager.removeItem(at:) is an untyped cross-module throwing API.
            defer { try? FileManager.default.removeItem(at: root) }
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

            let client = Git.Client()
            try client.initialize(at: source.path, bare: false)
            try command(client, ["config", "user.email", "workspace@swift.institute"], at: source)
            try command(client, ["config", "user.name", "Workspace Tests"], at: source)
            try command(client, ["branch", "-M", "main"], at: source)

            let fixture = source.appending(path: "Fixture.txt")
            try "first\n".write(to: fixture, atomically: true, encoding: .utf8)
            try command(client, ["add", "Fixture.txt"], at: source)
            try command(client, ["commit", "-m", "first"], at: source)
            let first = try client.head(at: source.path)

            try "second\n".write(to: fixture, atomically: true, encoding: .utf8)
            try command(client, ["add", "Fixture.txt"], at: source)
            try command(client, ["commit", "-m", "second"], at: source)
            let second = try client.head(at: source.path)

            try client.clone(source.path, branch: "main", bare: true, to: remote.path)
            #expect(try client.ancestor(first, of: second, at: remote.path))

            try client.initialize(at: probe.path, bare: true)
            let destination = try Git.Ref.Name("refs/probe/main")
            try client.fetch(remote.path, object: second, into: destination, at: probe.path)
            #expect(try client.head(destination.rawValue, at: probe.path) == second)
        }

        @Test
        func `exact object primitives answer from the store, not from refs`() throws {
            let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            let source = root.appending(path: "source")
            let clone = root.appending(path: "clone")
            // swift-linter:disable:next try optional
            // REASON: Foundation.FileManager.removeItem(at:) is an untyped cross-module throwing API.
            defer { try? FileManager.default.removeItem(at: root) }
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

            let client = Git.Client()
            try client.initialize(at: source.path, bare: false)
            try command(client, ["config", "user.email", "workspace@swift.institute"], at: source)
            try command(client, ["config", "user.name", "Workspace Tests"], at: source)
            try command(client, ["branch", "-M", "main"], at: source)

            let fixture = source.appending(path: "Fixture.txt")
            try "first\n".write(to: fixture, atomically: true, encoding: .utf8)
            try command(client, ["add", "Fixture.txt"], at: source)
            try command(client, ["commit", "-m", "first"], at: source)
            let first = try client.head(at: source.path)

            try "second\n".write(to: fixture, atomically: true, encoding: .utf8)
            try command(client, ["add", "Fixture.txt"], at: source)
            try command(client, ["commit", "-m", "second"], at: source)
            let second = try client.head(at: source.path)

            // Presence answers from the object store; an identifier the
            // store has never seen answers false rather than throwing.
            #expect(try client.contains(commit: first, at: source.path))
            #expect(try client.contains(commit: second, at: source.path))
            let absent = try #require(
                Git.Object.ID(rawValue: Swift.String(repeating: "a", count: 40))
            )
            #expect(try !client.contains(commit: absent, at: source.path))

            // A commit names one tree, and distinct commits over distinct
            // bytes name distinct trees.
            let firstTree = try client.tree(of: first, at: source.path)
            let secondTree = try client.tree(of: second, at: source.path)
            #expect(firstTree != secondTree)

            // A clone without checkout populates no worktree until an exact
            // detached checkout selects one commit — after which HEAD, the
            // tree identity, and a clean status all attest the exact bytes,
            // and no ref in the clone was consulted to choose them.
            try client.clone(source.path, branch: "main", checkout: false, to: clone.path)
            #expect(
                !FileManager.default.fileExists(
                    atPath: clone.appending(path: "Fixture.txt").path
                )
            )
            try client.checkout(detached: first, at: clone.path)
            #expect(try client.head(at: clone.path) == first)
            #expect(try client.tree(of: first, at: clone.path) == firstTree)
            #expect(try client.status(at: clone.path).isEmpty)
            #expect(
                try Swift.String(
                    contentsOf: clone.appending(path: "Fixture.txt"),
                    encoding: .utf8
                ) == "first\n"
            )

            // Advancing the source branch after the checkout cannot move a
            // detached head: the clone still stands at the exact object.
            try "third\n".write(to: fixture, atomically: true, encoding: .utf8)
            try command(client, ["add", "Fixture.txt"], at: source)
            try command(client, ["commit", "-m", "third"], at: source)
            #expect(try client.head(at: clone.path) == first)
        }
    }
}

/// Runs one fixture-shaping Git command through the client under test, so the
/// fixture uses the same PATH-located executable and spawn substrate on every
/// platform instead of assuming a POSIX `/usr/bin/git`.
private func command(
    _ client: Git.Client,
    _ arguments: [Swift.String],
    at directory: URL
) throws(Git.Client.Error) {
    _ = try client.bytes(arguments, at: directory.path)
}
