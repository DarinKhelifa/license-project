import React, { useMemo, useState } from 'react';
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
  Stack,
  Menu,
  MenuItem,
  ListItemAvatar,
} from '@mui/material';
import { alpha, useTheme } from '@mui/material/styles';
import {
  Menu as MenuIcon,
  Dashboard as DashboardIcon,
  People as PeopleIcon,
  MonitorHeart as MonitoringIcon,
  Notifications as NotificationsIcon,
  Settings as SettingsIcon,
  Logout as LogoutIcon,
  Person as PersonIcon,
  Badge as BadgeIcon,
  Assessment as AssessmentIcon,
  Event as EventIcon,
  Business as BusinessIcon,
  DarkMode as DarkModeIcon,
  LightMode as LightModeIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { useAuth } from '../context/AuthContext';
import { useThemeMode } from '../context/ThemeModeContext';
import { useNotifications } from '../context/NotificationsContext';

const drawerWidth = 280;

const menuItems = [
  { text: 'Overview', icon: <DashboardIcon />, path: '/dashboard' },
  { text: 'Guests', icon: <PeopleIcon />, path: '/guests' },
  { text: 'Contacts', icon: <BadgeIcon />, path: '/contacts' },
  { text: 'Monitoring', icon: <MonitoringIcon />, path: '/monitoring' },
  { text: 'Manage Accounts', icon: <PersonIcon />, path: '/accounts' },
  { text: 'Employees', icon: <BadgeIcon />, path: '/employees' },
  { text: 'Report', icon: <AssessmentIcon />, path: '/report' },
  { text: 'Events', icon: <EventIcon />, path: '/events' },
  { text: 'My Residences', icon: <BusinessIcon />, path: '/residences' },
];

function NotificationsButton() {
  const { notifications, unreadCount, markAllRead } = useNotifications();
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);

  const handleOpen = (e: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(e.currentTarget);
  };
  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleMarkAll = () => {
    markAllRead();
    handleClose();
  };

  return (
    <>
      <IconButton color="inherit" onClick={handleOpen} aria-label="Notifications">
        <Badge badgeContent={unreadCount} color="secondary">
          <NotificationsIcon />
        </Badge>
      </IconButton>
      <Menu anchorEl={anchorEl} open={Boolean(anchorEl)} onClose={handleClose} PaperProps={{ sx: { width: 360, maxWidth: '90vw' } }}>
        <MenuItem dense sx={{ justifyContent: 'space-between' }}>
          <strong>Notifications</strong>
          <Box component="span" onClick={handleMarkAll} sx={{ cursor: 'pointer', fontSize: 12, color: 'text.secondary' }}>Mark all read</Box>
        </MenuItem>
        {notifications.length === 0 && (
          <MenuItem disabled>No notifications</MenuItem>
        )}
        {notifications.map((n, idx) => (
          <MenuItem key={n._id ?? idx} onClick={handleClose} sx={{ whiteSpace: 'normal' }}>
            <ListItemAvatar>
              <Avatar sx={{ bgcolor: 'secondary.main' }}>{(n.type?.[0] ?? 'N').toUpperCase()}</Avatar>
            </ListItemAvatar>
            <ListItemText primary={n.title ?? 'Notification'} secondary={n.message} />
          </MenuItem>
        ))}
      </Menu>
    </>
  );
}


