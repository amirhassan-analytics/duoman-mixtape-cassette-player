//
//  MainTabView.swift
//  mixtape
//

import SwiftUI

enum AppTab: String, CaseIterable {
    case home = "Home"
    case discover = "Discover"
    case create = "Create"
    case library = "Library"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .discover: return "safari"
        case .create: return "plus.circle.fill"
        case .library: return "square.stack.fill"
        case .profile: return "person.fill"
        }
    }
}

struct MainTabView: View {

    @EnvironmentObject private var appearance: AppearanceStore
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                }
                .tabItem { Label("Home", systemImage: AppTab.home.icon) }
                .tag(AppTab.home)

                NavigationStack {
                    DiscoverView()
                }
                .tabItem { Label("Discover", systemImage: AppTab.discover.icon) }
                .tag(AppTab.discover)

                NavigationStack {
                    CreateTapeView()
                }
                .tabItem { Label("Create", systemImage: AppTab.create.icon) }
                .tag(AppTab.create)

                NavigationStack {
                    LibraryView()
                }
                .tabItem { Label("Library", systemImage: AppTab.library.icon) }
                .tag(AppTab.library)

                NavigationStack {
                    ProfileView()
                }
                .tabItem { Label("Profile", systemImage: AppTab.profile.icon) }
                .tag(AppTab.profile)
            }
            .tint(AppTheme.accent)
            .toolbarBackground(AppTheme.surface, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(appearance.colorScheme, for: .tabBar)
            .onChange(of: selectedTab) { _, _ in
                ClickSoundService.shared.playClick(style: .soft)
            }

            if selectedTab != .create {
                NowPlayingBar()
                    .padding(.bottom, 49)
            }
        }
    }
}
