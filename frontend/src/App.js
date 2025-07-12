import React, { useState } from 'react';
import './App.css';
import LoginPage from './components/LoginPage';
import Dashboard from './components/Dashboard';

function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [user, setUser] = useState(null);

  const handleLogin = async (credentials) => {
    try {
      const formData = new URLSearchParams();
      formData.append('username', credentials.username);
      formData.append('password', credentials.password);

      const response = await fetch('http://localhost:8000/token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData
      });

      if (response.ok) {
        const data = await response.json();
        setUser({ username: credentials.username, token: data.access_token });
        setIsLoggedIn(true);
      } else {
        throw new Error('Login failed');
      }
    } catch (error) {
      alert('로그인에 실패했습니다.');
      console.error('Login error:', error);
    }
  };

  return (
    <div className="App">
      {!isLoggedIn ? (
        <LoginPage onLogin={handleLogin} />
      ) : (
        <Dashboard user={user} />
      )}
    </div>
  );
}

export default App; 