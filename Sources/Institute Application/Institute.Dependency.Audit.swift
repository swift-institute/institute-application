internal import SPM_Standard

extension Institute.Dependency {
    /// Reproducible, read-only measurement of direct manifest dependency
    /// origins over the Institute inventory.
    struct Audit: Sendable {
        let repositories: [Institute.Repository]
        let policy: Institute.Inventory.Policy
        let client: Client
        let sanctioned: Set<Institute.Repository.Key>
        let inventoryReference: Swift.String
        let inventoryRevision: Swift.String
        let parser: Package.Dependency.Declaration.Parser
        let fanout: Institute.Fanout

        init(
            repositories: [Institute.Repository],
            policy: Institute.Inventory.Policy,
            client: Client,
            sanctioned: Set<Institute.Repository.Key> = [],
            inventoryReference: Swift.String,
            inventoryRevision: Swift.String,
            parser: Package.Dependency.Declaration.Parser = .init(),
            fanout: Institute.Fanout = .init()
        ) {
            self.repositories = repositories
            self.policy = policy
            self.client = client
            self.sanctioned = sanctioned
            self.inventoryReference = inventoryReference
            self.inventoryRevision = inventoryRevision
            self.parser = parser
            self.fanout = fanout
        }
    }
}
