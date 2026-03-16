//
//  VolumeDetailView.swift
//  pricepredictor
//
//  Created by matthew chadwell on 3/16/26.
//

import SwiftUI

struct VolumeIssuesDetailView: View {
    let volume: Volumes
    @State private var issueSearchText = ""
    @State private var issues: [VolumeIssues] = [] // This would be fetched via your Service
    @State private var isLoading = false

    // THE SIEVE: Filters the 30 fetched issues locally by number or title
    var filteredIssues: [VolumeIssues] {
        if issueSearchText.isEmpty {
            return issues
        } else {
            return issues.filter { issue in
                let matchName = (issue.name ?? "").localizedCaseInsensitiveContains(issueSearchText)
                let matchNumber = issue.issueNumber.contains(issueSearchText)
                return matchName || matchNumber
            }
        }
    }

    // Define the 2-column layout
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Header showing volume info
                headerSection
                
                if isLoading {
                    ProgressView("Fetching Issues...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    // The Grid - 30 issues, 2 columns
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredIssues) { issue in
                            // Reuse the ProductRow with the .grid layout flag
                            ProductRow(item: issue, layout: .grid)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(volume.name ?? "Issues")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $issueSearchText, prompt: "Sieve issues...")
        .onAppear {
            // Trigger your API call here for the specific volume ID
            loadIssues()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(volume.name ?? "Unknown Series")
                .font(.title2.bold())
            Text("\(volume.countOfIssues ?? 0) Total Issues")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    func loadIssues() {
        // Placeholder for your Service call:
        // await service.fetchIssues(for: volume.id)
    }
}
