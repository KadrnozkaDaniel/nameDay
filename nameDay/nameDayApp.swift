//
//  NameDayApp.swift
//

import SwiftUI
import AppKit

@main
struct NameDayApp: App {
    @StateObject private var vm = NamedayViewModel()

    var body: some Scene {
        MenuBarExtra {
            ZStack {
                LinearGradient(
                    colors: [Color.primary.opacity(0.04), Color.clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 18) {
                    VStack(spacing: 14) {
                        NamedayBlock(title: "Dnes má svátek:", text: vm.displayText)
                        NamedayBlock(title: "Zítra bude mít svátek:", text: vm.tomorrowText)
                    }

                    Divider()
                        .overlay(Color.primary.opacity(0.08))

                    VStack(spacing: 12) {
                        Toggle(isOn: $vm.launchAtLoginEnabled) {
                            Text("Otevřít po startu")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                        }
                        .toggleStyle(.checkbox)
                        .onChange(of: vm.launchAtLoginEnabled) { _, v in vm.setLaunchAtLogin(v) }
                        .onAppear { vm.syncLaunchAtLoginState() }

                        Button(action: { NSApp.terminate(nil) }) {
                            Text("Ukončit")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(PrimaryCapsuleButtonStyle())
                    }
                }
                .padding(18)
                .frame(width: 300)
            }
        } label: {
            Text(vm.displayText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .monospacedDigit()
                .padding(.horizontal, 6)
                .task { vm.start() }
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - UI
struct NamedayBlock: View {
    let title: String
    let text: String

    private var displayText: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "–" : trimmed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(displayText)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .glassCard()
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: displayText)
        }
    }
}

// MARK: - Styles & Modifiers

private struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.55), .white.opacity(0.12)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 8)
    }
}

private extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
}

private struct PrimaryCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                Capsule()
                    .fill(.red.gradient)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.35), .white.opacity(0.0)],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .red.opacity(0.25), radius: 14, x: 0, y: 8)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: configuration.isPressed)
    }
}
