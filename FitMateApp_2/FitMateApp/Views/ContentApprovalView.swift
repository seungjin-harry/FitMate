import SwiftUI

struct ContentApprovalView: View {
    @StateObject private var viewModel = ContentApprovalViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.pendingContents) { content in
                    ContentApprovalCell(content: content) { approved in
                        if approved {
                            viewModel.approveContent(content)
                        } else {
                            viewModel.rejectContent(content)
                        }
                    }
                }
            }
            .navigationTitle("컨텐츠 승인")
            .refreshable {
                await viewModel.loadPendingContents()
            }
        }
    }
}

struct ContentApprovalCell: View {
    let content: PendingContent
    let onAction: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let image = content.thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            
            Text(content.title)
                .font(.headline)
            
            Text("작성자: \(content.author)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Button(action: { onAction(true) }) {
                    Text("승인")
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                
                Button(action: { onAction(false) }) {
                    Text("거절")
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

struct PendingContent: Identifiable {
    let id: String
    let title: String
    let author: String
    let thumbnail: UIImage?
    let contentURL: URL
    let type: ContentType
}

class ContentApprovalViewModel: ObservableObject {
    @Published var pendingContents: [PendingContent] = []
    
    func loadPendingContents() async {
        // TODO: API 연동
        // 임시 데이터
        DispatchQueue.main.async {
            self.pendingContents = [
                PendingContent(
                    id: "1",
                    title: "운동 루틴 1",
                    author: "trainer1",
                    thumbnail: UIImage(systemName: "photo"),
                    contentURL: URL(string: "https://example.com")!,
                    type: .photo
                ),
                PendingContent(
                    id: "2",
                    title: "스트레칭 가이드",
                    author: "trainer2",
                    thumbnail: UIImage(systemName: "video"),
                    contentURL: URL(string: "https://example.com")!,
                    type: .video
                )
            ]
        }
    }
    
    func approveContent(_ content: PendingContent) {
        // TODO: API 연동
        if let index = pendingContents.firstIndex(where: { $0.id == content.id }) {
            pendingContents.remove(at: index)
        }
    }
    
    func rejectContent(_ content: PendingContent) {
        // TODO: API 연동
        if let index = pendingContents.firstIndex(where: { $0.id == content.id }) {
            pendingContents.remove(at: index)
        }
    }
} 