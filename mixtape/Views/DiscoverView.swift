//
//  DiscoverView.swift
//  mixtape
//

import SwiftUI

struct DiscoverView: View {

    @EnvironmentObject private var store: MixtapeStore
    @State private var query = ""

    private var filtered: [Mixtape] {
        let base = store.publicDiscover
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.description.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        ZStack {
            ScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Find tapes people shared publicly.")
                        .font(AppTheme.body(15))
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.horizontal, 20)

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.secondaryText)
                        TextField("Search", text: $query)
                            .font(AppTheme.body(15))
                            .foregroundStyle(AppTheme.ink)
                    }
                    .padding(14)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 20)

                    if filtered.isEmpty {
                        EmptyHint(
                            icon: "sparkles",
                            title: "No matches",
                            message: "Try another search word."
                        )
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(filtered) { mixtape in
                                NavigationLink {
                                    MixtapeDetailView(mixtapeID: mixtape.id)
                                } label: {
                                    discoverCard(mixtape)
                                }
                                .buttonStyle(.plain)
                                .recorderTap(.soft)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Discover")
    }

    private func discoverCard(_ mixtape: Mixtape) -> some View {
        SoftPanel(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                RealisticCassetteView(
                    title: mixtape.title,
                    accent: mixtape.accentColor,
                    shellTint: mixtape.shellTintColor,
                    labelImage: mixtape.labelUIImage,
                    isPlaying: false,
                    interactive3D: false
                )
                .frame(height: 150)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mixtape.title)
                            .font(AppTheme.title(16))
                            .foregroundStyle(AppTheme.ink)
                        Text("\(mixtape.songCount) songs")
                            .font(AppTheme.body(12))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }
}
