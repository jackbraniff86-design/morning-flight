import UIKit
import Capacitor

// Registers the app's own plugins (ones that live in this target rather than a package).
class MainViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(StorePlugin())
    }
}
