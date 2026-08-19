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

    public func fetch(
        _ remote: Swift.String,
        object: Git.Object.ID,
        into destination: Git.Ref.Name,
        at directory: Swift.String
    ) throws(Error) {
        let specification = "\(object.rawValue):\(destination.rawValue)"
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

    public func clone(
        _ remote: Swift.String,
        branch: Swift.String? = nil,
        bare: Swift.Bool = false,
        checkout: Swift.Bool = true,
        to directory: Swift.String
    ) throws(Error) {
        var arguments = ["clone", "--origin", "origin", "--no-tags"]
        if let branch {
            arguments += ["--single-branch", "--branch", branch]
        }
        if bare {
            arguments.append("--bare")
        }
        if !checkout {
            arguments.append("--no-checkout")
        }
        arguments += [remote, directory]
        _ = try bytes(arguments)
    }

    /// Detached checkout of one exact object. The worktree afterwards holds
    /// exactly the tree that commit names; no branch ref is created,
    /// consulted, or moved, so a moving branch tip cannot choose the bytes.
    public func checkout(
        detached object: Git.Object.ID,
        at directory: Swift.String
    ) throws(Error) {
        _ = try bytes(["checkout", "--detach", object.rawValue], at: directory)
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
