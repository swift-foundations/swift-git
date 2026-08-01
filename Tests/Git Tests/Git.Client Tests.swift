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
            let top = try client.top(at: root.path)
            #expect(top == root.path || top == "/private\(root.path)")
            #expect(try client.status(at: root.path).isEmpty)
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
            try command(["config", "user.email", "workspace@swift.institute"], at: source)
            try command(["config", "user.name", "Workspace Tests"], at: source)
            try command(["branch", "-M", "main"], at: source)

            let fixture = source.appending(path: "Fixture.txt")
            try "first\n".write(to: fixture, atomically: true, encoding: .utf8)
            try command(["add", "Fixture.txt"], at: source)
            try command(["commit", "-m", "first"], at: source)
            let first = try client.head(at: source.path)

            try "second\n".write(to: fixture, atomically: true, encoding: .utf8)
            try command(["add", "Fixture.txt"], at: source)
            try command(["commit", "-m", "second"], at: source)
            let second = try client.head(at: source.path)

            try client.clone(source.path, branch: "main", bare: true, to: remote.path)
            #expect(try client.ancestor(first, of: second, at: remote.path))

            try client.initialize(at: probe.path, bare: true)
            let destination = try Git.Ref.Name("refs/probe/main")
            try client.fetch(remote.path, object: second, into: destination, at: probe.path)
            #expect(try client.head(destination.rawValue, at: probe.path) == second)
        }
    }
}

private func command(_ arguments: [String], at directory: URL) throws(CocoaError) {
    let process = Foundation.Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments = arguments
    process.currentDirectoryURL = directory
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    // swift-linter:disable:next do throws for typed catch
    // REASON: Foundation.Process.run() is an untyped cross-module throwing API;
    // its failure is normalized to the same CocoaError this helper already throws.
    do {
        try process.run()
    } catch {
        throw CocoaError(.executableNotLoadable)
    }
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw CocoaError(.executableNotLoadable)
    }
}
