public import Git_Standard

extension Git.Client {
    public func initialize(at directory: Swift.String, bare: Swift.Bool) throws(Error) {
        var arguments = ["init"]
        if bare {
            arguments.append("--bare")
        }
        arguments.append(directory)
        _ = try bytes(arguments)
    }

    public func fetch(
        _ remote: Swift.String,
        ref: Git.Ref.Name,
        into destination: Git.Ref.Name? = nil,
        at directory: Swift.String
    ) throws(Error) {
        let specification = destination.map { "\(ref.rawValue):\($0.rawValue)" } ?? ref.rawValue
        _ = try bytes(["fetch", "--no-tags", remote, specification], at: directory)
    }

    public func merge(
        _ reference: Swift.String,
        mode: Git.Merge.Mode,
        at directory: Swift.String
    ) throws(Error) {
        var arguments = ["merge"]
        if mode == .fast {
            arguments.append("--ff-only")
        }
        arguments.append(reference)
        _ = try bytes(arguments, at: directory)
    }

    public func clone(_ remote: Swift.String, to directory: Swift.String) throws(Error) {
        _ = try bytes(["clone", "--origin", "origin", remote, directory])
    }

    public func `switch`(_ branch: Swift.String, at directory: Swift.String) throws(Error) {
        _ = try bytes(["switch", branch], at: directory)
    }

    public func track(
        _ branch: Swift.String,
        upstream: Swift.String,
        at directory: Swift.String
    ) throws(Error) {
        _ = try bytes(["branch", "--set-upstream-to=\(upstream)", branch], at: directory)
    }
}
