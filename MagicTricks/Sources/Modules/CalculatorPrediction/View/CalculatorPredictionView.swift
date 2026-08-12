//
//  CalculatorPredictionView.swift
//  Magic Tricks
//
//  Created by Ross on 31/01/2026.
//

import SwiftUI

struct CalculatorPredictionView: View {
    
    @StateObject private var vm = CalculatorPredictionViewModel()
    @State private var isVisible = AppPreferences.shared.isExitHintEnabled

    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 16
            let spacing: CGFloat = 12
            let availableWidth = geometry.size.width - horizontalPadding * 2
            let buttonSize = max((availableWidth - spacing * 3) / 4, 1)

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: spacing) {
                    Spacer()

                    HStack {
                        Spacer()
                        Text(vm.display)
                            .foregroundColor(.white)
                            .opacity(vm.isSaveBlinkVisible ? 0.16 : 1)
                            .font(.system(size: 70, weight: .light))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal)
                            .animation(.easeInOut(duration: 0.12), value: vm.isSaveBlinkVisible)
                    }

                    LazyVGrid(columns: Self.columns, spacing: 12) {
                        ForEach(CalculatorPrediction.buttons, id: \.self) { label in
                            CalculatorPredictionButtonView(label: label.rawValue, buttonSize: buttonSize) {
                                vm.buttonPressed(label)
                            }
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 2)
                                    .onEnded { _ in
                                        if label == .clear {
                                            vm.saveSecretValue()
                                        }
                                    }
                            )
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 20)
                
                ExitHintView(isVisible: $isVisible, style: .specialWhite)
            }
        }
    }
}

#Preview {
    CalculatorPredictionView()
}
