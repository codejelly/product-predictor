//
//  IssueDetailView.swift
//  pricepredictor
//
//  Created by matthew chadwell on 3/31/26.
//

import SwiftUI

struct IssueDetailView: View {
    let issue: ComicIssues

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Hero Image
                if let imageUrl = issue.image?.screenURL ?? issue.image?.smallURL {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView().frame(height: 300)
                    }
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }

                VStack(alignment: .leading, spacing: 8) {
                    // 2. Title & Volume Info
                    Text(issue.volume?.name ?? "Unknown Series")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text("Issue #\(issue.issueNumber)\(issue.name != nil ? ": \(issue.name!)" : "")")
                        .font(.largeTitle)
                        .bold()

                    // 3. Release Date
                    if let date = issue.storeDate ?? issue.coverDate {
                        Text("Released: \(date)")
                            .font(.subheadline)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)

                Divider()

                // 4. Creative Team (Artist Snapshot)
                if let credits = issue.personCredits, !credits.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Creative Team")
                            .font(.headline)

                        ForEach(credits.prefix(5)) { person in
                            HStack {
                                Text(person.name ?? "Unknown")
                                    .bold()
                                Spacer()
                                Text(person.role ?? "Contributor")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // 5. Description (Using simple HTML stripping)
                if let desc = issue.description {
                    VStack(alignment: .leading) {
                        Text("Summary")
                            .font(.headline)
                        Text(desc.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
