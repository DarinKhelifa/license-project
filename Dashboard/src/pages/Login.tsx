import React, { useState, FormEvent, ChangeEvent } from 'react';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Link,
  Alert,
  Paper,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';

export default function Login() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const handleLogin = (e: FormEvent) => {
    e.preventDefault();
    // TODO: Add actual authentication
    if (email && password) {
      // For demo, any credentials work
      localStorage.setItem('isAuthenticated', 'true');
      navigate('/dashboard');
    } else {
      setError('Please fill in all fields');
    }
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
      <Paper sx={{ maxWidth: 400, width: '100%', p: 4 }}>
        <Typography variant="h4" sx={{ color: '#034808', mb: 1, textAlign: 'center' }}>
          ORELAX
        </Typography>
        <Typography variant="body2" sx={{ mb: 3, textAlign: 'center', color: 'gray' }}>
          SMART · SAFE · COMFORTABLE
        </Typography>
        
        <Typography variant="h5" sx={{ mb: 3 }}>
          Welcome Back
        </Typography>

        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

        <Box component="form" onSubmit={handleLogin}>
          <TextField
            fullWidth
            label="Email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            margin="normal"
            required
          />
          <TextField
            fullWidth
            label="Password"
            type="password"
            value={password}
            onChange={(e: ChangeEvent<HTMLInputElement>) => setPassword(e.target.value)}
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
            LOGIN
          </Button>
        </Box>

        <Box sx={{ textAlign: 'center' }}>
          <Link
            component="button"
            variant="body2"
            onClick={() => navigate('/register')}
            sx={{ color: '#034808' }}
          >
            Don't have an account? Sign Up
          </Link>
        </Box>
      </Paper>
    </Box>
  );
}