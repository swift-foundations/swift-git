public import Git_Standard

extension Git.Client {
    public enum Termination: Sendable, Equatable {
        case exited(code: Int32)
        case signaled(signal: Int32)
        case stopped(signal: Int32)

    }
}
