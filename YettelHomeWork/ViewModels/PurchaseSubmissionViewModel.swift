import Foundation
import Observation

@MainActor
@Observable
final class PurchaseSubmissionViewModel {
    private let purchaseService: PurchaseService

    private(set) var isSubmitting = false
    private(set) var orderResult: PurchaseResultPayload?
    var showResult = false

    init(purchaseService: PurchaseService) {
        self.purchaseService = purchaseService
    }

    func submit(items: [OrderItem]) {
        guard !isSubmitting, !items.isEmpty else { return }
        isSubmitting = true

        Task {
            let result: PurchaseResultPayload

            do {
                let response = try await purchaseService.submitOrder(items)
                result = PurchaseResultPayload.from(response: response)
            } catch {
                result = PurchaseResultPayload.failure(message: error.localizedDescription)
            }

            orderResult = result
            isSubmitting = false
            showResult = true
            
        }
    }
}
