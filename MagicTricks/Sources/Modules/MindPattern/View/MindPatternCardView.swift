//
//  MindPatternCardView.swift
//  Magic Tricks
//
//  Created by Ross on 17/04/2026.
//

import SwiftUI

struct MindPatternCardView: View {

    let tile: MindPatternTile
    let isPressed: Bool

    var body: some View {
        TrickGradientCard(color: tile.color, height: tile.height, isPressed: isPressed) {
            Image(systemName: tile.animal.symbolName)
                .font(.system(size: 52, weight: .black))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.white.opacity(0.92))
        }
    }
}

#Preview {
    MindPatternCardView(tile: defaultMindPatternTiles[0], isPressed: false)
}
