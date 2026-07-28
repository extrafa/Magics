//
//  MindPatternView.swift
//  Magic Tricks
//
//  Created by Ross on 17/04/2026.
//

import SwiftUI

struct MindPatternView: View {

    @StateObject private var viewModel = MindPatternViewModel()
    @State private var isVisible = true

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                orderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.tiles) { tile in
                        MindPatternCardView(
                            tile: tile,
                            isPressed: viewModel.activeTapAnimal == tile.animal
                        )
                        .rotationEffect(.degrees(tile.rotation))
                        .floatingMotion(
                            phase: Double(tile.animal.signalCount) * 0.31,
                            travel: 2.5,
                            rotation: 0.5,
                            duration: 4.4 + Double(tile.animal.signalCount) * 0.18
                        )
                        .gesture(
                            // fires on touch down, not finger up — card responds instantly on press
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in viewModel.handleTap(on: tile) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }

            ExitHintView(isVisible: $isVisible)
        }
        .onDisappear {
            viewModel.cancelTasks()
        }
    }

    private var orderBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.tiles.count, id: \.self) { index in
                if index < viewModel.spectatorSelection.count {
                    filledSlot(index: index, animal: viewModel.spectatorSelection[index])
                } else {
                    emptySlot(index: index)
                }
            }

            clearButton
                .opacity(viewModel.spectatorSelection.isEmpty ? 0 : 1)
                .disabled(viewModel.spectatorSelection.isEmpty)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: viewModel.spectatorSelection)
    }

    private func filledSlot(index: Int, animal: MindPatternAnimal) -> some View {
        let tile = viewModel.tiles.first(where: { $0.animal == animal })
        let color = tile?.color ?? TrickPalette.Collection.mindPattern

        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.95), color.opacity(0.62)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 28
                    )
                )

            VStack(spacing: 2) {
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))

                Image(systemName: animal.symbolName)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tile?.color.opacity(0.3) ?? Color.primaryText.opacity(0.1), lineWidth: 1)
        }
        .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
    }

    private func emptySlot(index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primaryText.opacity(0.04))

            Text("\(index + 1)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primaryText.opacity(0.22))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primaryText.opacity(0.06), lineWidth: 1)
        }
    }

    private var clearButton: some View {
        Button(action: viewModel.reset) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primaryText.opacity(0.06))

                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primaryText.opacity(0.55))
            }
            .frame(width: 40, height: 48)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MindPatternView()
}
