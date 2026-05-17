import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var container: DependencyContainer
    @EnvironmentObject private var apiConfig: APIConfiguration
    @State private var showingAnthropicKey = false
    @State private var showingDiscogsToken = false
    @State private var savedNotice = false
    @State private var showingAnthropicHelp = false
    @State private var showingDiscogsHelp = false

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
                    Button {
                        showingAnthropicHelp = true
                    } label: {
                        Label("How to get an API key", systemImage: "questionmark.circle")
                            .font(.subheadline)
                    }
                } header: {
                    Text("Anthropic")
                } footer: {
                    Text("Required. Powers AI-based record identification from photos.")
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
                    Button {
                        showingDiscogsHelp = true
                    } label: {
                        Label("How to get a token", systemImage: "questionmark.circle")
                            .font(.subheadline)
                    }
                } header: {
                    Text("Discogs")
                } footer: {
                    Text("Optional but recommended. Increases search rate limits from 25 to 60 requests/min.")
                }

                Section {
                    NavigationLink {
                        SupportView(supportManager: container.supportManager)
                    } label: {
                        Label("Support the Developer", systemImage: "heart")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                    LabeledContent("Record Data", value: "Discogs")
                    Link("Report an Issue", destination: URL(string: "https://github.com/Wintaru/DeepGroove/issues")!)
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
            .sheet(isPresented: $showingAnthropicHelp) {
                AnthropicKeyHelpView()
            }
            .sheet(isPresented: $showingDiscogsHelp) {
                DiscogsTokenHelpView()
            }
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

private struct APIKeyStep: View {
    let number: Int
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Color.accentColor)
                .clipShape(Circle())
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

private struct AnthropicKeyHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Anthropic powers the AI that identifies records from photos. You'll need a free account to get a key.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        APIKeyStep(number: 1, text: "Open **console.anthropic.com** in your browser.")
                        APIKeyStep(number: 2, text: "Tap **Sign Up** to create a free account, or **Log In** if you already have one.")
                        APIKeyStep(number: 3, text: "Once you're in, look for **API Keys** in the left sidebar and tap it.")
                        APIKeyStep(number: 4, text: "Tap the **Create Key** button.")
                        APIKeyStep(number: 5, text: "Give your key a name — anything works, like *Deep Groove*.")
                        APIKeyStep(number: 6, text: "Copy the key that appears. It will start with **sk-ant-**.")
                        APIKeyStep(number: 7, text: "Come back here and paste it into the **Anthropic API Key** field.")
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Anthropic charges per use. Identifying a record typically costs around one cent or less.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Link(destination: URL(string: "https://console.anthropic.com")!) {
                        Label("Open Anthropic Console", systemImage: "arrow.up.right.square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Get an Anthropic API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct DiscogsTokenHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Discogs is the database Deep Groove uses to look up record details. A free account gives you a personal token that unlocks higher search limits.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        APIKeyStep(number: 1, text: "Open **discogs.com** in your browser.")
                        APIKeyStep(number: 2, text: "Tap **Register** to create a free account, or **Sign In** if you already have one.")
                        APIKeyStep(number: 3, text: "Tap your profile picture or username in the top right corner.")
                        APIKeyStep(number: 4, text: "Tap **Settings** from the dropdown menu.")
                        APIKeyStep(number: 5, text: "Scroll down and tap **Developers** in the left sidebar.")
                        APIKeyStep(number: 6, text: "Under the **Personal Access Tokens** section, tap **Generate new token**.")
                        APIKeyStep(number: 7, text: "Copy the token that appears.")
                        APIKeyStep(number: 8, text: "Come back here and paste it into the **Discogs Personal Access Token** field.")
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Without a token you can still search, but you're limited to 25 requests per minute. With one, you get 60.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Link(destination: URL(string: "https://www.discogs.com/settings/developers")!) {
                        Label("Open Discogs Developer Settings", systemImage: "arrow.up.right.square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Get a Discogs Token")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
