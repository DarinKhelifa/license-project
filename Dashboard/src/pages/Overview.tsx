import React from 'react';
import Grid from '@mui/material/Grid'; // Regular Grid
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import {
  Security as SecurityIcon,
  People as PeopleIcon,
  LocalParking as ParkingIcon,
  WbSunny as WeatherIcon,
  FlashOn as FlashOnIcon,
  NotificationsActive as AlertIcon,
  Build as BuildIcon,
  CheckCircle as CheckCircleIcon,
} from '@mui/icons-material';
import { motion } from 'framer-motion';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

const stats = [
  { title: 'Active Residents', value: '128', icon: <PeopleIcon />, color: '#034808' },
  { title: 'Security Alerts', value: '3', icon: <SecurityIcon />, color: '#FFD700' },
  { title: 'Parking Available', value: '24', icon: <ParkingIcon />, color: '#034808' },
  { title: 'Temperature', value: '24°C', icon: <WeatherIcon />, color: '#FFD700' },
];

const energyData = [
  { time: '00:00', consumption: 240 },
  { time: '04:00', consumption: 180 },
  { time: '08:00', consumption: 320 },
  { time: '12:00', consumption: 410 },
  { time: '16:00', consumption: 380 },
  { time: '20:00', consumption: 290 },
];

const recentActivities = [
  { text: 'Gate access granted', details: 'Apartment 204 • 5 min ago', icon: <CheckCircleIcon sx={{ color: '#4caf50' }} /> },
  { text: 'Package delivered', details: 'Front desk • 10 min ago', icon: <CheckCircleIcon sx={{ color: '#4caf50' }} /> },
  { text: 'Security alarm triggered', details: 'Building B • 20 min ago', icon: <AlertIcon sx={{ color: '#f44336' }} /> },
  { text: 'Maintenance request', details: 'Apartment 110 • 30 min ago', icon: <BuildIcon sx={{ color: '#FFD700' }} /> },
];

export default function Overview() {
  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ color: '#034808', mb: 3 }}>
        Dashboard Overview
      </Typography>
      
      <Grid container spacing={3}>
        {/* Stats Cards */}
        {stats.map((stat, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: index * 0.1 }}
              whileHover={{ y: -5 }}
            >
              <Card sx={{ 
                borderRadius: 4, 
                border: '1px solid rgba(0,0,0,0.05)',
                boxShadow: '0 4px 20px rgba(0,0,0,0.03)',
                bgcolor: '#ffffff',
                transition: 'box-shadow 0.3s',
                '&:hover': {
                  boxShadow: '0 8px 30px rgba(3,72,8,0.1)',
                }
              }}>
                <CardContent sx={{ p: 3 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <Box>
                      <Typography color="textSecondary" sx={{ fontWeight: 600, fontSize: '0.85rem', textTransform: 'uppercase', letterSpacing: 1, mb: 1 }}>
                        {stat.title}
                      </Typography>
                      <Typography variant="h3" sx={{ color: '#034808', fontWeight: 800 }}>
                        {stat.value}
                      </Typography>
                    </Box>
                    <Box sx={{ 
                      background: `linear-gradient(135deg, ${stat.color}20 0%, transparent 100%)`,
                      borderRadius: '16px', 
                      p: 1.5,
                      color: stat.color,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}>
                      {React.cloneElement(stat.icon as React.ReactElement, { sx: { fontSize: 32 } })}
                    </Box>
                  </Box>
                </CardContent>
              </Card>
            </motion.div>
          </Grid>
        ))}

        {/* Energy Consumption Chart */}
        <Grid item xs={12} md={8}>
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.4 }}
            style={{ height: '100%' }}
          >
          <Card sx={{ 
            borderRadius: 4, 
            height: '100%',
            boxShadow: '0 4px 20px rgba(0,0,0,0.03)',
            border: '1px solid rgba(0,0,0,0.05)'
          }}>
            <CardContent sx={{ p: 3 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3, gap: 1 }}>
                <FlashOnIcon sx={{ color: '#FFD700' }} />
                <Typography variant="h6" sx={{ color: '#034808', fontWeight: 700 }}>
                  Energy Consumption (kWh)
                </Typography>
              </Box>
              <Box sx={{ height: 320 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={energyData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                    <defs>
                      <linearGradient id="colorEnergy" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#034808" stopOpacity={0.3}/>
                        <stop offset="95%" stopColor="#034808" stopOpacity={0}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#eee" />
                    <XAxis dataKey="time" axisLine={false} tickLine={false} tick={{ fill: '#888', fontSize: 12 }} dy={10} />
                    <YAxis axisLine={false} tickLine={false} tick={{ fill: '#888', fontSize: 12 }} />
                    <Tooltip 
                      contentStyle={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 20px rgba(0,0,0,0.1)' }}
                      cursor={{ stroke: '#034808', strokeWidth: 1, strokeDasharray: '4 4' }}
                    />
                    <Area 
                      type="monotone" 
                      dataKey="consumption" 
                      stroke="#034808" 
                      strokeWidth={3}
                      fillOpacity={1} 
                      fill="url(#colorEnergy)" 
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
          </motion.div>
        </Grid>

        {/* Recent Activity */}
        <Grid item xs={12} md={4}>
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5, delay: 0.5 }}
            style={{ height: '100%' }}
          >
          <Card sx={{ 
            borderRadius: 4, 
            height: '100%',
            boxShadow: '0 4px 20px rgba(0,0,0,0.03)',
            border: '1px solid rgba(0,0,0,0.05)'
          }}>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" sx={{ color: '#034808', fontWeight: 700, mb: 2 }}>
                Recent Activity
              </Typography>
              <Box sx={{ mt: 1, display: 'flex', flexDirection: 'column', gap: 2 }}>
                {recentActivities.map((act, idx) => (
                  <Box
                    key={idx}
                    sx={{
                      display: 'flex',
                      gap: 2,
                      p: 1.5,
                      borderRadius: 2,
                      transition: 'background-color 0.2s',
                      '&:hover': { bgcolor: 'rgba(0,0,0,0.02)' },
                    }}
                  >
                    <Box sx={{ mt: 0.5 }}>
                      {act.icon}
                    </Box>
                    <Box>
                      <Typography variant="body2" sx={{ fontWeight: 600, color: '#333' }}>
                        {act.text}
                      </Typography>
                      <Typography variant="caption" sx={{ color: '#888', fontWeight: 500 }}>
                        {act.details}
                      </Typography>
                    </Box>
                  </Box>
                ))}
              </Box>
            </CardContent>
          </Card>
          </motion.div>
        </Grid>
      </Grid>
    </Box>
  );
}