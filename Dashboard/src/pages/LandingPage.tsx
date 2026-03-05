import React from 'react';
import { Box, Typography, Button, Container, Paper, Grid } from '@mui/material'; 
import { useNavigate } from 'react-router-dom';
import {
  Security as SecurityIcon,
  People as PeopleIcon,
  Dashboard as DashboardIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
} from '@mui/icons-material';
import GradualBlur from '../components/GradualBlur';

export default function LandingPage() {
  const navigate = useNavigate();

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: '#f5f5f5' }}>
      {/* Hero Section with Gradual Blur */}
      <Box sx={{ 
        bgcolor: '#034808', 
        color: 'white', 
        py: 8,
        position: 'relative',
        overflow: 'hidden'
      }}>
        {/* Gradual Blur Overlay */}
        <GradualBlur
          position="bottom"
          height="10rem"
          strength={3}
          divCount={8}
          curve="bezier"
          exponential={true}
          opacity={0.7}
          zIndex={5}
        />
        
        <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 10 }}>
          <Grid container spacing={4} alignItems="center">
            <Grid item xs={12} md={6}> {/* Changed: size={{ xs:12, md:6 }} → item xs={12} md={6} */}
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
            <Grid item xs={12} md={6}> {/* Changed: size={{ xs:12, md:6 }} → item xs={12} md={6} */}
              <Box
                sx={{
                  bgcolor: 'rgba(255,255,255,0.1)',
                  backdropFilter: 'blur(10px)',
                  borderRadius: 4,
                  p: 4,
                  textAlign: 'center',
                  border: '1px solid rgba(255,215,0,0.3)',
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
      <Box sx={{ position: 'relative', py: 8 }}>
        <Container maxWidth="lg">
          <Typography variant="h3" sx={{ textAlign: 'center', color: '#034808', mb: 6 }}>
            Why Choose ORELAX?
          </Typography>
          <Grid container spacing={4}>
            <Grid item xs={12} md={4}> {/* Changed: size → item */}
              <Paper sx={{ 
                p: 4, 
                textAlign: 'center', 
                height: '100%',
                transition: 'transform 0.3s',
                '&:hover': {
                  transform: 'translateY(-5px)',
                  boxShadow: '0 8px 16px rgba(3,72,8,0.2)'
                }
              }}>
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
            <Grid item xs={12} md={4}> {/* Changed: size → item */}
              <Paper sx={{ 
                p: 4, 
                textAlign: 'center', 
                height: '100%',
                transition: 'transform 0.3s',
                '&:hover': {
                  transform: 'translateY(-5px)',
                  boxShadow: '0 8px 16px rgba(3,72,8,0.2)'
                }
              }}>
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
            <Grid item xs={12} md={4}> {/* Changed: size → item */}
              <Paper sx={{ 
                p: 4, 
                textAlign: 'center', 
                height: '100%',
                transition: 'transform 0.3s',
                '&:hover': {
                  transform: 'translateY(-5px)',
                  boxShadow: '0 8px 16px rgba(3,72,8,0.2)'
                }
              }}>
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
      </Box>

      {/* Contact Section */}
      <Box sx={{ 
        bgcolor: '#034808', 
        color: 'white', 
        py: 6,
        position: 'relative',
        overflow: 'hidden'
      }}>
        <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 10 }}>
          <Grid container spacing={4} justifyContent="center">
            <Grid item xs={12} md={6} textAlign="center"> {/* Changed: size → item */}
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