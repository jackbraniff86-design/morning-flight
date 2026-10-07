import UIKit
import Capacitor

// Registers the app's own plugins (ones that live in this target rather than a package).
class MainViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        // (no app-local plugins at the moment)
    }
}
