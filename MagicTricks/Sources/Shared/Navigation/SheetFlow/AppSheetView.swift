//
//  AppSheetView.swift
//  Magic Tricks
//
//  Created by Ross on 11/01/2026.
//

import SwiftUI

struct AppSheetView: View {
    let activeSheet: SheetFlow
    @EnvironmentObject private var flow: AppFlowCoordinator

    var body: some View {
        switch activeSheet {
        case .instruction(let instruction):
            NavigationStack {
                InstructionView(instruction: instruction)
                    .sheetCloseToolbar()
            }
        case .instructionFirstLaunch(let instruction, let trick):
            NavigationStack {
                InstructionView(instruction: instruction) {
                    flow.startTrickAfterInstruction(trick)
                }
                .sheetCloseToolbar()
            }
        case .rateApp:
            RateAppSheet()
                .environmentObject(flow)
        }
    }
}

// A close button at the top left of a sheet that has its own navigation bar.
private struct SheetCloseToolbar: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.textPrimary)
                }
                .accessibilityLabel(String(localized: "common.close"))
            }
        }
    }
}

extension View {
    func sheetCloseToolbar() -> some View {
        modifier(SheetCloseToolbar())
    }
}

// The same button for a sheet without a navigation bar; the content keeps clear of that corner.
private struct SheetCloseOverlay: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.overlay(alignment: .topLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.textPrimary.opacity(0.08)))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "common.close"))
            .padding(.leading, 12)
            .padding(.top, 14)
        }
    }
}

extension View {
    func sheetCloseOverlay() -> some View {
        modifier(SheetCloseOverlay())
    }

    // The height of this view as it lays out, for a sheet that is as tall as its content. A preference key did not report it inside a sheet.
    func readHeight(into height: Binding<CGFloat>) -> some View {
        background(GeometryReader { proxy in
            Color.clear
                .onAppear { height.wrappedValue = proxy.size.height }
                .onChange(of: proxy.size.height) { height.wrappedValue = $0 }
        })
    }

    // A sheet as tall as its content: no empty room under the last element, and it cannot be pulled up to full screen. Content taller
    // than the screen scrolls inside it. Pass the height from readHeight; until it is known the sheet is half height.
    func fittedSheet(height: CGFloat) -> some View {
        modifier(FittedSheetPresentation(height: height))
    }
}

// The sheet itself takes the screen colour, so no strip of the system sheet shows around the content.
private struct FittedSheetPresentation: ViewModifier {
    let height: CGFloat

    private var detents: Set<PresentationDetent> {
        height > 0 ? [.height(height)] : [.medium]
    }

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationDetents(detents)
                .presentationBackground(Color.backgroundScreen)
                .presentationCornerRadius(28)
        } else {
            content
                .presentationDetents(detents)
        }
    }
}
