//
//  FeaturePlaceholderView.swift
//  mixtape
//
//  Created by ManoveKumar on 06/11/2026.
//


import SwiftUI

struct FeaturePlaceholderView: View {

    let title: String
    let description: String

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "opticaldisc.fill")
                    .font(.system(size: 65))
                    .foregroundStyle(AppTheme.lavender)

                Text(title)
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(AppTheme.ink)

                Text(description)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 25)

                Text("COMING SOON")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(AppTheme.lavender)
                    .padding(.top, 10)
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
