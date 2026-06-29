# Product Predictor

Native iOS **Collectibles** app for browsing comic books via the [Comic Vine API](https://comicvine.gamespot.com/api/). Search by series title or title + issue number, browse volumes, view issues, and open issue detail.

> **Note:** Price prediction is planned but not yet implemented.

## Quick Start

1. Copy `Secrets.example.xcconfig` to `Secrets.xcconfig` and add your Comic Vine API key.
2. Open `pricepredictor.xcodeproj` in Xcode 26.2+.
3. Run the **pricepredictor** scheme on an iOS Simulator.

## Documentation

See **[docs/REFERENCE.md](docs/REFERENCE.md)** for full architecture, file map, API details, configuration, known gaps, and roadmap.

## Stack

SwiftUI · `@Observable` MVVM · `URLSession` · no third-party dependencies
