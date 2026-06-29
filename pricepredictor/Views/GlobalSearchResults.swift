//
//  ContentView.swift
//  pricepredictor
//
//  Created by matthew chadwell on 2/17/26.
//

import SwiftUI

struct GlobalSearchResults: View {
    // Need to store the searched text in the Bank vault,bucket for the text.
    @State private var searchText = ""
    // Connects logic to the UI "Broacaster tower"
    @State private var viewModel = SearchViewModel()
    // In a simple search app, you don't strictly need to manage the task manually because .onSubmit creates a fresh one. However, if you were doing search-as-you-type,
    // Manage the task manually here ,if want to change the search implementation in future
    // @State private var task: Task<(), Never>?


    // Define the 2-column layout
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    /// Solid header fill on iOS; `Color.clear` elsewhere so macOS SourceKit does not require UIKit.
    private var headerSurfaceBackground: Color {
        #if os(iOS)
        Color(UIColor.systemBackground)
        #else
        Color.clear
        #endif
    }

    // Header for Specific Issues (The Grid)
    private var issuesHeaderSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Use the first issue's volume name if available, otherwise fallback
            Text(viewModel.issueVM.issues.first?.volume?.name ?? "Issue Results")
                .font(.title2.bold())
            Text("\(viewModel.issueVM.issues.count) Issues Found")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(headerSurfaceBackground) // Keeps header solid during scroll
    }

    // Header for Volumes (The List)
    private var volumesHeaderSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Matching Series")
                .font(.title2.bold())
            Text("Select a volume to view all issues")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(headerSurfaceBackground)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Dynamic Header Logic
                if !viewModel.lastSubmittedSearch.isEmpty {
                    Text("Results for \"\(viewModel.lastSubmittedSearch)\"")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                // 2. Main Content Switcher
                if viewModel.isLoading {
                    ProgressView("Fetching comics...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    switch viewModel.resultMode {

                    case .issues:
                        if viewModel.issueVM.issues.isEmpty {
                            ContentUnavailableView("No Specific Issues Found", systemImage: "magnifyingglass")
                        } else {
                            // needed to create a separate Vstack for each switch case view ,issues and volumes
                            VStack(spacing: 0) {
                                issuesHeaderSection // ⬅️ Unique Issue Header

                                ScrollView {
                                    LazyVGrid(columns: columns, spacing: 20) {
                                        ForEach(viewModel.issueVM.issues) { issue in
                                            NavigationLink(value: issue) {
                                                ProductRow(item: issue, layout: .grid)
                                            }
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }

                    case .volumes:
                        if viewModel.products.isEmpty {
                            ContentUnavailableView("Perform a search", systemImage: "book.closed")
                        } else {
                            VStack(spacing: 0) {
                                volumesHeaderSection // ⬅️ Unique Volume Header

                                List(viewModel.products) { product in
                                    NavigationLink(value: product) {
                                        ProductRow(item: product)
                                    }
                                }
                                .listStyle(.plain)
                            }
                        }
                    }
                }
            }
            // 3. Navigation Destinations
            .navigationDestination(for: Volumes.self) { volume in
                VolumeIssuesDetailView(volume: volume)
            }
            .navigationDestination(for: ComicIssues.self) { issue in
                IssueDetailView(issue: issue)
                // This is where you'd show the specific pricing/variant data
                //                IssueDetailView(issue: issue)
            }

            // In SwiftUI, the visual order of modifiers like .alert, .onSubmit, and .onChange doesn't strictly follow the "order of operations." Since they are all "listeners" waiting for different events, they can sit in any order.
            .navigationTitle("Collectibles")
            // binding
            .searchable(text: $searchText,prompt: "Search by title")
            // When it fires: Every time the user types or deletes a single letter.
            // What it does: Checks if the bar is empty. If yes, it hides the old results.
            .onChange(of: searchText) { oldValue, newValue in
                // Only clear if the user manually emptied the field
                if newValue.isEmpty && !viewModel.isLoading {
                    viewModel.products = []
                    viewModel.issueVM.issues = []
                }
            }
            // Final action , user taps submit button
            .onSubmit(of: .search) {
                let cleanQuery = searchText.trimmingCharacters(in: .whitespaces)

                if !cleanQuery.isEmpty {
                    Task {
                        // 🚀 Call the Smart Search instead of just loadData
                        await viewModel.performSmartSearch(input: cleanQuery)

                        // 🪄 Clear the bar and reset local state
                        //                            searchText = ""
                    }
                }
            }
            // .alert is a Presentation Modifier. When showAlert becomes true, SwiftUI ignores your layout stacks and tells the iOS System: "Dim the whole screen and pop this box over everything."
            // Even if you moved the .alert code to the very top of your body or the very bottom, it would still look the same to the user. This is because .alert is a Presentation Modifier
            .alert("Search Issue", isPresented: $viewModel.showAlert) {
                // The Safety Net (Catches the errors from the API)
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred.")
            }
        }
    }
}
#Preview {
    GlobalSearchResults()
}
