//
//  LibraryView.swift
//  mixtape
//

import SwiftUI

struct LibraryView: View {

    @EnvironmentObject private var store: MixtapeStore
    @State private var segment = 0

    private var items: [Mixtape] {
        switch segment {
        case 1: return store.receivedMixtapes
        case 2: return store.favoriteMixtapes
        default: return store.createdMixtapes
        }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Picker("Library", selection: $segment) {
                    Text("Created").tag(0)
                    Text("Received").tag(1)
                    Text("Favorites").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                if items.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "square.stack.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(AppTheme.lavender)
                        Text(emptyTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                        Text(emptySubtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(items) { mixtape in
                                NavigationLink {
                                    MixtapeDetailView(mixtapeID: mixtape.id)
                                } label: {
                                    MixtapeRowView(
                                        mixtape: mixtape,
                                        isFavorite: store.isFavorite(mixtape.id)
                                    )
                                }
                                .buttonStyle(.plain)
                                .recorderTap(.soft)
                                .contextMenu {
                                    Button {
                                        store.toggleFavorite(mixtape.id)
                                    } label: {
                                        Label(
                                            store.isFavorite(mixtape.id) ? "Unfavorite" : "Favorite",
                                            systemImage: "heart"
                                        )
                                    }

                                    if segment == 0 {
                                        Button(role: .destructive) {
                                            store.delete(mixtape.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationTitle("Library")
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private var emptyTitle: String {
        switch segment {
        case 1: return "No received mixtapes"
        case 2: return "No favorites yet"
        default: return "No mixtapes yet"
        }
    }

    private var emptySubtitle: String {
        switch segment {
        case 1: return "Save public mixtapes from Discover to hear them here."
        case 2: return "Tap the heart on any mixtape to keep it close."
        default: return "Create your first cassette and it will appear here."
        }
    }
}
