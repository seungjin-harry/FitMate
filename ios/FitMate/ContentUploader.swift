import Foundation
import UIKit
import AVFoundation

enum ContentType: String {
    case daily = "DAILY"
    case artistic = "ARTISTIC"
    case philosophy = "PHILOSOPHY"
    case work = "WORK"
    case interview = "INTERVIEW"
    
    var description: String {
        switch self {
        case .daily: return "감성적 일상 나눔"
        case .artistic: return "예술적 취향 나눔"
        case .philosophy: return "인용 및 철학"
        case .work: return "작품 소개"
        case .interview: return "감성 인터뷰"
        }
    }
}

class ContentUploader {
    static let shared = ContentUploader()
    private let baseURL = "http://localhost:8000/api"
    private var token: String?
    
    private init() {}
    
    func setToken(_ token: String) {
        self.token = token
    }
    
    func uploadContent(
        type: ContentType,
        title: String,
        description: String,
        mediaURL: URL,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let token = token else {
            completion(.failure(NSError(domain: "FitMate", code: -1, userInfo: [NSLocalizedDescriptionKey: "토큰이 없습니다"])))
            return
        }
        
        // 워터마크 추가
        if mediaURL.pathExtension.lowercased() == "mov" || mediaURL.pathExtension.lowercased() == "mp4" {
            addWatermarkToVideo(url: mediaURL) { result in
                switch result {
                case .success(let watermarkedURL):
                    self.uploadToServer(type: type, title: title, description: description, mediaURL: watermarkedURL, token: token, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            addWatermarkToImage(url: mediaURL) { result in
                switch result {
                case .success(let watermarkedURL):
                    self.uploadToServer(type: type, title: title, description: description, mediaURL: watermarkedURL, token: token, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func addWatermarkToImage(url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let image = UIImage(contentsOfFile: url.path) else {
            completion(.failure(NSError(domain: "FitMate", code: -2, userInfo: [NSLocalizedDescriptionKey: "이미지를 불러올 수 없습니다"])))
            return
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        let watermarkText = "Lento&Lux Inc."
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Arial", size: 12) ?? UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray.withAlphaComponent(0.5)
        ]
        let textSize = watermarkText.size(withAttributes: attributes)
        
        // 대각선으로 텍스트 그리기
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        context.translateBy(x: image.size.width/2, y: image.size.height/2)
        context.rotate(by: -45 * .pi / 180)
        watermarkText.draw(at: CGPoint(x: -textSize.width/2, y: -textSize.height/2), withAttributes: attributes)
        context.restoreGState()
        
        let watermarkedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let watermarkedURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        if let imageData = watermarkedImage?.pngData() {
            try? imageData.write(to: watermarkedURL)
            completion(.success(watermarkedURL))
        } else {
            completion(.failure(NSError(domain: "FitMate", code: -3, userInfo: [NSLocalizedDescriptionKey: "워터마크 추가에 실패했습니다"])))
        }
    }
    
    private func addWatermarkToVideo(url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: url)
        let composition = AVMutableComposition()
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(.failure(NSError(domain: "FitMate", code: -4, userInfo: [NSLocalizedDescriptionKey: "비디오 트랙을 생성할 수 없습니다"])))
            return
        }
        
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            
            let videoSize = videoTrack.naturalSize
            
            let watermarkText = "Lento&Lux Inc."
            let textLayer = CATextLayer()
            textLayer.string = watermarkText
            textLayer.font = "Arial" as CFTypeRef
            textLayer.fontSize = 12
            textLayer.foregroundColor = UIColor.gray.withAlphaComponent(0.5).cgColor
            textLayer.alignmentMode = .center
            textLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 20)
            
            let parentLayer = CALayer()
            let videoLayer = CALayer()
            parentLayer.frame = CGRect(origin: .zero, size: videoSize)
            videoLayer.frame = CGRect(origin: .zero, size: videoSize)
            textLayer.position = CGPoint(x: videoSize.width - 60, y: videoSize.height - 20)
            
            parentLayer.addSublayer(videoLayer)
            parentLayer.addSublayer(textLayer)
            
            let videoComposition = AVMutableVideoComposition()
            videoComposition.renderSize = videoSize
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = timeRange
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            instruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [instruction]
            
            let watermarkedURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
            
            guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                completion(.failure(NSError(domain: "FitMate", code: -5, userInfo: [NSLocalizedDescriptionKey: "비디오 내보내기 세션을 생성할 수 없습니다"])))
                return
            }
            
            exportSession.videoComposition = videoComposition
            exportSession.outputURL = watermarkedURL
            exportSession.outputFileType = .mp4
            
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    completion(.success(watermarkedURL))
                case .failed:
                    completion(.failure(exportSession.error ?? NSError(domain: "FitMate", code: -6, userInfo: [NSLocalizedDescriptionKey: "비디오 내보내기에 실패했습니다"])))
                default:
                    completion(.failure(NSError(domain: "FitMate", code: -7, userInfo: [NSLocalizedDescriptionKey: "알 수 없는 오류가 발생했습니다"])))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    private func uploadToServer(
        type: ContentType,
        title: String,
        description: String,
        mediaURL: URL,
        token: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: baseURL + "/content/upload")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var data = Data()
        
        // 텍스트 필드 추가
        let fields = [
            "title": title,
            "description": description,
            "content_type": type.rawValue
        ]
        
        for (key, value) in fields {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // 파일 추가
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(mediaURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        data.append(try! Data(contentsOf: mediaURL))
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let task = URLSession.shared.uploadTask(with: request, from: data) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "FitMate", code: -8, userInfo: [NSLocalizedDescriptionKey: "서버 오류가 발생했습니다"])))
                return
            }
            
            completion(.success(()))
        }
        
        task.resume()
    }
} 