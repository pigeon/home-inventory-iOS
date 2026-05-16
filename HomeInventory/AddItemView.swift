//
//  AddItemView.swift
//  HomeInventory
//
//  Created by Dmytro Golub on 03/06/2025.
//
import SwiftUI
import PhotosUI
#if os(iOS)
import UIKit
#endif

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddItemViewModel

    init(boxId: Int, onDone: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddItemViewModel(boxId: boxId, onDone: onDone))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Custom Name", text: $viewModel.name)
                    TextField("Note", text: $viewModel.note)
                }
                .listRowBackground(Color.appSurface)
                PhotoPickerSection(photo: $viewModel.photo)

                if viewModel.isAnalyzingPhoto || !viewModel.suggestedNames.isEmpty || viewModel.suggestionMessage != nil {
                    Section("Suggested Items") {
                        if let primarySuggestedName = viewModel.primarySuggestedName {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recognized object")
                                    .font(.caption)
                                    .foregroundStyle(Color.appTextSecondary)
                                Text(primarySuggestedName.localizedCapitalized)
                                    .font(.headline)
                                    .foregroundStyle(Color.appTextPrimary)
                            }
                        }

                        if viewModel.isAnalyzingPhoto {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text("Analyzing photo…")
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                        }

                        ForEach(viewModel.suggestedNames, id: \.self) { suggestion in
                            Button {
                                viewModel.toggleSuggestion(suggestion)
                            } label: {
                                HStack {
                                    Text(suggestion.capitalized)
                                        .foregroundStyle(Color.appTextPrimary)
                                    Spacer()
                                    if viewModel.selectedSuggestedNames.contains(suggestion) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.appPrimary)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(Color.appBorder)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        if let suggestionMessage = viewModel.suggestionMessage {
                            Text(suggestionMessage)
                                .font(.footnote)
                                .foregroundStyle(Color.appTextSecondary)
                        } else if !viewModel.suggestedNames.isEmpty {
                            Text("Tap one or more suggestions. Each selected suggestion will be saved as a separate item with the same photo.")
                                .font(.footnote)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                    }
                    .listRowBackground(Color.appSurfaceSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .onChange(of: viewModel.photo) {
                viewModel.analyzePhotoSuggestions()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.appTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                    }
                    .disabled(!viewModel.canSave)
                    .foregroundStyle(viewModel.canSave ? Color.appPrimary : Color.appTextSecondary)
                }
            }
            .navigationTitle("Add Item")
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            }, message: {
                if let msg = viewModel.errorMessage { Text(msg) }
            })
        }
    }
}


struct PhotoPickerSection: View {
    @Binding var photo: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    #if os(iOS)
    @State private var isShowingCamera = false
    @State private var showCameraUnavailableAlert = false
    #endif

    var body: some View {
        Section {
            PhotosPicker("Select Photo", selection: $selectedPhoto, matching: .images)
                .onChange(of: selectedPhoto) {
                    Task {
                        if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                            photo = data
                        }
                    }
                }

            #if os(iOS)
            Button("Take Photo") {
                guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                    showCameraUnavailableAlert = true
                    return
                }
                isShowingCamera = true
            }
            #endif

            if let photo = photo {
                #if os(iOS)
                if let uiImage = UIImage(data: photo) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediaCornerRadius, style: .continuous))
                }
                #elseif os(macOS)
                if let nsImage = NSImage(data: photo) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediaCornerRadius, style: .continuous))
                }
                #endif
            }
        }
        .listRowBackground(Color.appSurface)
        #if os(iOS)
        .sheet(isPresented: $isShowingCamera) {
            CameraImagePicker(photoData: $photo)
        }
        .alert("Camera Unavailable", isPresented: $showCameraUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device does not support camera capture.")
        }
        #endif
    }
}

#if os(iOS)
private struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var photoData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraImagePicker

        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.photoData = image.jpegData(compressionQuality: 0.9)
            }
            parent.dismiss()
        }
    }
}
#endif
