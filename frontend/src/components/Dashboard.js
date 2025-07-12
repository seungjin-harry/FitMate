import React, { useState, useEffect } from 'react';
import './Dashboard.css';

function Dashboard({ user }) {
  const [dateRange, setDateRange] = useState({
    startDate: new Date(new Date().setMonth(new Date().getMonth() - 1)).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0],
  });
  
  const [stats, setStats] = useState({
    totalContent: 0,
    socialMediaStats: {
      facebook: { uploaded: 0, failed: 0 },
      instagram: { uploaded: 0, failed: 0 },
      youtube: { uploaded: 0, failed: 0 },
    },
    failedContent: [],
    githubContent: [],
  });

  const [error, setError] = useState(null);

  useEffect(() => {
    fetchDashboardData();
  }, [dateRange]);

  const fetchDashboardData = async () => {
    try {
      const response = await fetch(
        `http://localhost:8000/api/dashboard/stats?startDate=${dateRange.startDate}&endDate=${dateRange.endDate}`,
        {
          headers: {
            'Authorization': `Bearer ${user.token}`
          }
        }
      );
      
      if (response.ok) {
        const data = await response.json();
        setStats(data);
        setError(null);
      } else {
        throw new Error('Failed to fetch dashboard data');
      }
    } catch (error) {
      console.error('Failed to fetch dashboard data:', error);
      setError('데이터를 불러오는데 실패했습니다.');
    }
  };

  if (error) {
    return <div className="error-message">{error}</div>;
  }

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <h1>컨텐츠 대시보드</h1>
        <div className="date-range">
          <input
            type="date"
            value={dateRange.startDate}
            onChange={(e) => setDateRange(prev => ({ ...prev, startDate: e.target.value }))}
          />
          <span>~</span>
          <input
            type="date"
            value={dateRange.endDate}
            onChange={(e) => setDateRange(prev => ({ ...prev, endDate: e.target.value }))}
          />
        </div>
      </header>

      <div className="stats-grid">
        <div className="stat-card total">
          <h3>총 컨텐츠</h3>
          <p className="stat-number">{stats.totalContent}</p>
        </div>

        <div className="stat-card social">
          <h3>소셜 미디어 현황</h3>
          <div className="social-stats">
            {Object.entries(stats.socialMediaStats).map(([platform, data]) => (
              <div key={platform} className="platform-stat">
                <h4>{platform}</h4>
                <p>업로드: {data.uploaded}</p>
                <p>실패: {data.failed}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="stat-card failed">
          <h3>실패한 컨텐츠</h3>
          <div className="failed-list">
            {stats.failedContent.map((content, index) => (
              <div key={index} className="failed-item">
                <p>{content.title}</p>
                <p className="error-reason">{content.reason}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="stat-card github">
          <h3>GitHub 컨텐츠</h3>
          <div className="github-list">
            {stats.githubContent.map((content, index) => (
              <div key={index} className="github-item">
                <p>{content.name}</p>
                <a href={content.url} target="_blank" rel="noopener noreferrer">
                  보기
                </a>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

export default Dashboard; 