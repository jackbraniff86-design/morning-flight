import Foundation
import Capacitor
import StoreKit

// Morning Flight Premium through StoreKit 2. No third-party billing SDK.
// JS: Store.products(), Store.purchase({id}), Store.restore(), Store.entitled()
@objc(StorePlugin)
public class StorePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "StorePlugin"
    public let jsName = "Store"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "products", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "purchase", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "restore", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "entitled", returnType: CAPPluginReturnPromise),
    ]
    static let ids = ["uk.co.themorningflight.premium.monthly", "uk.co.themorningflight.premium.annual"]
    private var updates: Task<Void, Never>?

    public override func load() {
        // Keep listening for renewals and purchases made outside the app so entitlement stays current.
        updates = Task { for await result in Transaction.updates { if case .verified(let t) = result { await t.finish() } } }
    }

    private func describe(_ p: Product) -> [String: Any] {
        var trial = ""
        if let intro = p.subscription?.introductoryOffer, intro.paymentMode == .freeTrial {
            trial = "\(intro.period.value) \(intro.period.unit)".lowercased()
        }
        return ["id": p.id, "title": p.displayName, "price": p.displayPrice,
                "period": p.subscription?.subscriptionPeriod.unit == .year ? "year" : "month", "trial": trial]
    }

    @objc func products(_ call: CAPPluginCall) {
        Task {
            do {
                let ps = try await Product.products(for: StorePlugin.ids)
                call.resolve(["products": ps.map { describe($0) }])
            } catch { call.reject("Could not load products: \(error.localizedDescription)") }
        }
    }

    @objc func purchase(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else { call.reject("Missing id"); return }
        Task {
            do {
                guard let p = try await Product.products(for: [id]).first else { call.reject("Unknown product"); return }
                let result = try await p.purchase()
                switch result {
                case .success(let verification):
                    if case .verified(let t) = verification { await t.finish(); call.resolve(["ok": true]) }
                    else { call.reject("Purchase could not be verified") }
                case .userCancelled: call.resolve(["ok": false, "cancelled": true])
                case .pending: call.resolve(["ok": false, "pending": true])
                @unknown default: call.resolve(["ok": false])
                }
            } catch { call.reject("Purchase failed: \(error.localizedDescription)") }
        }
    }

    @objc func restore(_ call: CAPPluginCall) {
        Task {
            do { try await AppStore.sync() } catch {}
            call.resolve(["ok": await StorePlugin.isEntitled()])
        }
    }

    @objc func entitled(_ call: CAPPluginCall) {
        Task { call.resolve(["ok": await StorePlugin.isEntitled()]) }
    }

    static func isEntitled() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, ids.contains(t.productID), t.revocationDate == nil { return true }
        }
        return false
    }
}
