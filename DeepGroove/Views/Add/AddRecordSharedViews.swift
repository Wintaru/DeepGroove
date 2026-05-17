import SwiftUI

func sourceButton(title: String, subtitle: String, icon: String,
                  color: Color, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

func searchingView() -> some View {
    VStack(spacing: 24) {
        Spacer()
        ProgressView().scaleEffect(1.5)
        Text("Consulting the Babel Fish…").font(.headline)
        Text("Translating the cosmos into metadata")
            .font(.subheadline).foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        Spacer()
    }
    .padding()
}

func noResultsView(message: String, onTryAgain: @escaping () -> Void,
                   onEnterManually: @escaping () -> Void) -> some View {
    VStack(spacing: 24) {
        Spacer()
        Image(systemName: "magnifyingglass")
            .font(.system(size: 72)).foregroundStyle(.secondary)
        VStack(spacing: 6) {
            Text("Not in This Sector of the Galaxy").font(.title2).fontWeight(.bold)
            Text(message).font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        Button("Try Again", action: onTryAgain)
            .buttonStyle(.borderedProminent).controlSize(.large)
        Button("Enter Manually", action: onEnterManually)
            .foregroundStyle(.secondary)
        Spacer()
    }
    .padding()
}

func failureView(message: String, onTryAgain: @escaping () -> Void) -> some View {
    VStack(spacing: 24) {
        Spacer()
        Image(systemName: "exclamationmark.circle.fill")
            .font(.system(size: 72)).foregroundStyle(.red)
        VStack(spacing: 6) {
            Text("The Vogons Have Interfered").font(.title2).fontWeight(.bold)
            Text(message).font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        Button("Try Again", action: onTryAgain)
            .buttonStyle(.borderedProminent).controlSize(.large)
        Spacer()
    }
    .padding()
}
