//
//  PhantomDrawReceiverView.swift
//  Magic Tricks
//

import SwiftUI

struct PhantomDrawReceiverView: View {

    @ObservedObject var viewModel: PhantomDrawViewModel

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                        .padding(24)

                    if viewModel.session.receivedStrokes.isEmpty {
                        placeholder
                    }

                    Canvas { context, size in
                        context.drawStrokes(viewModel.session.receivedStrokes, canvasSize: size)
                    }
                    .padding(24)
                    .allowsHitTesting(false)
                }
            }
        }
        .navigationTitle("Phantom Draw")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                connectionBadge
            }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color.secondary.opacity(0.4))
            Text("Waiting for drawing...")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .allowsHitTesting(false)
    }

    private var connectionBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.green)
                .frame(width: 7, height: 7)
            Text(peerName)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var peerName: String {
        guard case .connected(let peerName) = viewModel.session.connectionState else { return "Connected" }
        return peerName
    }
}
