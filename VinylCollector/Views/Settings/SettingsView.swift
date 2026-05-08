import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var apiConfig: APIConfiguration
    @State private var showingAnthropicKey = false
    @State private var showingDiscogsToken = false
    @State private var savedNotice = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: apiConfig.isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(apiConfig.isValid ? .green : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(apiConfig.isValid ? "API Keys Configured" : "API Key Required")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(apiConfig.isValid
                                 ? "AI record identification is active"
                                 : "Add your Anthropic API key to enable AI identification")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Anthropic API Key")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            if showingAnthropicKey {
                                TextField("sk-ant-…", text: $apiConfig.anthropicAPIKey)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.system(.body, design: .monospaced))
                            } else {
                                SecureField("sk-ant-…", text: $apiConfig.anthropicAPIKey)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.system(.body, design: .monospaced))
                            }
                            Button {
                                showingAnthropicKey.toggle()
                            } label: {
                                Image(systemName: showingAnthropicKey ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Anthropic")
                } footer: {
                    Text("Used for AI-powered record identification from photos. Get a key at console.anthropic.com.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Discogs Personal Access Token")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            if showingDiscogsToken {
                                TextField("Optional", text: Binding(
                                    get: { apiConfig.discogsToken ?? "" },
                                    set: { apiConfig.discogsToken = $0.isEmpty ? nil : $0 }
                                ))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                            } else {
                                SecureField("Optional", text: Binding(
                                    get: { apiConfig.discogsToken ?? "" },
                                    set: { apiConfig.discogsToken = $0.isEmpty ? nil : $0 }
                                ))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                            }
                            Button {
                                showingDiscogsToken.toggle()
                            } label: {
                                Image(systemName: showingDiscogsToken ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Discogs")
                } footer: {
                    Text("Optional but recommended. Increases rate limits from 25 to 60 requests/min. Get a token at discogs.com/settings/developers.")
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                    Link("Report an Issue", destination: URL(string: "https://github.com")!)
                }
            }
            .navigationTitle("Settings")
            .overlay(alignment: .bottom) {
                if savedNotice {
                    Text("Settings saved")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onChange(of: apiConfig.anthropicAPIKey) { _, _ in flashSaved() }
            .onChange(of: apiConfig.discogsToken) { _, _ in flashSaved() }
        }
    }

    private func flashSaved() {
        withAnimation {
            savedNotice = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { savedNotice = false }
        }
    }
}
