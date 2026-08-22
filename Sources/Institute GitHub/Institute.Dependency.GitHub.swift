public import Institute_Dependency
public import Institute_Model

extension Institute.Dependency {
    /// The application control is intentionally network-free. Remote source
    /// acquisition belongs outside the canonical source/build/test closure.
    public enum Remote: Sendable {}
}

extension Institute.Dependency.Remote {
    public static func client() -> Institute.Dependency.Client {
        .init(
            repository: { key in
                .unmeasured(
                    "\(key.identity): the Institute application has no network transport"
                )
            },
            source: { metadata in
                .unmeasured(
                    "\(metadata.key.identity): the Institute application has no network transport"
                )
            },
            content: { key, blob in
                .unmeasured(
                    "\(key.identity)/\(blob.path): the Institute application has no network transport"
                )
            }
        )
    }
}
