//
//  ProfileView.swift
//  mixtape
//

import SwiftUI

struct ProfileView: View {

    @EnvironmentObject private var store: MixtapeStore
    @State private var displayName = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var savedToast = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.lavender, AppTheme.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 96, height: 96)
                            .shadow(color: AppTheme.purple.opacity(0.45), radius: 18)

                        Text(initials)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.black)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 6) {
                        Text(store.profile.displayName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                        Text("@\(store.profile.username)")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.lavender)
                    }

                    HStack(spacing: 18) {
                        stat(store.createdMixtapes.count, label: "Created")
                        stat(store.favoriteMixtapes.count, label: "Favorites")
                        stat(store.receivedMixtapes.count, label: "Received")
                    }
                    .padding(.vertical, 8)

                    AppearanceModePicker()
                        .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 14) {
                        field("Display name", text: $displayName)
                        field("Username", text: $username)
                        field("Bio", text: $bio, axis: .vertical)

                        Button(action: save) {
                            Text("SAVE PROFILE")
                                .font(.system(size: 13, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color(hex: "#121214"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .sportsClick(.hard)
                    }
                    .padding(16)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Music identity")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                        Text(store.profile.bio?.isEmpty == false
                             ? store.profile.bio!
                             : "Tell people what your mixtapes feel like.")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Profile")
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .onAppear {
            displayName = store.profile.displayName
            username = store.profile.username
            bio = store.profile.bio ?? ""
        }
        .overlay(alignment: .bottom) {
            if savedToast {
                Text("Profile saved")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.surfaceLight)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
            }
        }
    }

    private var initials: String {
        let parts = store.profile.displayName.split(separator: " ")
        let chars = parts.prefix(2).compactMap { $0.first }
        return chars.isEmpty ? "M" : String(chars)
    }

    private func stat(_ value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func field(_ title: String, text: Binding<String>, axis: Axis = .horizontal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
            if axis == .vertical {
                TextField(title, text: text, axis: .vertical)
                    .lineLimit(3...5)
                    .foregroundStyle(AppTheme.ink)
            } else {
                TextField(title, text: text)
                    .foregroundStyle(AppTheme.ink)
            }
        }
        .padding(12)
        .background(AppTheme.surfaceLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func save() {
        var profile = store.profile
        profile.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? profile.displayName
            : displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .lowercased()
        profile.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        store.updateProfile(profile)
        withAnimation { savedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { savedToast = false }
        }
    }
}
