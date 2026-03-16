//
//  ContentView.swift
//  pricepredictor
//
//  Created by matthew chadwell on 2/17/26.
//

import SwiftUI

struct ComicSearchView: View {
    // Need to store the searched text in the Bank vault,bucket for the text.
    @State private var searchText = ""
    // Connects logic to the UI "Broacaster tower"
    @State private var viewModel = SearchViewModel()
    // In a simple search app, you don't strictly need to manage the task manually because .onSubmit creates a fresh one. However, if you were doing search-as-you-type,
    // Manage the task manually here ,if want to change the search implementation in future
    // @State private var task: Task<(), Never>?

    var body: some View {
        // LAYER 1: The Navigator (Handles titles, search bars, and moving between screens)
        NavigationStack {
            ZStack {
                VStack(alignment: .leading) {
                    // Header Logic
                    if !viewModel.lastSubmittedSearch.isEmpty && !viewModel.products.isEmpty {
                        Text("Results for \"\(viewModel.lastSubmittedSearch)\"")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }

                    if viewModel.products.isEmpty {
                        // You can replace this with a custom "No Results" graphic later
                        ContentUnavailableView("No Comics Found", systemImage: "book.closed")
                    } else {
                        // ✅ Calling the ProductRow inside the List
                        List(viewModel.products) { product in
                            NavigationLink(value: product) {
                                ProductRow(item: product)
                            }
                        }
                        // ✅ Modern NavigationStack destination logic
                        .navigationDestination(for: Volumes.self) { volume in
                            VolumeDetailView(volume: volume)
                        }
                    }
                }
            
            // In SwiftUI, the visual order of modifiers like .alert, .onSubmit, and .onChange doesn't strictly follow the "order of operations." Since they are all "listeners" waiting for different events, they can sit in any order.
            .navigationTitle("Collectibles")
            // binding
            .searchable(text: $searchText,prompt: "Search by title")
            // When it fires: Every time the user types or deletes a single letter.
            // What it does: Checks if the bar is empty. If yes, it hides the old results.
            .onChange(of: searchText) { oldValue, newValue in // 2. Detects the change
                if newValue.isEmpty {
                    viewModel.products = [] // Clear results if search is deleted
                }
            }
            // Final action , user taps submit button
            .onSubmit(of: .search){
                let cleanQuery = searchText.trimmingCharacters(in: .whitespaces)
                // Ensures that if a user just hits "Search" while the bar is empty (or just full of spaces), the app won't waste one of your 200 daily Comic Vine API
                if !cleanQuery.isEmpty {
                    Task {
                        await viewModel.loadData(for: searchText)
                        if let timestamp = viewModel.lastFetched {
                            timestamp
                                .formatted(date: .omitted, time: .shortened)
                        }
                        // 🪄 Clear the bar so it's ready for the next search
                        viewModel.searchText = ""
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
    ComicSearchView()
}
