import SwiftUI

struct SupportView: View {
    @State private var vm: SupportViewModel
    @State private var showThankYou = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(supportManager: ISupportManager) {
        _vm = State(initialValue: SupportViewModel(supportManager: supportManager))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Deep Groove is a one-person project built out of a love of records. If it brings you joy, a tip goes a long way — thank you!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if vm.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, 24)
                } else {
                    VStack(spacing: 12) {
                        ForEach(vm.products) { product in
                            TipButton(product: product, isPurchasing: isPurchasing) {
                                _ = Task { await purchase(product) }
                            }
                        }
                    }
                }

            }
            .padding()
        }
        .navigationTitle("Support the Developer")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadProducts() }
        .alert("Thank you!", isPresented: $showThankYou) {
            Button("You're welcome!") { vm.resetPurchaseState() }
        } message: {
            Text("So long, and thanks for all the records.")
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK") { vm.resetPurchaseState() }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: vm.purchaseState) { _, newState in
            switch newState {
            case .success:
                showThankYou = true
            case .error(let msg):
                errorMessage = msg
                showError = true
            case .cancelled:
                vm.resetPurchaseState()
            case .idle, .purchasing:
                break
            }
        }
    }

    private var isPurchasing: Bool {
        if case .purchasing = vm.purchaseState { return true }
        return false
    }

    private func purchase(_ product: TipProduct) async {
        await vm.purchase(product)
    }
}

private struct TipButton: View {
    let product: TipProduct
    let isPurchasing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.body.weight(.medium))
                    Text(product.displayPrice)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "heart.fill")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isPurchasing)
    }
}
