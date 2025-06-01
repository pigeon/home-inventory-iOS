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
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
            .task {
                await loadBoxes()
            }
        }
    }

    private func loadBoxes() async {
        isLoading = true
        defer { isLoading = false }

        do {
            boxes = try await APIClient.shared.listBoxes()
        } catch {
            print("Error loading boxes: \(error.localizedDescription)")
        }
    }

    private func addBox(number: String, description: String?) {
        isShowingAddSheet = false

        Task {
            do {
                let newBox = try await APIClient.shared.createBox(
                    number: number,
                    description: description
                )
                boxes.append(newBox)
            } catch {
                print("Error creating box: \(error.localizedDescription)")
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
            print("Search error: \(error.localizedDescription)")
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
                    print("Error deleting box: \(error)")
                }
            }
        }
    }
}


struct AddBoxView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var number = ""
    @State private var description = ""

    let onSave: (String, String?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Number", text: $number)
                    TextField("Description (Optional)", text: $description)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            number,
                            description.isEmpty ? nil : description
                        )
                    }
                    .disabled(number.isEmpty)
                }
            }
            #if os(iOS)
            .navigationTitle("Add Box")
            #else
            .navigationTitle("Add New Box")
            #endif
        }
    }
}

struct BoxDetailView: View {
    let boxId: Int
    @State private var detail: BoxDetail?
    @State private var loading = false
    @State private var addItem = false
    @State private var name = ""
    @State private var note = ""
    @State private var photo: Data?

    var body: some View {
        List {
            if let detail = detail {
                Section {
                    Text("Number: \(detail.number)")
                    if let description = detail.description {
                        Text(description)
                    }
                }

                Section {
                    ForEach(detail.items ?? []) { item in
                        VStack(alignment: .leading) {
                            Text(item.name)
                            if let note = item.note {
                                Text(note)
                                    .font(.caption)
                            }
                        }
                    }
                }
            } else if loading {
                ProgressView()
            } else {
                Text("Error loading box details")
            }
        }
        .navigationTitle("Box Details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $addItem) {
            AddItemView(boxId: boxId, onDone: refresh)
        }
        .task {
            await fetch()
        }
    }

    private func fetch() async {
        loading = true
        defer { loading = false }

        do {
            detail = try await APIClient.shared.getBox(boxId)
        } catch {
            print("Error fetching box details: \(error)")
        }
    }

    private func refresh() {
        addItem = false
        Task {
            await fetch()
        }
    }
}


struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    let boxId: Int
    var onDone: () -> Void
    @State private var name = ""
    @State private var note = ""
    @State private var photo: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Note", text: $note)
                }
                // Photo picker omitted for brevity
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        add()
                    }
                    .disabled(name.isEmpty)  // Disable save if name is empty
                }
            }
            .navigationTitle("Add Item")
        }
    }

    func add() {
        Task {
            do {
                _ = try await APIClient.shared.createItem(
                    boxId: boxId,
                    name: name,
                    note: note.isEmpty ? nil : note,
                    photoData: photo
                )
                await MainActor.run {
                    onDone()
                    dismiss()
                }
            } catch {
                print("Error adding item: \(error)")
                // Consider showing an error alert to the user
            }
        }
    }
}
