import React, { useState } from 'react';
import {
  Box,
  Drawer,
  AppBar,
  Toolbar,
  List,
  Typography,
  Divider,
  IconButton,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Avatar,
  Badge,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Dashboard as DashboardIcon,
  Security as SecurityIcon,
  People as PeopleIcon,
  MeetingRoom as FacilitiesIcon,
  MonitorHeart as MonitoringIcon,
  Notifications as NotificationsIcon,
  Settings as SettingsIcon,
  Logout as LogoutIcon,
  Person as PersonIcon,
  Badge as BadgeIcon,
  Assessment as AssessmentIcon,
  Event as EventIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { useAuth } from '../context/AuthContext';

const drawerWidth = 280;

const menuItems = [
  { text: 'Overview', icon: <DashboardIcon />, path: '/dashboard' },
  { text: 'Security', icon: <SecurityIcon />, path: '/security' },
  { text: 'Community', icon: <PeopleIcon />, path: '/community' },
  { text: 'Facilities', icon: <FacilitiesIcon />, path: '/facilities' },
  { text: 'Monitoring', icon: <MonitoringIcon />, path: '/monitoring' },
  { text: 'Manage Accounts', icon: <PersonIcon />, path: '/accounts' },
  { text: 'Employees', icon: <BadgeIcon />, path: '/employees' },
  { text: 'Report', icon: <AssessmentIcon />, path: '/report' },
  { text: 'Events', icon: <EventIcon />, path: '/events' },
];


export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [mobileOpen, setMobileOpen] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const { logout } = useAuth();

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleLogout = async () => {
    try {
      await logout();
      navigate('/login');
      setMobileOpen(false);
    } catch (error) {
      console.error('Logout error:', error);
    }
  };

  const drawer = (
    <Box sx={{ 
      height: '100%', 
      bgcolor: '#034808', 
      color: 'white',
      borderRight: '1px solid rgba(255,215,0,0.1)',
      boxShadow: '4px 0 24px rgba(3,72,8,0.2)',
      display: 'flex',
      flexDirection: 'column'
    }}>
      <Toolbar sx={{ justifyContent: 'center', py: 3 }}>
        <Typography variant="h5" sx={{ 
          color: '#FFD700', 
          fontWeight: '900',
          letterSpacing: 2
        }}>
          ORELAX
        </Typography>
      </Toolbar>
      <Divider sx={{ bgcolor: 'rgba(255,255,255,0.2)' }} />
      <List sx={{ px: 2, flexGrow: 1 }}>
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <ListItem key={item.text} disablePadding sx={{ mb: 1 }}>
              <ListItemButton
                onClick={() => {
                  navigate(item.path);
                  setMobileOpen(false);
                }}
                sx={{
                  borderRadius: 2,
                  bgcolor: isActive ? 'rgba(255,215,0,0.1)' : 'transparent',
                  transition: 'all 0.2s',
                  '&:hover': {
                    bgcolor: '#FFD700',
                    transform: 'translateX(4px)',
                    '& .MuiListItemIcon-root': {
                      color: '#034808',
                    },
                    '& .MuiListItemText-primary': {
                      color: '#034808',
                    },
                  },
                }}
              >
                <ListItemIcon sx={{ 
                  color: isActive ? '#FFD700' : 'rgba(255,215,0,0.7)',
                  minWidth: 40
                }}>
                  {item.icon}
                </ListItemIcon>
                <ListItemText 
                  primary={item.text} 
                  sx={{ 
                    '& .MuiListItemText-primary': { 
                      color: isActive ? '#FFD700' : 'rgba(255,255,255,0.8)',
                      fontWeight: isActive ? 600 : 500 
                    } 
                  }} 
                />
              </ListItemButton>
            </ListItem>
          );
        })}
      </List>
      <Divider sx={{ bgcolor: 'rgba(255,255,255,0.2)' }} />
      <List sx={{ px: 2, pb: 3 }}>
        <ListItem disablePadding sx={{ mb: 1 }}>
          <ListItemButton sx={{
            borderRadius: 2,
            transition: 'all 0.2s',
            '&:hover': {
              bgcolor: 'rgba(255,215,0,0.1)',
              transform: 'translateX(4px)'
            }
          }}>
            <ListItemIcon sx={{ color: 'rgba(255,215,0,0.7)', minWidth: 40 }}>
              <SettingsIcon />
            </ListItemIcon>
            <ListItemText primary="Settings" sx={{ '& .MuiListItemText-primary': { color: 'rgba(255,255,255,0.8)' } }} />
          </ListItemButton>
        </ListItem>
        <ListItem disablePadding>
          <ListItemButton 
            onClick={handleLogout}
            sx={{
              borderRadius: 2,
              transition: 'all 0.2s',
              '&:hover': {
                bgcolor: 'rgba(255,215,0,0.1)',
                transform: 'translateX(4px)'
              }
            }}>
            <ListItemIcon sx={{ color: 'rgba(255,215,0,0.7)', minWidth: 40 }}>
              <LogoutIcon />
            </ListItemIcon>
            <ListItemText primary="Logout" sx={{ '& .MuiListItemText-primary': { color: 'rgba(255,255,255,0.8)' } }} />
          </ListItemButton>
        </ListItem>
      </List>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex' }}>
      <AppBar
        position="fixed"
        elevation={0}
        sx={{
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          ml: { sm: `${drawerWidth}px` },
          bgcolor: 'rgba(255, 255, 255, 0.8)',
          backdropFilter: 'blur(12px)',
          color: '#034808',
          borderBottom: '1px solid rgba(0,0,0,0.05)',
        }}
      >
        <Toolbar>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2, display: { sm: 'none' } }}
          >
            <MenuIcon />
          </IconButton>
          <Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
            Dashboard
          </Typography>
          <IconButton color="inherit">
            <Badge badgeContent={4} color="secondary">
              <NotificationsIcon />
            </Badge>
          </IconButton>
          <Avatar sx={{ ml: 2, bgcolor: '#FFD700', color: '#034808' }}>
            R
          </Avatar>
        </Toolbar>
      </AppBar>
      
      <Box
        component="nav"
        sx={{ width: { sm: drawerWidth }, flexShrink: { sm: 0 } }}
      >
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{ keepMounted: true }}
          sx={{
            display: { xs: 'block', sm: 'none' },
            '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth },
          }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          sx={{
            display: { xs: 'none', sm: 'block' },
            '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth },
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>
      
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          bgcolor: '#f5f5f5',
          minHeight: '100vh',
        }}
      >
        <Toolbar />
        <AnimatePresence mode="wait">
          <motion.div
            key={location.pathname}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.3 }}
          >
            {children}
          </motion.div>
        </AnimatePresence>
      </Box>
    </Box>
  );
}