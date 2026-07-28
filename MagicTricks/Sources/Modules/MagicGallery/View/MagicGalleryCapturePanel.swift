import SwiftUI

struct MagicGalleryCapturePanel: View {
    let usesStandardSet: Bool
    let onToggleStandardSet: (Bool) -> Void
    let captureButtonTitle: String
    let canAddMorePhotos: Bool
    let onCapture: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            standardSetControl
            captureButton
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.grayCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.grayBorder, lineWidth: 1)
                }
        )
    }

    private var standardSetControl: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.indigo, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(String(localized: "magicGallery.standardSet.title"))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primaryText)

                Text(String(localized: "magicGallery.standardSet.description"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primaryText.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: Binding(
                get: { usesStandardSet },
                set: { onToggleStandardSet($0) }
            ))
            .labelsHidden()
            .tint(.indigo)
        }
    }

    private var captureButton: some View {
        Button(action: onCapture) {
            Label(captureButtonTitle, systemImage: "camera.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(canAddMorePhotos ? Color.button : Color.button.opacity(0.45))
                .foregroundStyle(.secondaryText)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canAddMorePhotos)
    }
}
