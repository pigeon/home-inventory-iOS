# HomeInventory

A simple SwiftUI app for tracking boxes and items in your home. The project can run on iOS and macOS.

## Building

Open `HomeInventory.xcodeproj` in Xcode and build/run the **HomeInventory** scheme. The project uses async/await and requires Xcode 15 or newer.

The backend API defaults to `http://127.0.0.1:8000`. To point the app at another server, set the `API_BASE_URL` environment variable in the run scheme.

## Tests

Unit and UI test targets are included but contain only template code. Future work could add real tests for `APIClient` and the UI.

## License

This project is released under the MIT License. See [LICENSE](LICENSE) for details.
