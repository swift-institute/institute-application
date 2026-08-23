public import Institute_Model

extension Institute {
    /// The application's typed GitHub effect surface: the Process-based
    /// `gh api` transport and the operations composed over it. The domain
    /// owns every contract (`Institute.Repository.Policy.Client`, the wave
    /// client protocols); this namespace owns only their execution.
    public enum GitHub {}
}
