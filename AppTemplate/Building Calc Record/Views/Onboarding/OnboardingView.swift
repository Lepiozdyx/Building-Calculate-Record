import SwiftUI

struct OnboardingView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @State private var page = 0

    private let pages: [(image: String, title: String, subtitle: String, button: String)] = [
        ("onb_container1", "Calculate Materials\nAccurately", "Know exactly how much plaster, paint, or tile you need before you buy.", "Next"),
        ("onb_container2", "Save Every\nCalculation", "Keep a full history of your estimates and never lose a number.", "Next"),
        ("onb_container3", "Track Your\nSpending", "See how much your renovation costs and plan your budget wisely.", "Next"),
        ("onb_container4", "Expert Tips\nIncluded", "40 practical building tips to help you work smarter on every job.", "Start Calculating"),
    ]

    var body: some View {
        ZStack {
            AppTheme.screenBackground(colorScheme).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if page < pages.count - 1 {
                        Button("Skip") { finish() }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText(colorScheme))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Text("\(page + 1) / \(pages.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
                    .padding(.top, 4)

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == page ? AppTheme.yellow : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 12)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 24) {
                            Spacer(minLength: 8)
                            Image(item.image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 280)
                                .padding(.horizontal, 32)
                            VStack(spacing: 12) {
                                Text(item.title)
                                    .font(.system(size: 32, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(AppTheme.primaryText(colorScheme))
                                Text(item.subtitle)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
                                    .padding(.horizontal, 24)
                            }
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        finish()
                    }
                } label: {
                    Text(pages[page].button)
                }
                .buttonStyle(PrimaryYellowButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func finish() {
        settings.hasCompletedOnboarding = true
    }
}