export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [mobileOpen, setMobileOpen] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const { logout, user } = useAuth();
  const theme = useTheme();
  const { mode, toggleMode } = useThemeMode();
  const { refreshUser } = useAuth();

  const isDark = theme.palette.mode === 'dark';

  function ProfileMenu() {
    const { user, logout, refreshUser } = useAuth();
    const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
    const open = Boolean(anchorEl);
    const handleOpen = (e: React.MouseEvent<HTMLElement>) => setAnchorEl(e.currentTarget);
    const handleClose = () => setAnchorEl(null);

    const handleLogoutClick = async () => {
      await logout();
      handleClose();
    };

    return (
      <>
        <IconButton onClick={handleOpen} sx={{ ml: 2 }}>
          <Avatar src={user?.profileImage || undefined} sx={{ bgcolor: theme.palette.secondary.main, color: theme.palette.primary.dark, fontWeight: 900 }}>
            {(user?.name?.[0] ?? 'U').toUpperCase()}
          </Avatar>
        </IconButton>
        <Menu anchorEl={anchorEl} open={open} onClose={handleClose} PaperProps={{ sx: { width: 260 } }}>
          <Box sx={{ p: 2, display: 'flex', gap: 1, alignItems: 'center' }}>
            <Avatar src={user?.profileImage || undefined} sx={{ width: 56, height: 56, bgcolor: theme.palette.secondary.main }} />
            <Box>
              <Typography sx={{ fontWeight: 800 }}>{user?.name ?? 'User'}</Typography>
              <Typography variant="caption" color="text.secondary">{user?.email}</Typography>
            </Box>
          </Box>
          <Divider />
          <MenuItem onClick={() => { navigate('/settings'); handleClose(); }}>Profile settings</MenuItem>
          <MenuItem onClick={handleLogoutClick}>Logout</MenuItem>
        </Menu>
      </>
    );
  }

  const pageTitle = useMemo(() => {
    const matched = menuItems.find((m) => m.path === location.pathname);
    return matched?.text ?? 'Dashboard';
  }, [location.pathname]);

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
    <Box
      sx={{
        height: '100%',
        color: isDark ? theme.palette.text.primary : 'common.white',
        borderRight: `1px solid ${alpha(isDark ? theme.palette.common.white : '#ffffff', 0.10)}`,
        boxShadow: isDark ? '10px 0 40px rgba(0, 0, 0, 0.45)' : '10px 0 40px rgba(2, 50, 6, 0.20)',
        display: 'flex',
        flexDirection: 'column',
        background: isDark
          ? `linear-gradient(180deg, ${theme.palette.background.paper} 0%, ${alpha(theme.palette.background.default, 0.98)} 100%)`
          : `linear-gradient(180deg, ${theme.palette.primary.dark} 0%, ${theme.palette.primary.main} 55%, ${alpha(
              theme.palette.primary.dark,
              0.92
            )} 100%)`,
      }}
    >
      <Toolbar sx={{ py: 2.5, minHeight: 88, px: 2.5, justifyContent: 'center' }}>
        <Box component="img" src="/logo.svg" alt="Orelax" sx={{ width: 44, height: 44 }} />
      </Toolbar>

      <Divider sx={{ bgcolor: alpha(isDark ? theme.palette.common.white : '#ffffff', 0.12) }} />
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
                  bgcolor: isActive
                    ? alpha(theme.palette.primary.main, isDark ? 0.18 : 0.14)
                    : 'transparent',
                  border: `1px solid ${
                    isActive
                      ? alpha(theme.palette.primary.main, isDark ? 0.26 : 0.22)
                      : 'transparent'
                  }`,
                  transition: 'all 0.18s ease',
                  '&:hover': {
                    bgcolor: alpha(isDark ? theme.palette.common.white : '#ffffff', isDark ? 0.06 : 0.10),
                    transform: 'translateX(4px)',
                    '& .MuiListItemIcon-root': {
                      color: theme.palette.secondary.main,
                    },
                    '& .MuiListItemText-primary': {
                      color: isDark ? theme.palette.text.primary : '#ffffff',
                    },
                  },
                  position: 'relative',
                  overflow: 'hidden',
                  '&::before': {
                    content: '""',
                    position: 'absolute',
                    left: 0,
                    top: 10,
                    bottom: 10,
                    width: 3,
                    borderRadius: 2,
                    bgcolor: isActive ? theme.palette.secondary.main : 'transparent',
                  },
                }}
              >
                <ListItemIcon sx={{ 
                  color: isActive
                    ? theme.palette.secondary.main
                    : alpha(isDark ? theme.palette.text.primary : theme.palette.secondary.main, isDark ? 0.75 : 0.72),
                  minWidth: 40
                }}>
                  {item.icon}
                </ListItemIcon>
                <ListItemText 
                  primary={item.text} 
                  sx={{ 
                    '& .MuiListItemText-primary': { 
                      color: isActive
                        ? theme.palette.secondary.main
                        : alpha(isDark ? theme.palette.text.primary : '#ffffff', isDark ? 0.86 : 0.86),
                      fontWeight: isActive ? 850 : 650,
                      letterSpacing: 0.2,
                    } 
                  }} 
                />
              </ListItemButton>
            </ListItem>
          );
        })}
      </List>
      <Divider sx={{ bgcolor: alpha(isDark ? theme.palette.common.white : '#ffffff', 0.12) }} />

      <Box sx={{ px: 2, pt: 2.2 }}>
        <Box
          sx={{
            borderRadius: 3,
            border: `1px solid ${alpha(isDark ? theme.palette.common.white : '#ffffff', isDark ? 0.10 : 0.14)}`,
            bgcolor: isDark ? alpha(theme.palette.common.black, 0.25) : alpha('#000000', 0.14),
            p: 1.6,
          }}
        >
          <Stack direction="row" spacing={1.4} alignItems="center">
            <Avatar sx={{ bgcolor: theme.palette.secondary.main, color: theme.palette.primary.dark, fontWeight: 900 }}>
              {(user?.name?.[0] ?? 'U').toUpperCase()}
            </Avatar>
            <Box sx={{ minWidth: 0, flex: 1 }}>
              <Typography sx={{ fontWeight: 900, color: isDark ? theme.palette.text.primary : '#fff', lineHeight: 1.1 }} noWrap>
                {user?.name ?? 'User'}
              </Typography>
              <Typography
                sx={{
                  fontSize: 12,
                  color: isDark ? alpha(theme.palette.text.primary, 0.72) : alpha('#ffffff', 0.72),
                  fontWeight: 700,
                }}
                noWrap
              >
                {user?.email ?? ''}
              </Typography>
            </Box>
          </Stack>
        </Box>
      </Box>

      <List sx={{ px: 2, pb: 3, pt: 1.4 }}>
        <ListItem disablePadding sx={{ mb: 1 }}>
          <ListItemButton onClick={() => { navigate('/settings'); setMobileOpen(false); }} sx={{
            borderRadius: 2,
            transition: 'all 0.2s',
            '&:hover': {
              bgcolor: alpha(isDark ? theme.palette.common.white : '#ffffff', isDark ? 0.06 : 0.10),
              transform: 'translateX(4px)'
            }
          }}>
            <ListItemIcon
              sx={{
                color: alpha(isDark ? theme.palette.text.primary : theme.palette.secondary.main, isDark ? 0.75 : 0.72),
                minWidth: 40,
              }}
            >
              <SettingsIcon />
            </ListItemIcon>
            <ListItemText
              primary="Settings"
              sx={{
                '& .MuiListItemText-primary': {
                  color: alpha(isDark ? theme.palette.text.primary : '#ffffff', 0.86),
                  fontWeight: 750,
                },
              }}
            />
          </ListItemButton>
        </ListItem>
        <ListItem disablePadding>
          <ListItemButton 
            onClick={handleLogout}
            sx={{
              borderRadius: 2,
              transition: 'all 0.2s',
              '&:hover': {
                bgcolor: alpha(isDark ? theme.palette.common.white : '#ffffff', isDark ? 0.06 : 0.10),
                transform: 'translateX(4px)'
              }
            }}>
            <ListItemIcon
              sx={{
                color: alpha(isDark ? theme.palette.text.primary : theme.palette.secondary.main, isDark ? 0.75 : 0.72),
                minWidth: 40,
              }}
            >
              <LogoutIcon />
            </ListItemIcon>
            <ListItemText
              primary="Logout"
              sx={{
                '& .MuiListItemText-primary': {
                  color: alpha(isDark ? theme.palette.text.primary : '#ffffff', 0.86),
                  fontWeight: 750,
                },
              }}
            />
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
          bgcolor: alpha(theme.palette.background.paper, 0.72),
          backdropFilter: 'blur(12px)',
          color: theme.palette.text.primary,
          borderBottom: `1px solid ${alpha(theme.palette.common.white, 0.08)}`,
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
          <Box sx={{ flexGrow: 1, minWidth: 0 }}>
            <Typography variant="h6" noWrap component="div" sx={{ fontWeight: 950, color: theme.palette.text.primary }}>
              {pageTitle}
            </Typography>
          </Box>

          <IconButton
            onClick={toggleMode}
            color="inherit"
            sx={{
              mr: 0.5,
              border: `1px solid ${alpha(theme.palette.text.primary, theme.palette.mode === 'dark' ? 0.16 : 0.12)}`,
              bgcolor: alpha(theme.palette.background.paper, 0.32),
              '&:hover': { bgcolor: alpha(theme.palette.background.paper, 0.52) },
            }}
            aria-label={mode === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
          >
            {mode === 'dark' ? <LightModeIcon /> : <DarkModeIcon />}
          </IconButton>

          <NotificationsButton />
          <ProfileMenu />
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
          p: { xs: 2, sm: 3 },
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          bgcolor: 'background.default',
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