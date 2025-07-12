import SwiftUI
import AVFoundation
import Photos

struct ContentCreationView: View {
    @StateObject private var viewModel = ContentCreationViewModel()
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedContentType: ContentType = .photo
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("컨텐츠 타입", selection: $selectedContentType) {
                    ForEach(ContentType.allCases) { type in
                        Text(type.description).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
                
                if viewModel.isVideoRecorded {
                    Text("비디오가 녹화되었습니다")
                        .foregroundColor(.green)
                        .padding()
                }
                
                Button(action: {
                    if selectedContentType == .photo {
                        showCamera = true
                    } else {
                        viewModel.startVideoRecording()
                    }
                }) {
                    HStack {
                        Image(systemName: selectedContentType == .photo ? "camera" : "video")
                        Text(selectedContentType == .photo ? "사진 촬영" : "비디오 녹화")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                if selectedContentType == .video && viewModel.isRecording {
                    Button(action: viewModel.stopVideoRecording) {
                        Text("녹화 중지")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                if viewModel.hasContent {
                    Button(action: viewModel.saveContent) {
                        Text("저장")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("컨텐츠 생성")
            .sheet(isPresented: $showCamera) {
                CameraView(image: $viewModel.capturedImage)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("알림"), message: Text(alertMessage), dismissButton: .default(Text("확인")))
            }
        }
    }
}

enum ContentType: String, CaseIterable, Identifiable {
    case photo
    case video
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .photo: return "사진"
        case .video: return "비디오"
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
} 