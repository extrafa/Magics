//
//  PaywallDisguiseScreen.swift
//  Magic Tricks
//

import SwiftUI

// What each trick looks like to a spectator: an ordinary stopwatch, calculator, tiles, photos, canvas.
struct PaywallDisguiseScreen: View {
    static let designSize = CGSize(width: 220, height: 476)

    let type: TrickType
    let isActive: Bool

    var body: some View {
        DisguisePhone {
            switch type {
            case .timeControl: StopwatchDisguise(isActive: isActive)
            case .calculatorPrediction: CalculatorDisguise(isActive: isActive)
            case .colorSense: ColorTilesDisguise(isActive: isActive)
            case .magicGallery: PhotosDisguise(isActive: isActive)
            case .phantomDraw: CanvasDisguise(isActive: isActive)
            case .geoMentalism: Color.black
            }
        }
        .frame(width: Self.designSize.width, height: Self.designSize.height)
    }
}

private struct DisguisePhone<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(Color.black)
            content
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .padding(6)
            Capsule()
                .fill(Color.black)
                .frame(width: 66, height: 20)
                .padding(.top, 14)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .stroke(Color(white: 0.3), lineWidth: 2)
        }
    }
}

// Runs a one-shot 0...1 animation each time the screen becomes the active one; resting screens show the finished state.
private struct DisguiseProgress: ViewModifier {
    let isActive: Bool
    let duration: Double
    @Binding var progress: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.task(id: isActive) {
            guard isActive, !reduceMotion else {
                progress = 1
                return
            }
            progress = 0
            try? await Task.sleep(milliseconds: 450)
            withAnimation(.easeInOut(duration: duration)) { progress = 1 }
        }
    }
}

private extension View {
    func runsWhenActive(_ isActive: Bool, duration: Double, progress: Binding<Double>) -> some View {
        modifier(DisguiseProgress(isActive: isActive, duration: duration, progress: progress))
    }
}

// MARK: - Stopwatch

private struct CountingTime: View, Animatable {
    var seconds: Double

    var animatableData: Double {
        get { seconds }
        set { seconds = newValue }
    }

    var body: some View {
        let hundredths = Int((seconds * 100).rounded(.down))
        Text(String(format: "%02d:%02d.%02d", hundredths / 6000, (hundredths / 100) % 60, hundredths % 100))
            .monospacedDigit()
    }
}

private struct StopwatchDisguise: View {
    let isActive: Bool
    @State private var progress = 1.0

    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 0) {
                CountingTime(seconds: 7.42 * progress)
                    .font(.system(size: 44, weight: .thin))
                    .foregroundStyle(.white)
                    .padding(.top, 74)
                Spacer()
                HStack {
                    circleButton("Reset", fill: Color(white: 0.16), text: Color(white: 0.7))
                    Spacer()
                    if progress < 1 {
                        circleButton("Stop", fill: Color(red: 0.3, green: 0.08, blue: 0.08), text: Color(red: 1, green: 0.27, blue: 0.23))
                    } else {
                        circleButton("Start", fill: Color(red: 0.08, green: 0.24, blue: 0.13), text: Color(red: 0.19, green: 0.82, blue: 0.35))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 26)
            }
        }
        .runsWhenActive(isActive, duration: 2.2, progress: $progress)
    }

    private func circleButton(_ title: String, fill: Color, text: Color) -> some View {
        Text(title)
            .font(.system(size: 14))
            .foregroundStyle(text)
            .frame(width: 62, height: 62)
            .background(Circle().fill(fill))
    }
}

// MARK: - Calculator

