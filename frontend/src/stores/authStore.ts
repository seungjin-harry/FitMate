import create from 'zustand';
import axios from 'axios';

interface AuthState {
  token: string | null;
  isAuthenticated: boolean;
  user: any | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  token: localStorage.getItem('token'),
  isAuthenticated: !!localStorage.getItem('token'),
  user: null,
  
  login: async (email: string, password: string) => {
    try {
      const response = await axios.post('http://localhost:8000/api/auth/login', {
        username: email,
        password,
      });
      
      const { access_token } = response.data;
      localStorage.setItem('token', access_token);
      
      // 사용자 정보 가져오기
      const userResponse = await axios.get('http://localhost:8000/api/auth/me', {
        headers: { Authorization: `Bearer ${access_token}` }
      });
      
      set({
        token: access_token,
        isAuthenticated: true,
        user: userResponse.data,
      });
    } catch (error) {
      throw new Error('로그인에 실패했습니다');
    }
  },
  
  logout: () => {
    localStorage.removeItem('token');
    set({
      token: null,
      isAuthenticated: false,
      user: null,
    });
  },
})); 