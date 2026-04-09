//
//  ProductRow.swift
//  pricepredictor
//
//  Created by matthew chadwell on 2/25/26.
//

import SwiftUI

protocol ComicDisplayable {
    var id: Int { get }
    var name: String? { get }
    var image: ImageLinks? { get }
    var subtitle: String { get }
    var resourceType: String? { get }
    var startYear: String? { get }
    var countOfIssues: Int? { get }
}

extension Volumes: ComicDisplayable {
    var resourceType: String? { "volume" }
    var issueNumber: String? { nil }
    
    // This creates the "1987 (175 issues)" label
    var subtitle: String {
        let year = startYear ?? "Unknown Year"
        let count = countOfIssues ?? 0
        return "\(year) (\(count) issues)"
    }
}

extension ComicIssues: ComicDisplayable {
    // Issues don't have these, so we return nil to satisfy the protocol
    var startYear: String? { nil }
    var countOfIssues: Int? { nil }
    
    // This creates the "Issue #1" or "Issue #1/2" label
    var subtitle: String {
        return "Issue #\(issueNumber)"
    }
}

enum ComicLayout {
    case list // Full width for Volume searches
    case grid // 2-column style for Issue sieving
}

struct ProductRow: View {
    let item: any ComicDisplayable
    var layout: ComicLayout = .list // Default to our existing list style

    var body: some View {
        if layout == .list {
            // Your existing HStack logic / Volumes
            standardHorizontalListLayout
        } else {
            // The 2-column "Grid" logic / Issues
            verticalGridLayout
        }
    }

    // Move your existing code here to keep 'body' readable
    private var standardHorizontalListLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            comicImage(width: 60, height: 90)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "Unknown Title").font(.headline).lineLimit(2)
//                Text(item.subtitle).font(.caption).foregroundColor(.secondary)
                Text(item.resourceType ?? "Unknown Type").font(.caption).foregroundColor(.secondary)
                Text(item.subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var verticalGridLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Taller image for the grid view to help spot cover keys
            comicImage(width: nil, height: 200)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name ?? "Issue").font(.subheadline).bold().lineLimit(1)
                Text(item.subtitle).font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    // Helper to keep image logic in one place
    private func comicImage(width: CGFloat?, height: CGFloat) -> some View {
        AsyncImage(url: URL(string: item.image?.smallURL ?? "")) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.gray.opacity(0.3)
        }
        .frame(width: width, height: height)
        .clipped()
        .cornerRadius(8)
    }
}