private struct CalculatorDisguise: View {
    let isActive: Bool
    @State private var shown = "146"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let rows: [[(String, Int)]] = [
        [("AC", 1), ("±", 1), ("%", 1), ("÷", 2)],
        [("7", 0), ("8", 0), ("9", 0), ("×", 2)],
        [("4", 0), ("5", 0), ("6", 0), ("−", 2)],
        [("1", 0), ("2", 0), ("3", 0), ("+", 2)],
    ]

    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 8) {
                Spacer()
                Text(shown)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 16)
                ForEach(rows.indices, id: \.self) { r in
                    HStack(spacing: 8) {
                        ForEach(rows[r].indices, id: \.self) { c in
                            key(rows[r][c].0, kind: rows[r][c].1)
                        }
                    }
                }
                HStack(spacing: 8) {
                    key("0", kind: 0)
                        .frame(width: 88, alignment: .leading)
                    key(".", kind: 0)
                    key("=", kind: 2)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 16)
        }
        .task(id: isActive) {
            guard isActive, !reduceMotion else {
                shown = "146"
                return
            }
            for step in ["", "7", "73", "73×", "73×2", "146"] {
                shown = step.isEmpty ? "0" : step
                try? await Task.sleep(milliseconds: step == "73×2" ? 700 : 380)
            }
        }
    }

    private func key(_ label: String, kind: Int) -> some View {
        let fill: Color = kind == 2 ? Color(red: 1, green: 0.62, blue: 0.04) : kind == 1 ? Color(white: 0.65) : Color(white: 0.2)
        return Text(label)
            .font(.system(size: 19))
            .foregroundStyle(kind == 1 ? Color.black : Color.white)
            .frame(width: 40, height: 40)
            .background(Circle().fill(fill))
    }
}

// MARK: - Color tiles

private struct ColorTilesDisguise: View {
    let isActive: Bool
    @State private var lit: Int? = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tiles: [(String, Color)] = [
        ("Tap", Color(red: 1, green: 0.27, blue: 0.23)),
        ("Trust", Color(red: 1, green: 0.8, blue: 0.04)),
        ("Pick One", Color(red: 0.19, green: 0.82, blue: 0.35)),
        ("Go On", Color(red: 0.04, green: 0.52, blue: 1)),
    ]

    var body: some View {
        ZStack {
            Color(white: 0.09)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(tiles.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(tiles[i].1)
                        .aspectRatio(0.6, contentMode: .fit)
                        .overlay(alignment: .bottomLeading) {
                            Text(tiles[i].0)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.65))
                                .padding(10)
                        }
                        .scaleEffect(lit == i ? 1.07 : 1)
                        .opacity(lit == nil || lit == i ? 1 : 0.5)
                        .shadow(color: lit == i ? tiles[i].1.opacity(0.8) : .clear, radius: 14)
                }
            }
            .padding(.horizontal, 14)
        }
        .task(id: isActive) {
            guard isActive, !reduceMotion else {
                lit = 0
                return
            }
            lit = nil
            try? await Task.sleep(milliseconds: 450)
            for i in [1, 2, 3, 2, 1, 0] {
                withAnimation(.easeOut(duration: 0.18)) { lit = i }
                try? await Task.sleep(milliseconds: 260)
            }
        }
    }
}

// MARK: - Photos

private struct PhotosDisguise: View {
    let isActive: Bool
    @State private var revealed = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let names = ["two", "five", "three", "one", "four", "seven", "nine", "six", "eight"]

    var body: some View {
        ZStack {
            Color(white: 0.07)
            VStack(alignment: .leading, spacing: 8) {
                Text("Recents")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 52)
                    .padding(.horizontal, 8)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                    ForEach(names, id: \.self) { name in
                        let isTarget = name == "seven"
                        Image("gallery.photo.\(name)")
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .aspectRatio(0.78, contentMode: .fit)
                            .clipped()
                            .overlay {
                                if isTarget && revealed {
                                    Rectangle().stroke(Color(red: 1, green: 0.8, blue: 0.04), lineWidth: 3)
                                }
                            }
                            .scaleEffect(isTarget && revealed ? 1.1 : 1)
                            .zIndex(isTarget && revealed ? 1 : 0)
                            .opacity(revealed && !isTarget ? 0.55 : 1)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .task(id: isActive) {
            guard isActive, !reduceMotion else {
                revealed = true
                return
            }
            revealed = false
            try? await Task.sleep(milliseconds: 900)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { revealed = true }
        }
    }
}

// MARK: - Canvas

private struct SevenShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.minY + rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.9))
        return path
    }
}

private struct CanvasDisguise: View {
    let isActive: Bool
    @State private var progress = 1.0

    var body: some View {
        ZStack {
            Color(white: 0.06)
            SevenShape()
                .trim(from: 0, to: progress)
                .stroke(
                    Color(red: 1, green: 0.22, blue: 0.37),
                    style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: Color(red: 1, green: 0.22, blue: 0.37).opacity(0.7), radius: 10)
                .frame(width: 120, height: 190)
                .offset(y: 8)
        }
        .runsWhenActive(isActive, duration: 1.7, progress: $progress)
    }
}
