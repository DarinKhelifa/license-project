import React, { useState } from 'react';
import { Box, TextField, Button, Typography, Alert, Paper, Grid, CircularProgress, Container } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Login as LoginIcon, Security as SecurityIcon, Verified as VerifiedIcon } from '@mui/icons-material';
import { useAuth } from '../context/AuthContext';

const GREEN = '#034808';
const YELLOW = '#FFD700';

export default function Login() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const { signIn } = useAuth();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!email || !password) {
      setError('Please fill in all fields');
      return;
    }

    setLoading(true);
    try {
      await signIn(email, password);
      navigate('/dashboard');
    } catch (err: any) {
      setError(err?.message ?? 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: '#f5f5f5', overflow: 'hidden' }}>
      <Box sx={{ position: 'absolute', inset: 0, background: 'radial-gradient(1200px 500px at 20% 10%, rgba(3,72,8,0.25), transparent 55%), radial-gradient(900px 420px at 90% 80%, rgba(255,215,0,0.22), transparent 55%)', pointerEvents: 'none' }} />

      <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 1, py: { xs: 4, md: 7 } }}>
        <Grid container spacing={3} alignItems="stretch">
          <Grid item xs={12} md={5}>
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
              <Paper elevation={0} sx={{ height: '100%', p: 4, borderRadius: 4, bgcolor: GREEN, color: 'white', border: '1px solid rgba(255,215,0,0.25)', overflow: 'hidden', position: 'relative' }}>
                <Typography sx={{ fontWeight: 950, fontSize: 40, color: YELLOW, mb: 1.2 }}>ORELAX</Typography>
                <Typography sx={{ fontWeight: 900, mb: 2.5 }}>SMART · SAFE · COMFORTABLE</Typography>
                <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap', mb: 3 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <SecurityIcon sx={{ color: YELLOW }} />
                    <Typography sx={{ fontWeight: 700 }}>Secure access</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <VerifiedIcon sx={{ color: YELLOW }} />
                    <Typography sx={{ fontWeight: 700 }}>Verified services</Typography>
                  </Box>
                </Box>
                <Typography sx={{ color: 'rgba(255,255,255,0.9)', lineHeight: 1.8 }}>
                  Sign in to manage incidents, chat with your community, and access services.
                </Typography>
              </Paper>
            </motion.div>
          </Grid>

          <Grid item xs={12} md={7}>
            <motion.div initial={{ opacity: 0, x: 30 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.55, delay: 0.05 }}>
              <Paper sx={{ p: { xs: 3, md: 4 }, borderRadius: 4, border: '1px solid rgba(3,72,8,0.10)', boxShadow: 3 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                  <LoginIcon sx={{ color: GREEN }} />
                  <Typography sx={{ fontWeight: 900, fontSize: 24, color: GREEN }}>Welcome back</Typography>
                </Box>

                {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

                <Box component="form" onSubmit={handleLogin}>
                  <TextField fullWidth label="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} margin="normal" required />
                  <TextField fullWidth label="Password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} margin="normal" required />

                  <Button type="submit" fullWidth variant="contained" sx={{ mt: 3, bgcolor: GREEN, py: 1.6, fontWeight: 950, '&:hover': { bgcolor: '#023206' } }} disabled={loading}>
                    {loading ? <CircularProgress size={20} sx={{ color: 'white' }} /> : 'LOGIN'}
                  </Button>
                </Box>

              </Paper>
            </motion.div>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
}