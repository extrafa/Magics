//
//  TrickRouterView.swift
//  Magic Tricks
//
//  Created by Ross on 11/01/2026.
//

import SwiftUI

struct TrickRouterView: View {

    let trick: Trick

    var body: some View {
        switch trick.id {
        case .calculatorPrediction:
            CalculatorPredictionView()
        case .colorSense:
            ColorSenseView()
        case .magicGallery:
            MagicGalleryView()
        case .timeControl:
            TimeControlView()
        case .geoMentalism:
            GeoMentalismView()
        case .mindLink:
            MindLinkView()
        }
    }
}
