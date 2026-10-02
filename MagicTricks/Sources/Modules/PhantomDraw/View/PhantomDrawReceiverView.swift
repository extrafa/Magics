//
//  PhantomDrawReceiverView.swift
//  Magic Tricks
//

import SwiftUI

struct PhantomDrawReceiverView: View {

    @ObservedObject var session: PhantomDrawSessionManager

    var body: some View {
        ZStack {
            Color.backgroundScreen.ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                        .padding(24)

                    if session.receivedStrokes.isEmpty && session.inProgressStroke == nil {
                        placeholder
                    }

                    Canvas { context, size in
                        context.drawStrokes(
                            session.receivedStrokes,
                            canvasSize: size,
                            senderAspectRatio: session.senderCanvasAspectRatio
                        )
                        if let inProgressStroke = session.inProgressStroke {
                            context.drawStrokes(
                                [inProgressStroke],
                                canvasSize: size,
                                senderAspectRatio: session.senderCanvasAspectRatio
                            )
                        }
                    }
                    .padding(24)
                    .allowsHitTesting(false)
                }
            }
        }
        .navigationTitle(String(localized: "card.phantomDraw.title"))
        .navigationBarTitleDisplayMode(.inline)
        .keepsScreenAwake()
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
                .accessibilityHidden(true)
            Text(String(localized: "phantomDraw.waitingForDrawing"))
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .allowsHitTesting(false)
    }

    private var connectionBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(session.isReconnecting ? Color.orange : Color.green)
                .frame(width: 7, height: 7)
            Text(session.isReconnecting ? String(localized: "phantomDraw.reconnecting") : peerName)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var peerName: String {
        guard case .connected(let peerName) = session.connectionState else {
            return String(localized: "phantomDraw.connectedFallback")
        }
        return peerName
    }
}
