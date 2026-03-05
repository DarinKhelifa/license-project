import { useState, ChangeEvent, FormEvent } from 'react';
import {
  Box,
  Paper,
  TextField,
  Button,
  Typography,
  Link,
  Alert,
} from '@mui/material';
import Grid from '@mui/material/Grid'; // Import Grid2
import { useNavigate } from 'react-router-dom';

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

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleRegister = (e: FormEvent) => {
    e.preventDefault();
    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      return;
    }
    // TODO: Add actual registration
    localStorage.setItem('isAuthenticated', 'true');
    navigate('/dashboard');
  };

  return (
    <Box sx={{ 
      minHeight: '100vh', 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center',
      bgcolor: '#f5f5f5',
      p: 2
    }}>
      <Paper sx={{ maxWidth: 500, width: '100%', p: 4 }}>
        <Typography variant="h4" sx={{ color: '#034808', mb: 1, textAlign: 'center' }}>
          ORELAX
        </Typography>
        <Typography variant="body2" sx={{ mb: 3, textAlign: 'center', color: 'gray' }}>
          SMART · SAFE · COMFORTABLE
        </Typography>
        
        <Typography variant="h5" sx={{ mb: 3 }}>
          Create Account
        </Typography>

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
            <Grid size={{ xs: 12, sm: 6 }}> {/* Fixed: using size prop */}
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
            <Grid size={{ xs: 12, sm: 6 }}> {/* Fixed: using size prop */}
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
            sx={{
              mt: 3,
              mb: 2,
              bgcolor: '#034808',
              '&:hover': { bgcolor: '#023206' },
              py: 1.5,
            }}
          >
            SIGN UP
          </Button>
        </Box>

        <Box sx={{ textAlign: 'center' }}>
          <Link
            component="button"
            variant="body2"
            onClick={() => navigate('/login')}
            sx={{ color: '#034808' }}
          >
            Already have an account? Sign In
          </Link>
        </Box>
      </Paper>
    </Box>
  );
}