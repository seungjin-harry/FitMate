import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  TextField,
  MenuItem,
  CircularProgress,
} from '@mui/material';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import axios from 'axios';
import { useAuthStore } from '../stores/authStore';
import { format } from 'date-fns';
import { ko } from 'date-fns/locale';

interface DailyStats {
  date: string;
  total: number;
  uploaded: number;
}

const Analytics: React.FC = () => {
  const [startDate, setStartDate] = useState<Date | null>(
    new Date(new Date().setDate(new Date().getDate() - 30))
  );
  const [endDate, setEndDate] = useState<Date | null>(new Date());
  const [contentType, setContentType] = useState('DAILY');
  const [loading, setLoading] = useState(true);
  const [dailyStats, setDailyStats] = useState<DailyStats[]>([]);
  const { token } = useAuthStore();

  const contentTypes = [
    { value: 'DAILY', label: '감성적 일상 나눔' },
    { value: 'ARTISTIC', label: '예술적 취향 나눔' },
    { value: 'PHILOSOPHY', label: '인용 및 철학' },
    { value: 'WORK', label: '작품 소개' },
    { value: 'INTERVIEW', label: '감성 인터뷰' },
  ];

  useEffect(() => {
    fetchAnalytics();
  }, [token, startDate, endDate, contentType]);

  const fetchAnalytics = async () => {
    if (!startDate || !endDate) return;

    try {
      setLoading(true);
      const response = await axios.get(
        'http://localhost:8000/api/analytics/daily',
        {
          headers: { Authorization: `Bearer ${token}` },
          params: {
            start_date: startDate.toISOString(),
            end_date: endDate.toISOString(),
            content_type: contentType,
          },
        }
      );

      const formattedData = response.data.map((stat: any) => ({
        ...stat,
        date: format(new Date(stat.date), 'MM/dd'),
      }));

      setDailyStats(formattedData);
    } catch (error) {
      console.error('분석 데이터 로딩 실패:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        컨텐츠 분석
      </Typography>

      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={4}>
              <LocalizationProvider
                dateAdapter={AdapterDateFns}
                adapterLocale={ko}
              >
                <DatePicker
                  label="시작일"
                  value={startDate}
                  onChange={(newValue) => setStartDate(newValue)}
                />
              </LocalizationProvider>
            </Grid>
            <Grid item xs={12} md={4}>
              <LocalizationProvider
                dateAdapter={AdapterDateFns}
                adapterLocale={ko}
              >
                <DatePicker
                  label="종료일"
                  value={endDate}
                  onChange={(newValue) => setEndDate(newValue)}
                />
              </LocalizationProvider>
            </Grid>
            <Grid item xs={12} md={4}>
              <TextField
                select
                fullWidth
                label="컨텐츠 타입"
                value={contentType}
                onChange={(e) => setContentType(e.target.value)}
              >
                {contentTypes.map((option) => (
                  <MenuItem key={option.value} value={option.value}>
                    {option.label}
                  </MenuItem>
                ))}
              </TextField>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
          <CircularProgress />
        </Box>
      ) : (
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  일별 컨텐츠 통계
                </Typography>
                <Box sx={{ height: 400 }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={dailyStats}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="date" />
                      <YAxis />
                      <Tooltip />
                      <Legend />
                      <Line
                        type="monotone"
                        dataKey="total"
                        name="전체"
                        stroke="#8884d8"
                      />
                      <Line
                        type="monotone"
                        dataKey="uploaded"
                        name="업로드됨"
                        stroke="#82ca9d"
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}
    </Box>
  );
};

export default Analytics; 