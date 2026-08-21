public import Git_Standard

extension Git.Client {
    public enum Error: Swift.Error, Sendable, Equatable {

        case execution(executable: Swift.String, reason: Swift.String)
        case command(
            arguments: [Swift.String],
            termination: Termination,
            stdout: [UInt8],
            stderr: [UInt8]
        )
        case advertisement(Git.Ref.Advertisement.Error)
        case status(Git.Status.Error)
        case object(Swift.String)
        case count(Swift.String)
        case missing(Git.Ref.Name)
    }
}
