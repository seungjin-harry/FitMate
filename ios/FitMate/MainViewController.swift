import UIKit
import AVFoundation

class MainViewController: UIViewController {
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "FitMateLogo")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let contentTypeSegmentedControl: UISegmentedControl = {
        let items = ContentType.allCases.map { $0.description }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("촬영하기", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "제목을 입력하세요"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private var capturedMediaURL: URL?
    private let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupImagePicker()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(logoImageView)
        view.addSubview(contentTypeSegmentedControl)
        view.addSubview(titleTextField)
        view.addSubview(descriptionTextView)
        view.addSubview(captureButton)
        
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 100),
            
            contentTypeSegmentedControl.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
            contentTypeSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentTypeSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            titleTextField.topAnchor.constraint(equalTo: contentTypeSegmentedControl.bottomAnchor, constant: 20),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            titleTextField.heightAnchor.constraint(equalToConstant: 44),
            
            descriptionTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20),
            descriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 150),
            
            captureButton.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 30),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 200),
            captureButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
    }
    
    private func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.mediaTypes = ["public.image", "public.movie"]
    }
    
    @objc private func captureButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "카메라", style: .default) { [weak self] _ in
                self?.imagePicker.sourceType = .camera
                self?.present(self?.imagePicker, animated: true)
            })
        }
        
        alertController.addAction(UIAlertAction(title: "갤러리", style: .default) { [weak self] _ in
            self?.imagePicker.sourceType = .photoLibrary
            self?.present(self?.imagePicker, animated: true)
        })
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func uploadContent(mediaURL: URL) {
        guard let title = titleTextField.text, !title.isEmpty,
              let description = descriptionTextView.text, !description.isEmpty,
              let selectedType = ContentType.allCases[safe: contentTypeSegmentedControl.selectedSegmentIndex] else {
            showAlert(message: "모든 필드를 입력해주세요")
            return
        }
        
        ContentUploader.shared.uploadContent(
            type: selectedType,
            title: title,
            description: description,
            mediaURL: mediaURL
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.showAlert(message: "업로드가 완료되었습니다")
                    self?.resetForm()
                case .failure(let error):
                    self?.showAlert(message: "업로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func resetForm() {
        titleTextField.text = ""
        descriptionTextView.text = ""
        capturedMediaURL = nil
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let mediaURL = info[.mediaURL] as? URL {
            // 비디오
            capturedMediaURL = mediaURL
            uploadContent(mediaURL: mediaURL)
        } else if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage,
                  let imageURL = saveImageToTemporary(image: image) {
            // 이미지
            capturedMediaURL = imageURL
            uploadContent(mediaURL: imageURL)
        }
    }
    
    private func saveImageToTemporary(image: UIImage) -> URL? {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        do {
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            print("이미지 저장 실패: \(error)")
            return nil
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension ContentType: CaseIterable {} 