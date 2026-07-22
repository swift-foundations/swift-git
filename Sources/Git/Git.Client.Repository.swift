public import Git_Standard

extension Git.Client {
    public func repository(at directory: Swift.String) throws(Error) -> Swift.Bool {
        do throws(Error) {
            return try text(["rev-parse", "--is-inside-work-tree"], at: directory) == "true"
        } catch {
            if case .command = error {
                return false
            }
            throw error
        }
    }

    public func top(at directory: Swift.String) throws(Error) -> Swift.String {
        try text(["rev-parse", "--show-toplevel"], at: directory)
    }

    public func remote(_ name: Swift.String, at directory: Swift.String) throws(Error) -> Swift.String {
        try text(["remote", "get-url", name], at: directory)
    }

    public func branch(at directory: Swift.String) throws(Error) -> Swift.String {
        try text(["branch", "--show-current"], at: directory)
    }

    public func upstream(_ branch: Swift.String, at directory: Swift.String) throws(Error) -> Swift.String {
        try text(["for-each-ref", "--format=%(upstream:short)", "refs/heads/\(branch)"], at: directory)
    }

    public func head(
        _ reference: Swift.String = "HEAD",
        at directory: Swift.String
    ) throws(Error) -> Git.Object.ID {
        let value = try text(["rev-parse", reference], at: directory)
        guard let object = Git.Object.ID(rawValue: value) else {
            throw .object(value)
        }
        return object
    }

    public func count(_ range: Swift.String, at directory: Swift.String) throws(Error) -> Swift.Int {
        let value = try text(["rev-list", "--count", range], at: directory)
        guard let count = Swift.Int(value) else {
            throw .count(value)
        }
        return count
    }

    public func status(at directory: Swift.String) throws(Error) -> [Git.Status.Entry] {
        let output = try bytes(["status", "--porcelain=v1", "-z", "--untracked-files=normal"], at: directory)
        do throws(Git.Status.Error) {
            return try Git.Status.parse(output)
        } catch {
            throw .status(error)
        }
    }
}
