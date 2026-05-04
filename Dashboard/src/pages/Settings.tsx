import React, { useState, useEffect } from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Avatar,
  Divider,
  Switch,
  FormControlLabel,
  List,
  ListItem,
  ListItemText,
} from '@mui/material';
import { PhotoCamera } from '@mui/icons-material';
import Snackbar from '@mui/material/Snackbar';
import Alert from '@mui/material/Alert';

import { authAPI, request, API_URL } from '../services/api';
import { useAuth } from '../context/AuthContext';
import { useThemeMode } from '../context/ThemeModeContext';
import { useRef } from 'react';

export default function Settings() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [twoFactor, setTwoFactor] = useState(false);
  const [reducedMotion, setReducedMotion] = useState(false);
  const [theme, setTheme] = useState<'auto' | 'light' | 'dark'>('auto');
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity?: 'success' | 'error' }>({ open: false, message: '' });

  // Types for settings response
  type UserSettings = {
    appearance?: { theme?: 'auto' | 'light' | 'dark'; reducedMotion?: boolean };
    notifications?: { inApp?: boolean; email?: boolean; sms?: boolean };
    security?: { twoFactorEnabled?: boolean };
  };

  type SettingsResponse = {
    id?: string;
    name?: string;
    email?: string;
    profileImage?: string;
    settings?: UserSettings;
  };

  // settings state
  const [inAppNotif, setInAppNotif] = useState(true);
  const [emailNotif, setEmailNotif] = useState(true);
  const [smsNotif, setSmsNotif] = useState(false);
  const { refreshUser, user } = useAuth();
  const { setMode } = useThemeMode();

  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [profileFile, setProfileFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const me = await authAPI.getMe();
        setName(me.name || '');
        setEmail(me.email || '');
        // load saved settings if available
        try {
          const s = await request<SettingsResponse>('/settings/me');
          if (s?.settings) {
            const st = s.settings as UserSettings;
            setTheme(st.appearance?.theme || 'auto');
            setReducedMotion(!!st.appearance?.reducedMotion);
            setInAppNotif(st.notifications?.inApp ?? true);
            setEmailNotif(st.notifications?.email ?? true);
            setSmsNotif(st.notifications?.sms ?? false);
          }
        } catch (e) {
          // backend settings not available, ignore
        }
      } catch (err) {
        // ignore
      }
    })();
  }, []);

  const showSnackbar = (message: string, severity: 'success' | 'error' = 'success') => {
    setSnackbar({ open: true, message, severity });
  };

  // --- Profile save ---
  const handleSaveProfile = async () => {
    try {
      await authAPI.updateProfile({ name });
      // Refresh user in context
      await refreshUser();
      showSnackbar('Profile saved', 'success');
    } catch (err: any) {
      showSnackbar(err?.message || 'Failed to save profile', 'error');
    }
  };

  const onSelectFile = (f?: File) => {
    if (!f) return;
    setProfileFile(f);
    const url = URL.createObjectURL(f);
    setPhotoPreview(url);
  };

  const handlePickFile = () => fileInputRef.current?.click();

  const handleFileChange: React.ChangeEventHandler<HTMLInputElement> = (e) => {
    const f = e.target.files?.[0];
    if (f) onSelectFile(f);
  };

  const handleUploadImage = async () => {
    if (!profileFile) return showSnackbar('No file selected', 'error');
    try {
      const token = localStorage.getItem('auth_token');
      const fd = new FormData();
      fd.append('profileImage', profileFile);
      fd.append('name', name);

      const res = await fetch(`${API_URL}/auth/profile`, {
        method: 'PUT',
        headers: {
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: fd,
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Upload failed');
      setProfileFile(null);
      setPhotoPreview(null);
      await refreshUser();
      showSnackbar('Profile image uploaded', 'success');
    } catch (err: any) {
      showSnackbar(err?.message || 'Failed to upload image', 'error');
    }
  };

  const handleRemoveImage = async () => {
    try {
      const token = localStorage.getItem('auth_token');
      const res = await fetch(`${API_URL}/auth/profile`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({ removeProfileImage: true }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Remove failed');
      setProfileFile(null);
      setPhotoPreview(null);
      await refreshUser();
      showSnackbar('Profile image removed', 'success');
    } catch (err: any) {
      showSnackbar(err?.message || 'Failed to remove image', 'error');
    }
  };

  const handleSaveAppearance = async () => {
    try {
      await request('/settings/appearance', { method: 'PUT', body: JSON.stringify({ theme, reducedMotion }) });
      // apply theme locally
      if (theme === 'auto') {
        const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
        setMode(prefersDark ? 'dark' : 'light');
      } else {
        setMode(theme as 'light' | 'dark');
      }
      showSnackbar('Appearance saved', 'success');
    } catch (err: any) {
      showSnackbar(err?.message || 'Failed to save appearance', 'error');
    }
  };

  const handleSaveNotifications = async () => {
    try {
      await request('/settings/notifications', { method: 'PUT', body: JSON.stringify({ inApp: inAppNotif, email: emailNotif, sms: smsNotif }) });
      showSnackbar('Notifications saved', 'success');
    } catch (err: any) {
      showSnackbar(err?.message || 'Failed to save notifications', 'error');
    }
  };

  const handleToggleTwoFactor = async (value: boolean) => {
    try {
      setTwoFactor(value);
      await request('/settings/security', { method: 'PUT', body: JSON.stringify({ twoFactorEnabled: value }) });
      showSnackbar('Security settings updated', 'success');
    } catch (err: any) {
      showSnackbar(err?.message || 'Failed to update security settings', 'error');
    }
  };

  

  return (
    <Box>
      <Typography variant="h4" sx={{ mb: 3, fontWeight: 800 }}>
        Settings
      </Typography>

      <Grid container spacing={3}>
        {/* Account */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 800, mb: 1 }}>
                Account
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Manage your profile and account settings.
              </Typography>

              <input ref={fileInputRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={handleFileChange} />
              <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', mb: 2 }}>
                <Avatar src={photoPreview || user?.profileImage || undefined} sx={{ width: 64, height: 64 }}>{!photoPreview && !(user?.profileImage) && 'U'}</Avatar>
                <Box>
                  <Typography variant="subtitle2">Profile photo</Typography>
                  <Box sx={{ display: 'flex', gap: 1, mt: 1 }}>
                    <Button startIcon={<PhotoCamera />} variant="outlined" size="small" onClick={handlePickFile}>Upload</Button>
                    <Button variant="text" size="small" onClick={handleRemoveImage}>Remove</Button>
                    {profileFile && <Button size="small" variant="contained" onClick={handleUploadImage}>Save image</Button>}
                  </Box>
                </Box>
              </Box>

              <TextField label="Full name" fullWidth value={name} onChange={(e) => setName(e.target.value)} sx={{ mb: 2 }} />
              <TextField label="Email" fullWidth value={email} onChange={(e) => setEmail(e.target.value)} sx={{ mb: 2 }} />

              <Box sx={{ display: 'flex', gap: 1 }}>
                <Button variant="contained" onClick={handleSaveProfile}>Save profile</Button>
                <Button variant="outlined">Change password</Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Security */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 800, mb: 1 }}>
                Security
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Keep your account secure.
              </Typography>

              <FormControlLabel
                control={<Switch checked={twoFactor} onChange={(e) => handleToggleTwoFactor(e.target.checked)} />}
                label="Two-factor authentication (TOTP)"
              />

              <Box sx={{ mt: 2 }}>
                <Typography variant="subtitle2">Active sessions</Typography>
                <List dense>
                  <ListItem secondaryAction={<Button size="small">Sign out</Button>}>
                    <ListItemText primary="Chrome on Windows" secondary="This device" />
                  </ListItem>
                  <ListItem secondaryAction={<Button size="small">Sign out</Button>}>
                    <ListItemText primary="Mobile (iOS)" secondary="Last active 2 days ago" />
                  </ListItem>
                </List>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Notifications */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 800, mb: 1 }}>
                Notifications
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Control which notifications you receive and how.
              </Typography>

              <FormControlLabel control={<Switch checked={inAppNotif} onChange={(e) => setInAppNotif(e.target.checked)} />} label="In-app notifications" />
              <FormControlLabel control={<Switch checked={emailNotif} onChange={(e) => setEmailNotif(e.target.checked)} />} label="Email notifications" />
              <FormControlLabel control={<Switch checked={smsNotif} onChange={(e) => setSmsNotif(e.target.checked)} />} label="SMS notifications" />

              <Box sx={{ mt: 2, display: 'flex', gap: 1 }}>
                <Button variant="contained" onClick={handleSaveNotifications}>Save notifications</Button>
                <Button variant="outlined">Send test notification</Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Privacy & Data */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 800, mb: 1 }}>
                Privacy & Data
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Export or remove your data, and configure retention.
              </Typography>

              <Box sx={{ display: 'flex', gap: 1, mb: 2 }}>
                <Button variant="outlined">Export data (JSON)</Button>
                <Button variant="outlined">Export data (CSV)</Button>
              </Box>

              <Divider sx={{ my: 2 }} />
              <Typography variant="subtitle2">Delete account</Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                Deleting your account removes all personal data. This action is irreversible.
              </Typography>
              <Button color="error" variant="contained">Delete account</Button>
            </CardContent>
          </Card>
        </Grid>

        {/* Appearance & Accessibility */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 800, mb: 1 }}>
                Appearance & Accessibility
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Personalize theme, motion, and text size.
              </Typography>

              <Box sx={{ display: 'flex', gap: 1, mb: 2, alignItems: 'center' }}>
                <Button variant={theme === 'light' ? 'contained' : 'outlined'} onClick={() => setTheme('light')}>Light</Button>
                <Button variant={theme === 'dark' ? 'contained' : 'outlined'} onClick={() => setTheme('dark')}>Dark</Button>
                <Button variant={theme === 'auto' ? 'contained' : 'outlined'} onClick={() => setTheme('auto')}>Auto</Button>
              </Box>

              <FormControlLabel control={<Switch checked={reducedMotion} onChange={(e) => setReducedMotion(e.target.checked)} />} label="Reduce motion" />
              <Box sx={{ mt: 2 }}>
                <Button variant="contained" onClick={handleSaveAppearance}>Save appearance</Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        {/* (Removed integrations, privacy and admin sections; keeping only Account, Security, Notifications, Appearance) */}
      </Grid>
        <Snackbar open={snackbar.open} autoHideDuration={5000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'top', horizontal: 'right' }}>
          <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity ?? 'success'} sx={{ width: '100%' }}>
            {snackbar.message}
          </Alert>
        </Snackbar>
    </Box>
  );
}
