import { useState, ChangeEvent, FormEvent } from 'react';
import { Box, Paper, TextField, Button, Typography, Link, Alert, Container, Grid, CircularProgress } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Google as GoogleIcon, Person as PersonIcon, Verified as VerifiedIcon, Security as SecurityIcon } from '@mui/icons-material';
import { useAuth } from '../context/AuthContext';

const GREEN = '#034808';
const YELLOW = '#FFD700';

export default function Register() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    apartment: '',
    password: '',
    confirmPassword: '',
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const { signUp, signInWithGoogle } = useAuth();

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleRegister = async (e: FormEvent) => {
    e.preventDefault();
    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    setLoading(true);
    setError('');

    try {
      await signUp(formData.email, formData.password, {
        name: formData.name,
        email: formData.email,
        phone: formData.phone,
        apartment: formData.apartment,
        role: 'resident',
        status: 'pending',
      });
      localStorage.setItem('isAuthenticated', 'true');
      navigate('/dashboard');
    } catch (err: any) {
      setError(err?.message ?? 'Sign up failed');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleRegister = async () => {
    setError('');
    setLoading(true);
    try {
      await signInWithGoogle();
      localStorage.setItem('isAuthenticated', 'true');
      navigate('/dashboard');
    } catch (err: any) {
      setError(err?.message ?? 'Google sign-up failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: '#f5f5f5', overflow: 'hidden', position: 'relative' }}>
      {/* Ambient glow */}
      <Box
        sx={{
          position: 'absolute',
          inset: 0,
          background:
            'radial-gradient(1200px 500px at 15% 10%, rgba(3,72,8,0.25), transparent 55%), radial-gradient(900px 420px at 90% 80%, rgba(255,215,0,0.22), transparent 55%)',
          pointerEvents: 'none',
        }}
      />

      <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 1, py: { xs: 4, md: 7 } }}>
        <Grid container spacing={3} alignItems="stretch">
          <Grid item xs={12} md={5}>
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
              <Paper
                elevation={0}
                sx={{
                  height: '100%',
                  p: 4,
                  borderRadius: 4,
                  bgcolor: GREEN,
                  color: 'white',
                  border: '1px solid rgba(255,215,0,0.25)',
                }}
              >
                <Typography sx={{ fontWeight: 950, fontSize: 40, color: YELLOW, mb: 1.2 }}>
                  ORELAX
                </Typography>
                <Typography sx={{ fontWeight: 900, mb: 2.5 }}>Create your resident profile</Typography>

                <Box sx={{ display: 'flex', gap: 1.5, flexWrap: 'wrap', mb: 2 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <SecurityIcon sx={{ color: YELLOW }} />
                    <Typography sx={{ fontWeight: 700 }}>Secure</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <VerifiedIcon sx={{ color: YELLOW }} />
                    <Typography sx={{ fontWeight: 700 }}>Verified</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <PersonIcon sx={{ color: YELLOW }} />
                    <Typography sx={{ fontWeight: 700 }}>Community</Typography>
                  </Box>
                </Box>

                <Typography sx={{ color: 'rgba(255,255,255,0.92)', lineHeight: 1.8 }}>
                  Sign up to access chat, reports, and community services.
                </Typography>
              </Paper>
            </motion.div>
          </Grid>

          <Grid item xs={12} md={7}>
            <motion.div initial={{ opacity: 0, x: 30 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.55, delay: 0.05 }}>
              <Paper sx={{ p: { xs: 3, md: 4 }, borderRadius: 4, border: '1px solid rgba(3,72,8,0.10)', boxShadow: 3 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                  <PersonIcon sx={{ color: GREEN }} />
                  <Typography sx={{ fontWeight: 950, fontSize: 24, color: GREEN }}>Create account</Typography>
                </Box>

                {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

                <Box component="form" onSubmit={handleRegister}>
                  <TextField
                    fullWidth
                    label="Full Name"
                    name="name"
                    value={formData.name}
                    onChange={handleChange}
                    margin="normal"
                    required
                  />
                  <TextField
                    fullWidth
                    label="Email"
                    name="email"
                    type="email"
                    value={formData.email}
                    onChange={handleChange}
                    margin="normal"
                    required
                  />

                  <Grid container spacing={2}>
                    <Grid item xs={12} sm={6}>
                      <TextField
                        fullWidth
                        label="Phone"
                        name="phone"
                        value={formData.phone}
                        onChange={handleChange}
                        margin="normal"
                        required
                      />
                    </Grid>
                    <Grid item xs={12} sm={6}>
                      <TextField
                        fullWidth
                        label="Apartment"
                        name="apartment"
                        value={formData.apartment}
                        onChange={handleChange}
                        margin="normal"
                        required
                      />
                    </Grid>
                  </Grid>

                  <TextField
                    fullWidth
                    label="Password"
                    name="password"
                    type="password"
                    value={formData.password}
                    onChange={handleChange}
                    margin="normal"
                    required
                  />
                  <TextField
                    fullWidth
                    label="Confirm Password"
                    name="confirmPassword"
                    type="password"
                    value={formData.confirmPassword}
                    onChange={handleChange}
                    margin="normal"
                    required
                  />

                  <Button
                    type="submit"
                    fullWidth
                    variant="contained"
                    disabled={loading}
                    sx={{
                      mt: 3,
                      bgcolor: GREEN,
                      py: 1.6,
                      fontWeight: 950,
                      '&:hover': { bgcolor: '#023206' },
                    }}
                  >
                    {loading ? <CircularProgress size={20} sx={{ color: 'white' }} /> : 'SIGN UP'}
                  </Button>
                </Box>

                <Button
                  fullWidth
                  variant="outlined"
                  onClick={handleGoogleRegister}
                  disabled={loading}
                  sx={{
                    mt: 2,
                    borderColor: GREEN,
                    color: GREEN,
                    py: 1.5,
                    fontWeight: 900,
                    '&:hover': { borderColor: '#023206', bgcolor: 'rgba(3,72,8,0.04)' },
                  }}
                >
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, justifyContent: 'center' }}>
                    <GoogleIcon />
                    Continue with Google
                  </Box>
                </Button>

                <Box sx={{ mt: 2, textAlign: 'center' }}>
                  <Link
                    component="button"
                    variant="body2"
                    onClick={() => navigate('/login')}
                    sx={{ color: GREEN, fontWeight: 800 }}
                  >
                    Already have an account? Sign In
                  </Link>
                </Box>
              </Paper>
            </motion.div>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
}

