import React from 'react';
import { Box, Typography, Button, Container, Paper } from '@mui/material';
import Grid from '@mui/material/Grid';
import { useNavigate } from 'react-router-dom';
import {
  Security as SecurityIcon,
  People as PeopleIcon,
  Dashboard as DashboardIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
} from '@mui/icons-material';
import GradualBlur from '../components/GradualBlur/GradualBlur';

export default function LandingPage() {
  const navigate = useNavigate();

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: '#f5f5f5' }}>
      {/* Hero Section with Gradual Blur */}
      <Box sx={{ 
        bgcolor: '#034808', 
        color: 'white', 
        py: { xs: 4, md: 8 },
        position: 'relative',
        minHeight: { xs: 400, md: 500 },
        overflow: 'hidden'
      }}>
        {/* Bottom Blur - creates smooth fade to next section */}
        <GradualBlur
          position="bottom"
          height="10rem"
          strength={5}
          divCount={12}
          curve="ease-out"
          exponential={true}
          opacity={0.95}
          zIndex={5}
        />
        
        {/* Top Blur - adds depth to hero section */}
        <GradualBlur
          position="top"
          height="5rem"
          strength={2}
          divCount={6}
          curve="linear"
          opacity={0.6}
          zIndex={5}
        />
        
        <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 10 }}>
          <Grid container spacing={4} alignItems="center">
            {/* Left Column - Text Content */}
            <Grid item xs={12} md={6}>
              <Typography 
                variant="h2" 
                sx={{ 
                  fontWeight: 'bold', 
                  mb: 2, 
                  color: '#FFD700',
                  fontSize: { xs: '2.5rem', md: '3.75rem' }
                }}
              >
                ORELAX
              </Typography>
              <Typography 
                variant="h5" 
                sx={{ 
                  mb: 3, 
                  color: 'white',
                  fontSize: { xs: '1.25rem', md: '1.5rem' }
                }}
              >
                SMART · SAFE · COMFORTABLE
              </Typography>
              <Typography 
                variant="body1" 
                sx={{ 
                  mb: 4, 
                  color: 'rgba(255,255,255,0.9)',
                  fontSize: { xs: '1rem', md: '1.1rem' },
                  lineHeight: 1.6
                }}
              >
                Your connected home where responsive security meets neighbourhood harmony 
                and technological ease. Stay Connected.
              </Typography>
              <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
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
                    fontSize: '1.1rem',
                    fontWeight: 'bold'
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
                    '&:hover': { 
                      borderColor: '#FFC107', 
                      bgcolor: 'rgba(255,215,0,0.1)' 
                    },
                    px: 4,
                    py: 1.5,
                    fontSize: '1.1rem',
                    fontWeight: 'bold'
                  }}
                >
                  Sign Up
                </Button>
              </Box>
            </Grid>

            {/* Right Column - ALL IN ONE Card */}
            <Grid item xs={12} md={6}>
              <Paper
                elevation={6}
                sx={{
                  bgcolor: 'rgba(255,255,255,0.1)',
                  backdropFilter: 'blur(10px)',
                  borderRadius: 4,
                  p: { xs: 3, md: 4 },
                  textAlign: 'center',
                  border: '2px solid rgba(255,215,0,0.3)',
                  transition: 'transform 0.3s',
                  '&:hover': {
                    transform: 'scale(1.02)',
                    borderColor: '#FFD700'
                  }
                }}
              >
                <Typography 
                  variant="h4" 
                  sx={{ 
                    color: '#FFD700', 
                    mb: 2,
                    fontWeight: 'medium'
                  }}
                >
                  ALL IN ONE
                </Typography>
                <Typography 
                  variant="h3" 
                  sx={{ 
                    color: 'white', 
                    mb: 3,
                    fontWeight: 'bold',
                    fontSize: { xs: '2rem', md: '2.5rem' }
                  }}
                >
                  REAL RESIDENCE
                </Typography>
                <Box sx={{ display: 'flex', justifyContent: 'center', gap: 4 }}>
                  <SecurityIcon sx={{ fontSize: { xs: 40, md: 50 }, color: '#FFD700' }} />
                  <PeopleIcon sx={{ fontSize: { xs: 40, md: 50 }, color: '#FFD700' }} />
                  <DashboardIcon sx={{ fontSize: { xs: 40, md: 50 }, color: '#FFD700' }} />
                </Box>
              </Paper>
            </Grid>
          </Grid>
        </Container>
      </Box>

      {/* Features Section with Blur */}
      <Box sx={{ 
        position: 'relative', 
        py: { xs: 6, md: 8 },
        minHeight: 400,
        overflow: 'hidden',
        bgcolor: '#f5f5f5'
      }}>
        {/* Top Blur for features section */}
        <GradualBlur
          position="top"
          height="8rem"
          strength={4}
          divCount={10}
          curve="ease-in"
          exponential={true}
          opacity={0.8}
          zIndex={5}
        />
        
        <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 10 }}>
          <Typography 
            variant="h3" 
            sx={{ 
              textAlign: 'center', 
              color: '#034808', 
              mb: 6,
              fontWeight: 'bold',
              fontSize: { xs: '2rem', md: '2.5rem' }
            }}
          >
            Why Choose ORELAX?
          </Typography>
          
          <Grid container spacing={4}>
            {/* Feature 1 */}
            <Grid item xs={12} md={4}>
              <Paper sx={{ 
                p: { xs: 3, md: 4 }, 
                textAlign: 'center', 
                height: '100%',
                transition: 'transform 0.3s, box-shadow 0.3s',
                '&:hover': {
                  transform: 'translateY(-8px)',
                  boxShadow: '0 12px 20px rgba(3,72,8,0.3)'
                }
              }}>
                <SecurityIcon sx={{ fontSize: 70, color: '#034808', mb: 2 }} />
                <Typography variant="h5" sx={{ color: '#034808', mb: 2, fontWeight: 'bold' }}>
                  Smart Security
                </Typography>
                <Typography color="textSecondary" sx={{ lineHeight: 1.7 }}>
                  Automated access management, real-time alerts, and 24/7 surveillance 
                  for complete peace of mind.
                </Typography>
              </Paper>
            </Grid>

            {/* Feature 2 */}
            <Grid item xs={12} md={4}>
              <Paper sx={{ 
                p: { xs: 3, md: 4 }, 
                textAlign: 'center', 
                height: '100%',
                transition: 'transform 0.3s, box-shadow 0.3s',
                '&:hover': {
                  transform: 'translateY(-8px)',
                  boxShadow: '0 12px 20px rgba(3,72,8,0.3)'
                }
              }}>
                <PeopleIcon sx={{ fontSize: 70, color: '#034808', mb: 2 }} />
                <Typography variant="h5" sx={{ color: '#034808', mb: 2, fontWeight: 'bold' }}>
                  Community Living
                </Typography>
                <Typography color="textSecondary" sx={{ lineHeight: 1.7 }}>
                  Connect with neighbors, organize events, and book shared spaces 
                  through our community platform.
                </Typography>
              </Paper>
            </Grid>

            {/* Feature 3 */}
            <Grid item xs={12} md={4}>
              <Paper sx={{ 
                p: { xs: 3, md: 4 }, 
                textAlign: 'center', 
                height: '100%',
                transition: 'transform 0.3s, box-shadow 0.3s',
                '&:hover': {
                  transform: 'translateY(-8px)',
                  boxShadow: '0 12px 20px rgba(3,72,8,0.3)'
                }
              }}>
                <DashboardIcon sx={{ fontSize: 70, color: '#034808', mb: 2 }} />
                <Typography variant="h5" sx={{ color: '#034808', mb: 2, fontWeight: 'bold' }}>
                  Smart Management
                </Typography>
                <Typography color="textSecondary" sx={{ lineHeight: 1.7 }}>
                  Monitor energy consumption, control facilities, and manage 
                  maintenance requests effortlessly.
                </Typography>
              </Paper>
            </Grid>
          </Grid>
        </Container>
      </Box>

      {/* Contact Section with Blur */}
      <Box sx={{ 
        bgcolor: '#034808', 
        color: 'white', 
        py: { xs: 4, md: 6 },
        position: 'relative',
        overflow: 'hidden',
        minHeight: 200
      }}>
        {/* Bottom Blur for smooth transition */}
        <GradualBlur
          position="top"
          height="5rem"
          strength={3}
          divCount={8}
          curve="linear"
          opacity={0.6}
          zIndex={5}
        />
        
        <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 10 }}>
          <Grid container spacing={4} justifyContent="center">
            <Grid item xs={12} md={6} textAlign="center">
              <Typography 
                variant="h4" 
                sx={{ 
                  color: '#FFD700', 
                  mb: 3,
                  fontWeight: 'bold',
                  fontSize: { xs: '1.75rem', md: '2.25rem' }
                }}
              >
                Stay Connected
              </Typography>
              <Box sx={{ 
                display: 'flex', 
                justifyContent: 'center', 
                gap: { xs: 2, md: 4 }, 
                flexWrap: 'wrap' 
              }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <PhoneIcon sx={{ color: '#FFD700', fontSize: 28 }} />
                  <Typography sx={{ fontSize: '1.1rem' }}>+213 (0) 123 456 789</Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <EmailIcon sx={{ color: '#FFD700', fontSize: 28 }} />
                  <Typography sx={{ fontSize: '1.1rem' }}>contact@orelax.dz</Typography>
                </Box>
              </Box>
            </Grid>
          </Grid>
        </Container>
      </Box>
    </Box>
  );
}