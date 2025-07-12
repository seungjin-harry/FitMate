import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var isAdmin = false
    
    var token: String?
    
    init() {
        // 저장된 토큰이 있는지 확인
        if let savedToken = UserDefaults.standard.string(forKey: "userToken") {
            self.token = savedToken
            validateToken()
        } else {
            isLoading = false
        }
    }
    
    func login(username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        // TODO: API 연동
        guard let url = URL(string: "http://localhost:8000/token") else {
            completion(false, "Invalid URL")
            return
        }
        
        let parameters = ["username": username, "password": password]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                
                guard let data = data else {
                    completion(false, "No data received")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(LoginResponse.self, from: data)
                    self?.token = response.access_token
                    UserDefaults.standard.set(response.access_token, forKey: "userToken")
                    self?.isAuthenticated = true
                    self?.isAdmin = username == "admin" // 임시로 admin 계정 체크
                    completion(true, "Login successful")
                } catch {
                    completion(false, "Failed to parse response")
                }
            }
        }.resume()
    }
    
    func logout() {
        token = nil
        isAuthenticated = false
        isAdmin = false
        UserDefaults.standard.removeObject(forKey: "userToken")
    }
    
    private func validateToken() {
        // TODO: API 연동
        // 임시로 토큰이 있으면 인증된 것으로 처리
        isAuthenticated = token != nil
        isLoading = false
    }
}

struct LoginResponse: Codable {
    let access_token: String
    let token_type: String
} 