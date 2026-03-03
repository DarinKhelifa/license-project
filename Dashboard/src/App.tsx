import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { orelaxTheme } from './styles/theme';
import DashboardLayout from './components/DashboardLayout';
import Overview from './pages/Overview';
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
            <Route path="/" element={<Overview />} />
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