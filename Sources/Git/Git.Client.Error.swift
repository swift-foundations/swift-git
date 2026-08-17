public import Git_Standard

extension Git.Client {
    public enum Error: Swift.Error, Sendable, Equatable {
        /// The Git executable could not be spawned at all.
        ///
        /// Carries the path that was attempted and the underlying spawn
        /// failure. A bare case named neither, so a failure to spawn was
        /// indistinguishable from Git running and failing — and on a
        /// platform without a local reproduction that difference costs a
        /// whole CI cycle to establish.
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
