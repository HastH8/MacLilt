import SwiftUI

enum DeliveryStatus: String {
    case implemented = "Available"
    case unsupported = "Unsupported"

    var color: Color {
        switch self {
        case .implemented: .green
        case .unsupported: .secondary
        }
    }
}

struct FeatureStatusRow: View {
    let symbol: String
    let title: String
    let detail: String
    let status: DeliveryStatus

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(status.color)
                .frame(width: 28, height: 28)
                .background(status.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(status.rawValue)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.color.opacity(0.12), in: Capsule())
        }
        .accessibilityElement(children: .combine)
    }
}
