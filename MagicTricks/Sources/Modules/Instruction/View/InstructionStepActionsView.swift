import SwiftUI

struct InstructionStepActionsView: View {
    let actions: [InstructionStepAction]
    let onAction: (InstructionStepAction) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(actions, id: \.self) { action in
                InstructionStepActionButton(action: action) {
                    onAction(action)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InstructionStepActionButton: View {
    let action: InstructionStepAction
    let onTap: () -> Void

    private var presentation: InstructionStepActionPresentation {
        InstructionStepActionPresentation(action: action)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: presentation.icon)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 18)

                labels
                Spacer(minLength: 8)
                chevron
            }
            .foregroundStyle(.primaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
            .background(buttonBackground)
        }
        .buttonStyle(.plain)
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(presentation.title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(presentation.subtitle)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.primaryText.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.primaryText.opacity(0.44))
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.primaryText.opacity(0.055))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primaryText.opacity(0.08), lineWidth: 1)
            }
    }
}
