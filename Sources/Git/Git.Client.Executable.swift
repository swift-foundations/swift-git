public import Git_Standard

#if canImport(Darwin)
    private import Darwin  // getenv, access, X_OK
#elseif canImport(Glibc)
    private import Glibc  // getenv, access, X_OK
#elseif canImport(Musl)
    private import Musl  // getenv, access, X_OK
#elseif canImport(WinSDK)
    private import WinSDK  // GetEnvironmentVariableW, GetFileAttributesW
#endif

// MARK: - Locating the Git Executable

extension Git.Client {
    /// The path this client uses when no executable is named explicitly.
    ///
    /// Resolved by searching `PATH`, because the spawn underneath needs an
    /// absolute path — `Process.Spawn` passes `lpApplicationName` on Windows
    /// and uses `posix_spawn` rather than `posix_spawnp` elsewhere, so
    /// neither platform performs the search itself.
    ///
    /// The previous default was the literal `/usr/bin/git`. That path does
    /// not exist on Windows at all, and it is not where Git lives on a
    /// Homebrew or Nix installation either, so the hard-coded form was
    /// wrong beyond the leg that exposed it.
    ///
    /// If the search finds nothing, the conventional location is returned
    /// rather than `nil`: a client that names a path which then fails to
    /// spawn reports a Git-execution failure, which is a better diagnosis
    /// than a client that cannot be constructed.
    public static var installed: Swift.String {
        for directory in searchDirectories() {
            for name in executableNames {
                let candidate = "\(directory)\(separator)\(name)"
                if isExecutable(candidate) { return candidate }
            }
        }
        return conventionalPath
    }

    /// The file names Git is installed under on this platform.
    #if os(Windows)
        static let executableNames = ["git.exe"]
    #else
        static let executableNames = ["git"]
    #endif

    /// The path returned when `PATH` names no Git.
    #if os(Windows)
        static let conventionalPath = #"C:\Program Files\Git\cmd\git.exe"#
    #else
        static let conventionalPath = "/usr/bin/git"
    #endif

    /// The platform's directory separator.
    #if os(Windows)
        static let separator: Swift.String = #"\"#
    #else
        static let separator: Swift.String = "/"
    #endif

    /// The platform's `PATH` entry separator.
    #if os(Windows)
        static let pathListSeparator: Swift.Character = ";"
    #else
        static let pathListSeparator: Swift.Character = ":"
    #endif

    /// The entries of `PATH`, in order, with empty entries dropped.
    static func searchDirectories() -> [Swift.String] {
        guard let path = environmentValue("PATH") else { return [] }
        return
            path
            .split(separator: pathListSeparator, omittingEmptySubsequences: true)
            .map(Swift.String.init)
    }

    /// Whether `path` names a file that can be spawned.
    ///
    /// Windows carries executability in the extension rather than a
    /// permission bit, so the meaningful check there is that the candidate
    /// exists and is not a directory.
    static func isExecutable(_ path: Swift.String) -> Swift.Bool {
        #if os(Windows)
            return path.withCString(encodedAs: UTF16.self) { wide in
                let attributes = unsafe GetFileAttributesW(wide)
                guard attributes != DWORD.max else { return false }
                return attributes & DWORD(FILE_ATTRIBUTE_DIRECTORY) == 0
            }
        #else
            return unsafe path.withCString { unsafe access($0, X_OK) == 0 }
        #endif
    }

    /// The value of the environment variable `name`, or `nil` if unset.
    static func environmentValue(_ name: Swift.String) -> Swift.String? {
        #if os(Windows)
            return name.withCString(encodedAs: UTF16.self) { wide -> Swift.String? in
                // The first call sizes the value including its NUL; the
                // second fills a buffer of that size, so it reports one less.
                let capacity = unsafe GetEnvironmentVariableW(wide, nil, 0)
                guard capacity > 0 else { return nil }
                var buffer = [WCHAR](repeating: 0, count: Swift.Int(capacity))
                let written = unsafe GetEnvironmentVariableW(wide, &buffer, capacity)
                guard written > 0, written < capacity else { return nil }
                return Swift.String(decoding: buffer[..<Swift.Int(written)], as: UTF16.self)
            }
        #else
            guard let value = unsafe getenv(name) else { return nil }
            return unsafe Swift.String(cString: value)
        #endif
    }
}
