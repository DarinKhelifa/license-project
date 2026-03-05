import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { orelaxTheme } from './styles/theme';
import AuthGuard from './components/AuthGuard';
import LandingPage from './pages/LandingPage';
import Login from './pages/Login';
import Register from './pages/Register';
import DashboardLayout from './components/DashboardLayout';
import Overview from './pages/Overview';
import ManageAccounts from './pages/ManageAccounts';
/*import Security from './pages/Security';
import Community from './pages/Community';
import Facilities from './pages/Facilities';
import Monitoring from './pages/Monitoring';*/

function App() {
  return (
    <ThemeProvider theme={orelaxTheme}>
      <CssBaseline />
      <Router>
        <Routes>
          {/* Public Routes - NO DASHBOARD LAYOUT */}
          <Route path="/" element={<LandingPage />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          
          {/* Protected Routes - WITH DASHBOARD LAYOUT AND AUTH GUARD */}
          <Route path="/dashboard" element={
            <AuthGuard>
              <DashboardLayout>
                <Overview />
              </DashboardLayout>
            </AuthGuard>
          } />
          <Route path="/accounts" element={
            <AuthGuard>
              <DashboardLayout>
                <ManageAccounts />
              </DashboardLayout>
            </AuthGuard>
          } />
          {/*<Route path="/security" element={
            <AuthGuard>
              <DashboardLayout>
                <Security />
              </DashboardLayout>
            </AuthGuard>
          } />
          <Route path="/community" element={
            <AuthGuard>
              <DashboardLayout>
                <Community />
              </DashboardLayout>
            </AuthGuard>
          } />
          <Route path="/facilities" element={
            <AuthGuard>
              <DashboardLayout>
                <Facilities />
              </DashboardLayout>
            </AuthGuard>
          } />
          <Route path="/monitoring" element={
            <AuthGuard>
              <DashboardLayout>
                <Monitoring />
              </DashboardLayout>
            </AuthGuard>
          />*/}
        </Routes>
      </Router>
    </ThemeProvider>
  );
}

export default App;