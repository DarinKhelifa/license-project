import React from 'react';
import { Box, Typography, Button, Container, Paper, Grid, Chip } from '@mui/material';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import {
  Security as SecurityIcon,
  People as PeopleIcon,
  Dashboard as DashboardIcon,
  Chat as ChatIcon,
  Verified as VerifiedIcon,
  Shield as ShieldIcon,
} from '@mui/icons-material';

const GREEN = '#034808';
const YELLOW = '#FFD700';

export default function LandingPage() {
  const navigate = useNavigate();

  return (
    <Box
      sx={{
        minHeight: '100vh',
        bgcolor: '#f5f5f5',
        overflow: 'hidden',
        position: 'relative',
      }}
    >
      {/* Ambient blobs */}
      <motion.div
        style={{
          position: 'absolute',
          width: 520,
          height: 520,
          left: -240,
          top: -260,
          background: 'rgba(3,72,8,0.28)',
          filter: 'blur(40px)',
          borderRadius: '999px',
          pointerEvents: 'none',
        }}
        animate={{ y: [0, 18, 0] }}
        transition={{ duration: 7, repeat: Infinity, ease: 'easeInOut' }}
      />
      <motion.div
        style={{
          position: 'absolute',
          width: 520,
          height: 520,
          right: -260,
          bottom: -280,
          background: 'rgba(255,215,0,0.22)',
          filter: 'blur(40px)',
          borderRadius: '999px',
          pointerEvents: 'none',
        }}
        animate={{ y: [0, -14, 0] }}
        transition={{ duration: 8, repeat: Infinity, ease: 'easeInOut' }}
      />

      <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 1, py: { xs: 5, md: 8 } }}>
        <Grid container spacing={4} alignItems="center">
          <Grid item xs={12} md={6}>
            <motion.div initial={{ opacity: 0, x: -40 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.6 }}>
              <Typography
                sx={{
                  fontSize: { xs: '2.2rem', md: '3.6rem' },
                  fontWeight: 950,
                  letterSpacing: 1,
                  color: YELLOW,
                  mb: 1.5,
                  lineHeight: 1,
                }}
              >
                ORELAX
              </Typography>

              <Typography
                sx={{
                  fontSize: { xs: '1.05rem', md: '1.35rem' },
                  fontWeight: 900,
                  color: 'white',
                  mb: 2.5,
                }}
              >
                SMART · SAFE · COMFORTABLE
              </Typography>

              <Paper
                elevation={0}
                sx={{
                  p: 3,
                  borderRadius: 4,
                  bgcolor: GREEN,
                  color: 'white',
                  border: '1px solid rgba(255,215,0,0.28)',
                  backdropFilter: 'blur(10px)',
                }}
              >
                <Typography sx={{ color: 'rgba(255,255,255,0.95)', lineHeight: 1.8 }}>
                  A secure gated community experience with incident reporting, chat, and resident services—built for real life.
                </Typography>

                <Box sx={{ mt: 3, display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                  <motion.div whileHover={{ scale: 1.03 }}>
                    <Button
                      variant="contained"
                      size="large"
                      onClick={() => navigate('/login')}
                      sx={{
                        bgcolor: YELLOW,
                        color: GREEN,
                        px: 4,
                        py: 1.7,
                        fontWeight: 950,
                        '&:hover': { bgcolor: '#FFC107' },
                      }}
                    >
                      Login
                    </Button>
                  </motion.div>
                  <motion.div whileHover={{ scale: 1.03 }}>
                    <Button
                      variant="outlined"
                      size="large"
                      onClick={() => navigate('/register')}
                      sx={{
                        borderColor: YELLOW,
                        color: YELLOW,
                        px: 4,
                        py: 1.7,
                        fontWeight: 950,
                        '&:hover': { borderColor: '#FFC107', bgcolor: 'rgba(255,215,0,0.08)' },
                      }}
                    >
                      Sign Up
                    </Button>
                  </motion.div>
                </Box>

                <Box sx={{ mt: 3, display: 'flex', gap: 1.2, flexWrap: 'wrap' }}>
                  <Chip icon={<ShieldIcon />} label="Secure access" sx={{ bgcolor: 'rgba(255,255,255,0.1)', color: 'white' }} />
                  <Chip icon={<VerifiedIcon />} label="Verified staff" sx={{ bgcolor: 'rgba(255,255,255,0.1)', color: 'white' }} />
                  <Chip icon={<ChatIcon />} label="Resident chat" sx={{ bgcolor: 'rgba(255,255,255,0.1)', color: 'white' }} />
                </Box>
              </Paper>
            </motion.div>
          </Grid>

          <Grid item xs={12} md={6}>
            <motion.div
              initial={{ opacity: 0, scale: 0.96 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.6, delay: 0.1 }}
            >
              <Paper
                elevation={10}
                sx={{
                  p: 4,
                  borderRadius: 5,
                  border: '1px solid rgba(255,215,0,0.25)',
                  bgcolor: 'rgba(255,255,255,0.75)',
                  backdropFilter: 'blur(10px)',
                }}
              >
                <Typography sx={{ color: GREEN, fontWeight: 950, letterSpacing: 0.8, mb: 1.5 }}>
                  ALL IN ONE
                </Typography>
                <Typography sx={{ color: GREEN, fontWeight: 1000, fontSize: '2.2rem', mb: 2 }}>
                  REAL RESIDENCE
                </Typography>

                <Grid container spacing={2} sx={{ mb: 2 }}>
                  <Grid item xs={4}>
                    <Box
                      sx={{
                        borderRadius: 3,
                        border: '1px solid rgba(3,72,8,0.12)',
                        bgcolor: 'rgba(3,72,8,0.04)',
                        p: 2,
                        textAlign: 'center',
                      }}
                    >
                      <SecurityIcon sx={{ color: GREEN, fontSize: 30 }} />
                      <Typography sx={{ color: GREEN, mt: 1, fontWeight: 800, fontSize: 13 }}>Security</Typography>
                    </Box>
                  </Grid>
                  <Grid item xs={4}>
                    <Box
                      sx={{
                        borderRadius: 3,
                        border: '1px solid rgba(3,72,8,0.12)',
                        bgcolor: 'rgba(255,215,0,0.15)',
                        p: 2,
                        textAlign: 'center',
                      }}
                    >
                      <PeopleIcon sx={{ color: GREEN, fontSize: 30 }} />
                      <Typography sx={{ color: GREEN, mt: 1, fontWeight: 800, fontSize: 13 }}>Residents</Typography>
                    </Box>
                  </Grid>
                  <Grid item xs={4}>
                    <Box
                      sx={{
                        borderRadius: 3,
                        border: '1px solid rgba(3,72,8,0.12)',
                        bgcolor: 'rgba(3,72,8,0.04)',
                        p: 2,
                        textAlign: 'center',
                      }}
                    >
                      <DashboardIcon sx={{ color: GREEN, fontSize: 30 }} />
                      <Typography sx={{ color: GREEN, mt: 1, fontWeight: 800, fontSize: 13 }}>Dashboard</Typography>
                    </Box>
                  </Grid>
                </Grid>

                <Typography sx={{ color: 'text.secondary', lineHeight: 1.7 }}>
                  Designed for admins and residents to manage incidents, communicate, and access community services—fast and organized.
                </Typography>
              </Paper>
            </motion.div>
          </Grid>
        </Grid>

        <Box sx={{ mt: { xs: 4, md: 6 }, textAlign: 'center', color: 'text.secondary' }}>
          <Typography variant="body2">Secure gated access. Modern experience. Powered by Firebase.</Typography>
        </Box>
      </Container>
    </Box>
  );
}

