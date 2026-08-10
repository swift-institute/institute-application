internal import Institute_Conversion
internal import Institute_Dependency
internal import Institute_Development
internal import Institute_Doctor
internal import Institute_GitHub
internal import Institute_Instruments
internal import Institute_Inventory
internal import Institute_Lint
public import Institute_Model
internal import Institute_Pages

extension Institute {
    /// The Institute Application: the composition that operates an Institute
    /// checkout, as distinct from the Institute domain model it composes.
    ///
    /// Domain semantics — inventory, dependency, doctor, lint, instruments,
    /// conversion, development — are owned by `Institute` itself. This
    /// namespace owns only the act of operating them: the command surface and
    /// the wiring that binds it to a root.
    public enum Application {}
}
