//
//  TrickRouterView.swift
//  Magic Tricks
//
//  Created by Ross on 11/01/2026.
//

import SwiftUI

struct TrickRouterView: View {

    let type: TrickType

    var body: some View {
        switch type {
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
        case .phantomDraw:
            PhantomDrawView()
        }
    }
}
