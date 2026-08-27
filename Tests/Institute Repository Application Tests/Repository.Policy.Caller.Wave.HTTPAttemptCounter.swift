public import Institute_Model
import Institute_Repository_Policy
import Byte
import Byte_Standard_Library_Integration
actor CallerWaveHTTPAttemptCounter {
    private var value = 0

    func next() -> Int {
        value += 1
        return value
    }

    func count() -> Int {
        value
    }
}
