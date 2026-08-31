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
    var onStart: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.background
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
            .withPresentationDragIndicator()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: InstructionShareFormatter.shareText(for: instruction)) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.primaryText)
                }
            }
        }
    }

    private func startTrickButton(action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.background.opacity(0), Color.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 32)

            Button(action: action) {
                Text(String(localized: "instruction.startTrick"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
            }
            .buttonStyle(PrimaryTrickButtonStyle(color: .button))
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .background(Color.background)
        }
    }
}

private extension InstructionView {
    var headerSection: some View {
        Text(instruction.title)
            .font(.system(size: 32, weight: .bold, design: .rounded))
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
