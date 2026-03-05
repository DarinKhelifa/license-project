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
        <DashboardLayout>
          <Routes>
              {/* Public Routes */}
          <Route path="/" element={<LandingPage />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
            <Route path="/" element={<Overview />} />
            <Route path="/accounts" element={<ManageAccounts />} />
            {/*<Route path="/security" element={<Security />} />
            <Route path="/community" element={<Community />} />
            <Route path="/facilities" element={<Facilities />} />
            <Route path="/monitoring" element={<Monitoring />} />*/}
          </Routes>
        </DashboardLayout>
      </Router>
    </ThemeProvider>
  );
}

export default App;