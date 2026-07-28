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

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    effectSection
                    secretSection
                    stepsSection

                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
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
                ShareLink(
                    item: InstructionShareFormatter.shareText(for: instruction),
                    preview: SharePreview(instruction.title)
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.primaryText)
                }
            }
        }
    }
}

private extension InstructionView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(instruction.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
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
    NavigationView {
        InstructionView(instruction: .calculatorPrediction)
    }
}
