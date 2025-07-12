import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            if authManager.isAdmin {
                ContentApprovalView()
                    .tabItem {
                        Image(systemName: "checkmark.circle")
                        Text("컨텐츠 승인")
                    }
            } else {
                ContentCreationView()
                    .tabItem {
                        Image(systemName: "camera")
                        Text("컨텐츠 생성")
                    }
            }
            
            ContentListView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("컨텐츠 목록")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("프로필")
                }
        }
    }
} 