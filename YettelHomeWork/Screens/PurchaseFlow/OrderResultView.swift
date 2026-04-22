import SwiftUI

struct OrderResultView: View {
    let payload: PurchaseResultPayload
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            (payload.isSuccess ? AppTheme.accentLime : AppTheme.pageBackground)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                if payload.isSuccess {
                    celebrationConfetti

                    Text("result.success.message")
                        .font(.system(size: ResultScreenMetrics.successMessageSize, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(maxWidth: 280, alignment: .leading)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(2)

                    HStack {
                        Spacer()
                        Image("SuccessIllustration")
                            .resizable()
                            .scaledToFit()
                            .frame(height: ResultScreenMetrics.illustrationHeight)
                            .offset(x: 34)
                    }
                    .layoutPriority(0)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        Label {
                            Text("result.failure.title")
                                .font(.system(size: ResultScreenMetrics.failureTitleSize, weight: .bold, design: .rounded))
                        } icon: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 42, weight: .bold))
                        }
                        .foregroundStyle(.red)

                        Text(payload.message.isEmpty ? String(localized: "result.failure.message") : payload.message)
                            .font(.system(size: ResultScreenMetrics.failureMessageSize, weight: .regular, design: .rounded))
                            .foregroundStyle(AppTheme.primaryText.opacity(0.8))

                        Button {
                            dismiss()
                        } label: {
                            Text("result.button.retry")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.primaryButton)
                                .clipShape(.capsule)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(18)
                    .background(AppTheme.surface)
                    .clipShape(.rect(cornerRadius: AppTheme.cornerMedium))
                }

                Spacer(minLength: 0)

                Button {
                    dismiss()
                } label: {
                    Text("result.button.done")
                        .font(.system(size: ResultScreenMetrics.actionButtonSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryButton)
                        .clipShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("result.doneButton")
            }
            .padding(.horizontal, ResultScreenMetrics.contentHorizontalPadding)
            .padding(.vertical, ResultScreenMetrics.contentVerticalPadding)
        }
        .navigationTitle(String(localized: "common.title.e_vignette"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(payload.isSuccess ? AppTheme.accentLime : AppTheme.pageBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var celebrationConfetti: some View {
        ZStack(alignment: .top) {
            Image("SuccessConfetti")
                .resizable()
                .scaledToFill()
                .frame(height: ResultScreenMetrics.confettiHeight)
                .frame(maxWidth: .infinity)
                .clipped()
        }
        .padding(.bottom, 4)
    }
}

#Preview("Order Result Success") {
    NavigationStack {
        OrderResultView(payload: PurchaseResultPayload(isSuccess: true, message: ""))
    }
}

#Preview("Order Result Failure") {
    NavigationStack {
        OrderResultView(payload: PurchaseResultPayload(isSuccess: false, message: "Payment provider timeout."))
    }
}
