import React from 'react';
import Grid from '@mui/material/Grid';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import {
  Security as SecurityIcon,
  People as PeopleIcon,
  LocalParking as ParkingIcon,
  WbSunny as WeatherIcon,
} from '@mui/icons-material';
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

export default function Overview() {
  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ color: '#034808', mb: 3 }}>
        Dashboard Overview
      </Typography>
      
      <Grid container spacing={3}>
        {/* Stats Cards - REMOVED 'item' prop */}
        {stats.map((stat, index) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={index}> {/* Changed: xs={12} to size={{ xs: 12 }} */}
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Box>
                    <Typography color="textSecondary" gutterBottom variant="body2">
                      {stat.title}
                    </Typography>
                    <Typography variant="h4" component="div" sx={{ color: stat.color, fontWeight: 'bold' }}>
                      {stat.value}
                    </Typography>
                  </Box>
                  <Box sx={{ 
                    bgcolor: `${stat.color}20`, 
                    borderRadius: '50%', 
                    p: 1,
                    color: stat.color 
                  }}>
                    {stat.icon}
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}

        {/* Energy Consumption Chart  */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ color: '#034808' }}>
                Energy Consumption (kWh)
              </Typography>
              <Box sx={{ height: 300 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={energyData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="time" />
                    <YAxis />
                    <Tooltip />
                    <Area 
                      type="monotone" 
                      dataKey="consumption" 
                      stroke="#034808" 
                      fill="#034808" 
                      fillOpacity={0.3} 
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Recent Activity - REMOVED 'item' prop */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ color: '#034808' }}>
                Recent Activity
              </Typography>
              <Box sx={{ mt: 2 }}>
                {[1, 2, 3, 4].map((item) => (
                  <Box
                    key={item}
                    sx={{
                      py: 1.5,
                      borderBottom: '1px solid #eee',
                      '&:last-child': { borderBottom: 'none' },
                    }}
                  >
                    <Typography variant="body2" fontWeight={500}>
                      Gate access granted 
                    </Typography>
                    <Typography variant="caption" color="textSecondary">
                      Apartment 204 • 5 min ago
                    </Typography>
                  </Box>
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}