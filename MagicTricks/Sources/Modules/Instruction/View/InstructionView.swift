//
//  InstructionView.swift
//  Instruction
//
//  Created by Ross on 09/04/2026.
//

import SwiftUI

struct InstructionView: View {
    @State private var presentedSheet: InstructionPresentedSheet?
    let instruction: Instruction
    var onStart: Completion? = nil
    @ScaledMetric(relativeTo: .largeTitle) private var headerTitleSize: CGFloat = 32
    private let shareText: String

    init(instruction: Instruction, onStart: Completion? = nil) {
        self.instruction = instruction
        self.onStart = onStart
        self.shareText = InstructionShareFormatter.shareText(for: instruction)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.backgroundScreen
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    effectSection
                    secretSection
                    stepsSection

                    Color.clear.frame(height: onStart != nil ? 100 : 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }

            if let onStart {
                startTrickButton(action: onStart)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $presentedSheet) { sheet in
            NavigationStack {
                InstructionActionSheetDestination(sheet: sheet)
            }
            .presentationDragIndicator(.visible)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.primaryText)
                }
                .accessibilityLabel(String(localized: "common.share"))
            }
        }
    }

    private func startTrickButton(action: @escaping Completion) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.backgroundScreen.opacity(0), Color.backgroundScreen],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 32)

            Button(action: action) {
                Text(String(localized: "instruction.startTrick"))
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
            }
            .buttonStyle(PrimaryTrickButtonStyle(color: .buttonPrimary))
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .background(Color.backgroundScreen)
        }
    }
}

private extension InstructionView {
    var headerSection: some View {
        Text(instruction.title)
            .font(.system(size: headerTitleSize, weight: .bold, design: .rounded))
            .foregroundStyle(.primaryText)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top)
    }

    var effectSection: some View {
        InstructionBlock(text: instruction.effect)
    }

    var secretSection: some View {
        InstructionSecretView(text: instruction.secret)
    }
    
    func handleStepAction(_ action: InstructionStepAction) {
        presentedSheet = .action(action)
    }

    var stepsSection: some View {
        InstructionStepsSection(
            steps: instruction.steps,
            onAction: handleStepAction
        )
    }
}

#Preview {
    NavigationStack {
        InstructionView(instruction: .calculatorPrediction)
    }
}
