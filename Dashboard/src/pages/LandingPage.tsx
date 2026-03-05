import React from 'react';
import { Box, Typography, Button, Container, Paper } from '@mui/material';
import Grid from '@mui/material/Grid'; // Import Grid2
import { useNavigate } from 'react-router-dom';
import {
  Security as SecurityIcon,
  People as PeopleIcon,
  Dashboard as DashboardIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
} from '@mui/icons-material';

export default function LandingPage() {
  const navigate = useNavigate();

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: '#f5f5f5' }}>
      {/* Hero Section */}
      <Box sx={{ bgcolor: '#034808', color: 'white', py: 8 }}>
        <Container maxWidth="lg">
          <Grid container spacing={4} alignItems="center">
            <Grid size={{ xs: 12, md: 6 }}> {/* Fixed: using size prop */}
              <Typography variant="h2" sx={{ fontWeight: 'bold', mb: 2, color: '#FFD700' }}>
                ORELAX
              </Typography>
              <Typography variant="h5" sx={{ mb: 3, color: 'white' }}>
                SMART · SAFE · COMFORTABLE
              </Typography>
              <Typography variant="body1" sx={{ mb: 4, color: 'rgba(255,255,255,0.9)' }}>
                Your connected home where responsive security meets neighbourhood harmony 
                and technological ease. Stay Connected.
              </Typography>
              <Box sx={{ display: 'flex', gap: 2 }}>
                <Button
                  variant="contained"
                  size="large"
                  onClick={() => navigate('/login')}
                  sx={{
                    bgcolor: '#FFD700',
                    color: '#034808',
                    '&:hover': { bgcolor: '#FFC107' },
                    px: 4,
                    py: 1.5,
                  }}
                >
                  Login
                </Button>
                <Button
                  variant="outlined"
                  size="large"
                  onClick={() => navigate('/register')}
                  sx={{
                    borderColor: '#FFD700',
                    color: '#FFD700',
                    '&:hover': { borderColor: '#FFC107', bgcolor: 'rgba(255,215,0,0.1)' },
                    px: 4,
                    py: 1.5,
                  }}
                >
                  Sign Up
                </Button>
              </Box>
            </Grid>
            <Grid size={{ xs: 12, md: 6 }}> {/* Fixed: using size prop */}
              <Box
                sx={{
                  bgcolor: 'rgba(255,255,255,0.1)',
                  borderRadius: 4,
                  p: 4,
                  textAlign: 'center',
                }}
              >
                <Typography variant="h4" sx={{ color: '#FFD700', mb: 2 }}>
                  ALL IN ONE
                </Typography>
                <Typography variant="h3" sx={{ color: 'white', mb: 3 }}>
                  REAL RESIDENCE
                </Typography>
                <Box sx={{ display: 'flex', justifyContent: 'center', gap: 4 }}>
                  <SecurityIcon sx={{ fontSize: 50, color: '#FFD700' }} />
                  <PeopleIcon sx={{ fontSize: 50, color: '#FFD700' }} />
                  <DashboardIcon sx={{ fontSize: 50, color: '#FFD700' }} />
                </Box>
              </Box>
            </Grid>
          </Grid>
        </Container>
      </Box>

      {/* Features Section */}
      <Container maxWidth="lg" sx={{ py: 8 }}>
        <Typography variant="h3" sx={{ textAlign: 'center', color: '#034808', mb: 6 }}>
          Why Choose ORELAX?
        </Typography>
        <Grid container spacing={4}>
          <Grid size={{ xs: 12, md: 4 }}> {/* Fixed: using size prop */}
            <Paper sx={{ p: 4, textAlign: 'center', height: '100%' }}>
              <SecurityIcon sx={{ fontSize: 60, color: '#034808', mb: 2 }} />
              <Typography variant="h5" sx={{ color: '#034808', mb: 2 }}>
                Smart Security
              </Typography>
              <Typography color="textSecondary">
                Automated access management, real-time alerts, and 24/7 surveillance 
                for complete peace of mind.
              </Typography>
            </Paper>
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}> {/* Fixed: using size prop */}
            <Paper sx={{ p: 4, textAlign: 'center', height: '100%' }}>
              <PeopleIcon sx={{ fontSize: 60, color: '#034808', mb: 2 }} />
              <Typography variant="h5" sx={{ color: '#034808', mb: 2 }}>
                Community Living
              </Typography>
              <Typography color="textSecondary">
                Connect with neighbors, organize events, and book shared spaces 
                through our community platform.
              </Typography>
            </Paper>
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}> {/* Fixed: using size prop */}
            <Paper sx={{ p: 4, textAlign: 'center', height: '100%' }}>
              <DashboardIcon sx={{ fontSize: 60, color: '#034808', mb: 2 }} />
              <Typography variant="h5" sx={{ color: '#034808', mb: 2 }}>
                Smart Management
              </Typography>
              <Typography color="textSecondary">
                Monitor energy consumption, control facilities, and manage 
                maintenance requests effortlessly.
              </Typography>
            </Paper>
          </Grid>
        </Grid>
      </Container>

      {/* Contact Section */}
      <Box sx={{ bgcolor: '#034808', color: 'white', py: 6 }}>
        <Container maxWidth="lg">
          <Grid container spacing={4} justifyContent="center">
            <Grid size={{ xs: 12, md: 6 }} textAlign="center"> {/* Fixed: using size prop */}
              <Typography variant="h4" sx={{ color: '#FFD700', mb: 3 }}>
                Stay Connected
              </Typography>
              <Box sx={{ display: 'flex', justifyContent: 'center', gap: 4, flexWrap: 'wrap' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <PhoneIcon sx={{ color: '#FFD700' }} />
                  <Typography>+213 (0) 123 456 789</Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <EmailIcon sx={{ color: '#FFD700' }} />
                  <Typography>contact@orelay.dz</Typography>
                </Box>
              </Box>
            </Grid>
          </Grid>
        </Container>
      </Box>
    </Box>
  );
}