/// The architecture model's namespace root.
///
/// The `Institute Application` module declares its own `Institute` namespace;
/// this module is a leaf that the application composes, so it declares the
/// namespace independently rather than depending upward. Consumers that
/// import both modules qualify the architecture side as
/// `InstituteArchitectureModel.Institute`.
public enum Institute {}
