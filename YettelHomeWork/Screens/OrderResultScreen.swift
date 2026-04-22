import SwiftUI

struct OrderResultScreen: View {
    let payload: PurchaseResultPayload
    @Environment(\.dismiss) private var dismiss
    @Environment(\.popToRoot) private var popToRoot

    private enum ResultMetrics {
        static let contentStackSpacing: CGFloat = FigmaConstants.spacings.mediumLargePadding
        static let contentHorizontalPadding: CGFloat = FigmaConstants.spacings.xLargePadding
        static let contentTopPadding: CGFloat = FigmaConstants.spacings.largePadding
        static let contentBottomPadding: CGFloat = FigmaConstants.spacings.xLargePadding

        static let successContentSpacing: CGFloat = FigmaConstants.spacings.mediumPadding
        static let successTextToImageSpacing: CGFloat = FigmaConstants.spacings.xSmallPadding

        static let successMessageSize: CGFloat = 52
        static let successMessageMaxWidth: CGFloat = 280
        static let successMessageLineLimit: Int = 4
        static let illustrationHeight: CGFloat = 280
        static let illustrationOffsetX: CGFloat = 34

        static let failureStackSpacing: CGFloat = FigmaConstants.spacings.regularPadding
        static let failureTitleSize: CGFloat = 34
        static let failureIconSize: CGFloat = 42
        static let failureMessageSize: CGFloat = FigmaConstants.typography.bodySize
        static let failureMessageOpacity: CGFloat = 0.8
        static let failureCardPadding: CGFloat = FigmaConstants.spacings.mediumLargePadding

        static let confettiHeight: CGFloat = 208
        static let confettiBottomPadding: CGFloat = -FigmaConstants.spacings.smallPadding

        static let doneButtonTopPadding: CGFloat = FigmaConstants.spacings.mediumPadding
        static let doneButtonBottomPadding: CGFloat = FigmaConstants.spacings.mediumPadding
    }

    var body: some View {
        ZStack {
            (payload.isSuccess ? AppTheme.accentLime : AppTheme.pageBackground)
                .ignoresSafeArea()

            if payload.isSuccess {
                ViewThatFits(in: .vertical) {
                    successContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.horizontal, ResultMetrics.contentHorizontalPadding)
                        .padding(.top, ResultMetrics.contentTopPadding)
                        .padding(.bottom, ResultMetrics.contentBottomPadding)

                    ScrollView {
                        successContent
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, ResultMetrics.contentHorizontalPadding)
                            .padding(.top, ResultMetrics.contentTopPadding)
                            .padding(.bottom, ResultMetrics.contentBottomPadding)
                    }
                    .scrollIndicators(.hidden)
                }
            } else {
                ScrollView {
                    failureContent
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, ResultMetrics.contentHorizontalPadding)
                        .padding(.top, ResultMetrics.contentTopPadding)
                        .padding(.bottom, ResultMetrics.contentBottomPadding)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryActionButton(title: "result.button.done") {
                popToRoot()
            }
            .accessibilityIdentifier("result.doneButton")
            .padding(.horizontal, ResultMetrics.contentHorizontalPadding)
            .padding(.top, ResultMetrics.doneButtonTopPadding)
            .padding(.bottom, ResultMetrics.doneButtonBottomPadding)
            .background(.clear)
            .zIndex(10)
        }
        .navigationBarBackButtonHidden()
    }

    private var successContent: some View {
        VStack(alignment: .leading, spacing: ResultMetrics.successContentSpacing) {
            celebrationConfetti

            Text("result.success.message")
                .font(AppTypography.bold(ResultMetrics.successMessageSize))
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: ResultMetrics.successMessageMaxWidth, alignment: .leading)
                .lineLimit(ResultMetrics.successMessageLineLimit)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Image("SuccessIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(height: ResultMetrics.illustrationHeight)
                    .offset(x: ResultMetrics.illustrationOffsetX)
            }
            .padding(.top, ResultMetrics.successTextToImageSpacing)
        }
    }

    private var failureContent: some View {
        VStack(alignment: .leading, spacing: ResultMetrics.contentStackSpacing) {
            SectionCard(
                alignment: .leading,
                spacing: ResultMetrics.failureStackSpacing,
                padding: ResultMetrics.failureCardPadding,
                cornerRadius: AppTheme.cornerMedium
            ) {
                Label {
                    Text("result.failure.title")
                        .font(AppTypography.bold(ResultMetrics.failureTitleSize))
                } icon: {
                    Image(systemName: "xmark.circle.fill")
                        .font(AppTypography.bold(ResultMetrics.failureIconSize))
                }
                .foregroundStyle(.red)

                Text(payload.message.isEmpty ? String(localized: "result.failure.message") : payload.message)
                    .font(AppTypography.regular(ResultMetrics.failureMessageSize))
                    .foregroundStyle(AppTheme.primaryText.opacity(ResultMetrics.failureMessageOpacity))

                PrimaryActionButton(title: "result.button.retry") {
                    dismiss()
                }
            }
        }
    }

    private var celebrationConfetti: some View {
        ZStack(alignment: .top) {
            Image("SuccessConfetti")
                .resizable()
                .scaledToFill()
                .frame(height: ResultMetrics.confettiHeight)
                .frame(maxWidth: .infinity)
                .clipped()
        }
        .padding(.bottom, ResultMetrics.confettiBottomPadding)
        .zIndex(1)
    }
}

#Preview("Order Result Success") {
    NavigationStack {
        OrderResultScreen(payload: PurchaseResultPayload(isSuccess: true, message: ""))
    }
}

#Preview("Order Result Failure") {
    NavigationStack {
        OrderResultScreen(payload: PurchaseResultPayload(isSuccess: false, message: "Payment provider timeout."))
    }
}
