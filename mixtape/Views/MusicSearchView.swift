//
//  MusicSearchView.swift
//  mixtape
//

import SwiftUI

struct MusicSearchView: View {

    var onAdd: (Song) -> Void

    @StateObject private var search = MusicSearchService()
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.yellow)
                        TextField("Search songs", text: $query)
                            .foregroundStyle(AppTheme.ink)
                            .textInputAutocapitalization(.never)
                            .submitLabel(.search)
                            .onSubmit { Task { await search.search(query) } }
                    }
                    .padding(14)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if search.isLoading {
                        ProgressView()
                            .tint(AppTheme.yellow)
                            .padding(.top, 30)
                        Spacer()
                    } else if let error = search.errorMessage, search.results.isEmpty {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(search.results) { item in
                                    Button {
                                        ClickSoundService.shared.playClick(style: .soft)
                                        onAdd(item.asSong())
                                        dismiss()
                                    } label: {
                                        HStack(spacing: 12) {
                                            artwork(item.artworkURL)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.title)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(AppTheme.ink)
                                                    .lineLimit(2)
                                                Text(item.artist)
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(AppTheme.secondaryText)
                                            }

                                            Spacer()

                                            Image(systemName: "plus.circle.fill")
                                                .foregroundStyle(AppTheme.yellow)
                                                .font(.system(size: 22))
                                        }
                                        .padding(12)
                                        .background(AppTheme.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationTitle("Find Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        ClickSoundService.shared.playClick()
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.sportsBlue)
                }
            }
            .onChange(of: query) { _, newValue in
                Task {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    guard newValue == query else { return }
                    await search.search(newValue)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private func artwork(_ urlString: String?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.surfaceLight)
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Image(systemName: "music.note")
                            .foregroundStyle(AppTheme.yellow)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: "music.note")
                    .foregroundStyle(AppTheme.yellow)
            }
        }
        .frame(width: 52, height: 52)
        .clipped()
    }
}
