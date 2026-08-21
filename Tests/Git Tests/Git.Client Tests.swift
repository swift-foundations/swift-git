import Foundation
import Testing

@testable import Git_Foundation

extension Git.Client {
    @Suite
    struct Test {
        @Test
        func `repository state and status use typed operations`() throws {
            let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

            defer { try? FileManager.default.removeItem(at: root) }
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

            let client = Git.Client()
            try client.initialize(at: root.path, bare: false)

            #expect(try client.repository(at: root.path))
            #expect(try client.status(at: root.path).isEmpty)

            let top = try client.top(at: root.path)

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

            #expect(try client.contains(commit: first, at: source.path))
            #expect(try client.contains(commit: second, at: source.path))
            let absent = try #require(
                Git.Object.ID(rawValue: Swift.String(repeating: "a", count: 40))
            )
            #expect(try !client.contains(commit: absent, at: source.path))

            let firstTree = try client.tree(of: first, at: source.path)
            let secondTree = try client.tree(of: second, at: source.path)
            #expect(firstTree != secondTree)

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

            try "third\n".write(to: fixture, atomically: true, encoding: .utf8)
            try command(client, ["add", "Fixture.txt"], at: source)
            try command(client, ["commit", "-m", "third"], at: source)
            #expect(try client.head(at: clone.path) == first)
        }
    }
}

private func command(
    _ client: Git.Client,
    _ arguments: [Swift.String],
    at directory: URL
) throws(Git.Client.Error) {
    _ = try client.bytes(arguments, at: directory.path)
}
