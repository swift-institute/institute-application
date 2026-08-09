import Testing

@testable import Institute_Application

extension Institute.Inventory {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
    }
}
