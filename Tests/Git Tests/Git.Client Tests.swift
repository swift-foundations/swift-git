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
            defer { try? FileManager.default.removeItem(at: root) }

            let client = Git.Client()
            try client.initialize(at: source.path, bare: true)
            try client.initialize(at: probe.path, bare: true)

            let ref = try Git.Ref.Name("refs/heads/main")
            let destination = try Git.Ref.Name("refs/probe/local")
            #expect(throws: Git.Client.Error.self) {
                try client.fetch(source.path, ref: ref, into: destination, at: probe.path)
            }
        }
    }
}
