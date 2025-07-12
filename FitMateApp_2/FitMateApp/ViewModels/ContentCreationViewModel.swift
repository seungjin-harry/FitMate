import SwiftUI
import AVFoundation
import Photos

class ContentCreationViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isRecording = false
    @Published var isVideoRecorded = false
    @Published var hasContent: Bool = false
    
    private var videoRecorder: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var currentVideoURL: URL?
    
    var watermarkText = "Lento&Lux Inc."
    
    func startVideoRecording() {
        guard !isRecording else { return }
        
        if videoRecorder == nil {
            setupVideoRecorder()
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        currentVideoURL = documentsPath.appendingPathComponent("video_\(Date().timeIntervalSince1970).mov")
        
        if let url = currentVideoURL {
            videoOutput?.startRecording(to: url, recordingDelegate: self)
            isRecording = true
        }
    }
    
    func stopVideoRecording() {
        videoOutput?.stopRecording()
    }
    
    private func setupVideoRecorder() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        let output = AVCaptureMovieFileOutput()
        
        if session.canAddInput(input) && session.canAddOutput(output) {
            session.addInput(input)
            session.addOutput(output)
            
            videoRecorder = session
            videoOutput = output
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.videoRecorder?.startRunning()
            }
        }
    }
    
    func saveContent() {
        if let image = capturedImage {
            let watermarkedImage = addWatermark(to: image)
            UIImageWriteToSavedPhotosAlbum(watermarkedImage, nil, nil, nil)
            hasContent = false
            capturedImage = nil
        } else if let videoURL = currentVideoURL {
            addWatermarkToVideo(at: videoURL) { success in
                if success {
                    self.isVideoRecorded = false
                    self.hasContent = false
                    self.currentVideoURL = nil
                }
            }
        }
    }
    
    private func addWatermark(to image: UIImage) -> UIImage {
        let imageSize = image.size
        let scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        let watermarkedImage = renderer.image { context in
            // 원본 이미지 그리기
            image.draw(in: CGRect(origin: .zero, size: imageSize))
            
            // 워터마크 텍스트 설정
            let text = watermarkText
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Arial", size: 12) ?? UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray.withAlphaComponent(0.5)
            ]
            let textSize = text.size(withAttributes: attributes)
            
            // 대각선으로 워터마크 위치 계산
            let angle = -45 * CGFloat.pi / 180
            let x = (imageSize.width - textSize.width) / 2
            let y = (imageSize.height - textSize.height) / 2
            
            // 컨텍스트 회전
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: x + textSize.width / 2, y: y + textSize.height / 2)
            context.cgContext.rotate(by: angle)
            context.cgContext.translateBy(x: -(x + textSize.width / 2), y: -(y + textSize.height / 2))
            
            // 워터마크 그리기
            text.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
            context.cgContext.restoreGState()
        }
        
        return watermarkedImage
    }
    
    private func addWatermarkToVideo(at videoURL: URL, completion: @escaping (Bool) -> Void) {
        let asset = AVAsset(url: videoURL)
        let composition = AVMutableComposition()
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(false)
            return
        }
        
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            
            let videoSize = videoTrack.naturalSize
            
            let watermarkText = self.watermarkText
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Arial", size: 12) ?? UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray.withAlphaComponent(0.5)
            ]
            let textSize = watermarkText.size(withAttributes: attributes)
            
            let watermarkLayer = CATextLayer()
            watermarkLayer.string = watermarkText
            watermarkLayer.font = "Arial" as CFTypeRef
            watermarkLayer.fontSize = 12
            watermarkLayer.foregroundColor = UIColor.gray.withAlphaComponent(0.5).cgColor
            watermarkLayer.frame = CGRect(x: (videoSize.width - textSize.width) / 2,
                                        y: (videoSize.height - textSize.height) / 2,
                                        width: textSize.width,
                                        height: textSize.height)
            watermarkLayer.transform = CATransform3DMakeRotation(-45 * CGFloat.pi / 180, 0, 0, 1)
            
            let overlayLayer = CALayer()
            overlayLayer.addSublayer(watermarkLayer)
            overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
            
            let videoComposition = AVMutableVideoComposition()
            videoComposition.renderSize = videoSize
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: CALayer(),
                                                                                in: overlayLayer)
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = timeRange
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            instruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [instruction]
            
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
            let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("watermarked_video_\(Date().timeIntervalSince1970).mov")
            
            exportSession?.videoComposition = videoComposition
            exportSession?.outputURL = outputURL
            exportSession?.outputFileType = .mov
            
            exportSession?.exportAsynchronously {
                DispatchQueue.main.async {
                    if exportSession?.status == .completed {
                        if let outputURL = exportSession?.outputURL {
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
                            }) { success, error in
                                DispatchQueue.main.async {
                                    completion(success)
                                }
                            }
                        }
                    } else {
                        completion(false)
                    }
                }
            }
        } catch {
            completion(false)
        }
    }
}

extension ContentCreationViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        isRecording = false
        if error == nil {
            isVideoRecorded = true
            hasContent = true
        }
    }
} 