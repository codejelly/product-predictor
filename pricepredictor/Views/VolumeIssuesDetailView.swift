//
//  VolumeIssuesDetailView.swift
//  pricepredictor
//
//  Created by matthew chadwell on 3/16/26.
//

import SwiftUI

struct VolumeIssuesDetailView: View {
    let volume: Volumes
    @State private var issueSearchText = ""
    @State private var issues: [ComicIssues] = [] // This would be fetched via your Service
    @State private var isLoading = false
    @State private var viewModel = IssueViewModel()

    // THE SIEVE: Filters the 30 fetched issues locally by number or title
    var filteredIssues: [ComicIssues] {
        if issueSearchText.isEmpty {
            return viewModel.issues
        } else {
            return viewModel.issues.filter { issue in
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
                issuesHeaderSection
                
                // ✅ USE THE VIEWMODEL'S LOADING STATE
                if viewModel.isLoading {
                    ProgressView("Fetching Issues...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    // The Grid - 30 issues, 2 columns
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredIssues) { issue in
                            // Reuse the ProductRow with the .grid layout flag
                            NavigationLink(destination: IssueDetailView(issue: issue)){
                                ProductRow(item: issue, layout: .grid)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(volume.name ?? "Issues")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $issueSearchText, prompt: "Search issues...")
        .task {
            if viewModel.issues.isEmpty {
                await viewModel.loadEntireVolume(for: volume.id)
            }
        }
        .refreshable {
            // 🔄 This ignores the 'isEmpty' check and forces a network call
            await viewModel.loadEntireVolume(for: volume.id)
        }
    }
    
    private var issuesHeaderSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(volume.name ?? "Unknown Series")
                .font(.title2.bold())
            Text("\(viewModel.totalResultCount) Total Issues")
                .font(.subheadline)
                .foregroundColor(.secondary)
            //prevents confudion for volumes starting on a differnt comic # in a volume other than #1
            if let firstIssue = viewModel.issues.first?.issueNumber {
                Text("Starts at #\(firstIssue)")
            }
        }
        .padding()
    }
    
    func loadIssues() async {
        await viewModel.loadEntireVolume(for: volume.id)
    }
}
