// SearchViewModel.swift (this new one) stays as the "Generalist" that handles the search bar and decides which view to show.

import Foundation

@Observable
class SearchViewModel {
    // UI State
    var searchText = ""
    var lastSubmittedSearch = ""
    var isLoading = false
    var errorMessage: String?
    var showAlert: Bool = false

    // Data Storage
    var products: [Volumes] = [] // For Series results
    var issueVM = IssueViewModel() // For Specific Book results

    // Routing Mode
    enum SearchResultMode { case volumes, issues }
    var resultMode: SearchResultMode = .volumes

    private let service = ProductService()

    // tell the view need fall back
    var showFallbackMessage = false // 👈 Add this trigger

    func performSmartSearch(input: String) async {
        let (title, issueNum) = input.partitionTitleAndIssue()

        self.errorMessage = nil
        self.isLoading = true
        defer { self.isLoading = false }

        if let number = issueNum {
            // 1. SCOUT: Find volumes - Note: the app would be "blindly" searching for numbers without knowing which series they belong to,needs to validate that Volumes exist first before working with the issue #
            let volumes = try? await service.fetchVolumes(for: title)
            let matches = volumes ?? []
            let volumeIDs = matches.map { String($0.id) }.joined(separator: "|")

            if !volumeIDs.isEmpty {
                // 2. STRIKE: Try to find specific issues
                await issueVM.loadBulkIssues(ids: volumeIDs, number: number)

                // ✅ FALLBACK LOGIC:
                // If we tried to find issues but found NONE, strip the number and show volumes instead
                if issueVM.issues.isEmpty {
                    print("⚠️ No issues found for #\(number). Falling back to Volume search for '\(title)'")
                    self.resultMode = .volumes
                    await loadVolumeData(for: title)
                } else {
                    self.resultMode = .issues
                }
            } else {
                // No volumes found at all? Fallback to general volume search just in case
                self.resultMode = .volumes
                await loadVolumeData(for: input)
            }
        } else {
            // No number provided? Standard Volume list
            self.resultMode = .volumes
            await loadVolumeData(for: input)
        }
    }

    private func loadVolumeData(for query: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await service.fetchVolumes(for: query)

            // 1. Prepare the Sieve: "Spider-man" -> ["spiderman"]
            let searchTokens = query.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .map { $0.condensed } // 👈 Normalize the user's input

            if searchTokens.isEmpty {
                self.products = data
                return
            }

            // 2. The Versatile Filter
            self.products = data.filter { volume in
                let volumeName = (volume.name ?? "").condensed // 👈 Normalize the API's result

                // Logic: Does "spiderman" exist inside the condensed volume name?
                return searchTokens.allSatisfy { token in
                    volumeName.contains(token)
                }
            }

            print("✅ Versatile Search: Matched \(self.products.count) volumes.")

        } catch {
            self.products = []
            self.errorMessage = error.localizedDescription
            self.showAlert = true
        }
    }
    @MainActor
    func syncVolumeData(for volumeID: Int, forceRefresh: Bool = false) async {
        // Only fetch if empty OR if we are forcing a refresh (pull-to-refresh)
        if products.isEmpty || forceRefresh {
            await issueVM.loadEntireVolume(for: volumeID)
        }
    }
}
