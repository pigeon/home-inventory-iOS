//
//  ContentView.swift
//  HomeInventory
//
//  Created by Dmytro Golub on 28/05/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var boxes: [Box] = []
    @State private var isLoading = false
    @State private var isShowingAddSheet = false
    @State private var searchText = ""
    @State private var searchResults: [Item] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty {
                    Section("Search Results") {
                        ForEach(searchResults) { item in
                            VStack(alignment: .leading) {
                                Text(item.name)
                                if let note = item.note {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }


                                if let box = boxes.first(where: { $0.id == item.boxId }) {
                                    Text("Box: \(box.number)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Box: Unknown")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                } else {
                    Section("Boxes") {
                        ForEach(boxes) { box in
                            NavigationLink {
                                BoxDetailView(boxId: box.id)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(box.number)
                                        .bold()

                                    if let description = box.description {
                                        Text(description)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }.onDelete(perform: deleteBox)
                    }
                }
            }
            .navigationTitle("Boxes")
            .searchable(text: $searchText, prompt: "Search items...")
            .onChange(of: searchText) { text in
                Task {
                    await search(query: text)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddBoxView(onSave: addBox)
            }.refreshable {
                await loadBoxes()
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
            .task {
                await loadBoxes()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            }, message: {
                if let msg = errorMessage {
                    Text(msg)
                }
            })
        }
    }

    private func loadBoxes() async {
        isLoading = true
        defer { isLoading = false }

        do {
            boxes = try await APIClient.shared.listBoxes()
        } catch {
            errorMessage = "Error loading boxes: \(error.localizedDescription)"
        }
    }

    private func addBox(number: String, description: String?, photo: Data?) {
        isShowingAddSheet = false

        Task {
            do {
                let newBox = try await APIClient.shared.createBox(
                    number: number,
                    description: description,
                    photoData: photo
                )
                boxes.append(newBox)
            } catch {
                errorMessage = "Error creating box: \(error.localizedDescription)"
            }
        }
    }

    private func search(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        do {
            searchResults = try await APIClient.shared.searchItems(query: query)
        } catch {
            errorMessage = "Search error: \(error.localizedDescription)"
            searchResults = []
        }
    }

    func deleteBox(at offsets: IndexSet) {
        for index in offsets {
            let boxId = boxes[index].id
            Task {
                do {
                    try await APIClient.shared.deleteBoxFromAPI(boxId: boxId)
                    boxes.remove(at: index)
                } catch {
                    errorMessage = "Error deleting box: \(error.localizedDescription)"
                }
            }
        }
    }
}
