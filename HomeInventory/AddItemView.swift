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
                    TextField("Name", text: $viewModel.name)
                    TextField("Note", text: $viewModel.note)
                }
                PhotoPickerSection(photo: $viewModel.photo)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .navigationTitle("Add Item")
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
                }
                #elseif os(macOS)
                if let nsImage = NSImage(data: photo) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                }
                #endif
            }
        }
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
