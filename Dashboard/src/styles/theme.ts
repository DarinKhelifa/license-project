import { alpha, createTheme } from '@mui/material/styles';
import type { PaletteMode } from '@mui/material';

export function createOrelaxTheme(mode: PaletteMode) {
  const isDark = mode === 'dark';

  return createTheme({
  shape: {
    borderRadius: 14,
  },
  palette: {
    mode,
    primary: {
      // Keep Orelax branding green, but make it readable in dark mode.
      main: isDark ? '#22c55e' : '#034808',
      light: isDark ? '#4ade80' : '#2b6b2f',
      dark: isDark ? '#15803d' : '#023206',
      contrastText: '#ffffff',
    },
    secondary: {
      main: '#FFD700', // Yellow accent
      light: '#FFE44D',
      dark: '#CCAC00',
      contrastText: '#034808',
    },
    background: {
      default: isDark ? '#0b1220' : '#f6f7f8',
      paper: isDark ? '#0f172a' : '#ffffff',
    },
    text: {
      primary: isDark ? '#e2e8f0' : '#0f172a',
      secondary: isDark ? alpha('#e2e8f0', 0.68) : alpha('#0f172a', 0.68),
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
    h4: {
      fontWeight: 900,
      letterSpacing: -0.4,
      color: isDark ? '#e2e8f0' : '#034808',
    },
    h5: {
      fontWeight: 800,
      color: isDark ? '#e2e8f0' : '#034808',
    },
    h6: {
      fontWeight: 800,
    },
    subtitle1: {
      fontWeight: 700,
    },
    body1: {
      lineHeight: 1.7,
    },
  },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        body: {
          backgroundColor: isDark ? '#0b1220' : '#f6f7f8',
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          textTransform: 'none',
          fontWeight: 800,
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
          borderRadius: 18,
          boxShadow: isDark ? '0 16px 46px rgba(0, 0, 0, 0.45)' : '0 10px 30px rgba(15, 23, 42, 0.06)',
          border: `1px solid ${alpha(isDark ? '#ffffff' : '#0f172a', isDark ? 0.10 : 0.06)}`,
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 18,
          border: `1px solid ${alpha(isDark ? '#ffffff' : '#0f172a', isDark ? 0.10 : 0.06)}`,
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: isDark ? '#0f172a' : '#034808',
        },
      },
    },
  },
  });
}

// Backward-compatible default export for existing imports.
export const orelaxTheme = createOrelaxTheme('dark');