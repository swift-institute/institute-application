extension Institute.Context.Packet {
    struct Record: Equatable, Sendable {
        let key: Institute.Context.Packet.Key
        let title: Swift.String
        let state: Swift.String
        let type: Swift.String
        let stateReason: Swift.String?
        let url: Swift.String
        let body: Swift.String
        let assignees: [Swift.String]
        let labels: [Swift.String]
        let parent: Swift.String?
        let children: [Swift.String]
        let comments: [Institute.Context.Packet.Record.Comment]
        let divergences: [Swift.String]
        let diagnostics: [Swift.String]
    }
}

extension Institute.Context.Packet.Record {
    struct Comment: Equatable, Sendable {
        let url: Swift.String
        let issue: Institute.Context.Packet.Key
        let author: Swift.String
        let body: Swift.String
    }
}
