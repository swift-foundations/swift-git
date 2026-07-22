public import Git_Standard

extension Git.Merge {
    public enum Mode: Sendable, Equatable {
        case fast
        case any
    }
}
