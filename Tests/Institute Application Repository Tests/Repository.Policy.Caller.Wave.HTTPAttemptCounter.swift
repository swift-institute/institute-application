import Institute_Repository_Policy
actor RepositoryPolicyCallerWaveHTTPAttemptCounter {
    private var value = 0

    func next() -> Int {
        value += 1
        return value
    }

    func count() -> Int {
        value
    }
}
