import React, { useMemo, useState } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import type { PaletteMode } from '@mui/material';
import { createOrelaxTheme } from './styles/theme';
import { AuthProvider } from './context/AuthContext';
import { ThemeModeProvider } from './context/ThemeModeContext';
import { NotificationsProvider } from './context/NotificationsContext';
import AuthGuard from './components/AuthGuard';
import LandingPage from './pages/LandingPage';
import Login from './pages/Login';
import Register from './pages/Register';
import DashboardLayout from './components/DashboardLayout';
import Overview from './pages/Overview';
import ManageAccounts from './pages/ManageAccounts';
import Employees from './pages/Employees';
import Report from './pages/Report';
import Events from './pages/Events';
import Guests from './pages/Guests';
import GuestDetail from './pages/GuestDetail';
import Settings from './pages/Settings';
import Contacts from './pages/Contacts';
import MyResidences from './pages/MyResidences';
import FireAlerts from './pages/FireAlerts';
import GlobalFireOverlay from './components/GlobalFireOverlay';

/*import Security from './pages/Security';
import Community from './pages/Community';
import Facilities from './pages/Facilities';
import Monitoring from './pages/Monitoring';*/

const THEME_MODE_STORAGE_KEY = 'orelax-dashboard-theme-mode';

function getInitialMode(): PaletteMode {
  const raw = window.localStorage.getItem(THEME_MODE_STORAGE_KEY);
  if (raw === 'light' || raw === 'dark') return raw;
  return 'dark';
}

function App() {
  const [mode, setMode] = useState<PaletteMode>(() => getInitialMode());

  const theme = useMemo(() => createOrelaxTheme(mode), [mode]);
  const themeModeValue = useMemo(
    () => ({
      mode,
      setMode: (m: PaletteMode) => {
        window.localStorage.setItem(THEME_MODE_STORAGE_KEY, m);
        setMode(m);
      },
      toggleMode: () => {
        const next: PaletteMode = mode === 'dark' ? 'light' : 'dark';
        window.localStorage.setItem(THEME_MODE_STORAGE_KEY, next);
        setMode(next);
      },
    }),
    [mode]
  );

  return (
    <ThemeModeProvider value={themeModeValue}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <AuthProvider>
          <NotificationsProvider>
            <GlobalFireOverlay />
            <Router>
              <Routes>
              {/* Public Routes - NO DASHBOARD LAYOUT */}
              <Route path="/" element={<LandingPage />} />
              <Route path="/login" element={<Login />} />
              <Route path="/register" element={<Register />} />

              {/* Protected Routes - WITH DASHBOARD LAYOUT AND AUTH GUARD */}
              <Route
                path="/dashboard"
                element={
                  <AuthGuard>
                    <DashboardLayout>
                      <Overview />
                    </DashboardLayout>
                  </AuthGuard>
                }
              />
              <Route
                path="/accounts"
                element={
                  <AuthGuard>
                    <DashboardLayout>
                      <ManageAccounts />
                    </DashboardLayout>
                  </AuthGuard>
                }
              />
              <Route
                path="/employees"
                element={
                  <AuthGuard>
                    <DashboardLayout>
                      <Employees />
                    </DashboardLayout>
                  </AuthGuard>
                }
              />
              <Route
                path="/report"
                element={
                  <AuthGuard>
                    <DashboardLayout>
                      <Report />
                    </DashboardLayout>
                  </AuthGuard>
                }
              />
              <Route
                path="/events"
                element={
                  <AuthGuard>
                    <DashboardLayout>
                      <Events />
                    </DashboardLayout>
                  </AuthGuard>
                }
              />
              <Route
                path="/residences"
                element={
                  <AuthGuard>
                    <DashboardLayout>
                      <MyResidences />
                    </DashboardLayout>
                  </AuthGuard>
                }
              />
              <Route
                path="/guests"
                element={
                  <AuthGuard>
                    <DashboardLayout>
                      <Guests />
                    </DashboardLayout>
                  </AuthGuard>
                }
              />
              <Route
                path="/contacts"
                element={
                  <AuthGuard>
                    <DashboardLayout>
                      <Contacts />
                    </DashboardLayout>
                  </AuthGuard>
                }
              />
              <Route
                path="/guests/:guestId"
                element={
                  <AuthGuard>
                    <DashboardLayout>
                      <GuestDetail />
                    </DashboardLayout>
                  </AuthGuard>
                }
              />
              <Route
                path="/fire-alerts"
                element={
                  <AuthGuard>
                    <DashboardLayout>
                      <FireAlerts />
                    </DashboardLayout>
                  </AuthGuard>
                }
              />
              <Route
                path="/settings"
                element={
                  <AuthGuard>
                    <DashboardLayout>
                      <Settings />
                    </DashboardLayout>
                  </AuthGuard>
                }
              />
              {/* Security / Facilities removed from UI */}
              </Routes>
            </Router>
          </NotificationsProvider>
        </AuthProvider>
      </ThemeProvider>
    </ThemeModeProvider>
  );
}

export default App;