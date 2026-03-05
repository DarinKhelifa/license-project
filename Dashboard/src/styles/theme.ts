import { createTheme } from '@mui/material/styles';

export const orelaxTheme = createTheme({
  palette: {
    primary: {
      main: '#034808', // Dark green from mobile app
      light: '#2b6b2f',
      dark: '#023206',
      contrastText: '#ffffff',
    },
    secondary: {
      main: '#FFD700', // Yellow accent
      light: '#FFE44D',
      dark: '#CCAC00',
      contrastText: '#034808',
    },
    background: {
      default: '#f5f5f5',
      paper: '#ffffff',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
    h4: {
      fontWeight: 600,
      color: '#034808',
    },
    h5: {
      fontWeight: 600,
      color: '#034808',
    },
    h6: {
      fontWeight: 600,
    },
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          textTransform: 'none',
          fontWeight: 600,
        },
        containedPrimary: {
          backgroundColor: '#034808',
          '&:hover': {
            backgroundColor: '#023206',
          },
        },
        containedSecondary: {
          backgroundColor: '#FFD700',
          color: '#034808',
          '&:hover': {
            backgroundColor: '#CCAC00',
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: '#034808',
        },
      },
    },
  },
});