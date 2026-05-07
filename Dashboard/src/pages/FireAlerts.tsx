import { useEffect, useMemo, useState, useCallback } from 'react';
import axios from 'axios';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Grid,
  Stack,
  Typography,
  Divider,
  alpha,
  useTheme,
} from '@mui/material';
import { Refresh as RefreshIcon, LocalFireDepartment as FireIcon, CheckCircle as CheckIcon, ErrorOutline as WarningIcon } from '@mui/icons-material';
import { motion } from 'framer-motion';

// Recency threshold used by overlays and normalization
const RECENT_THRESHOLD_MS = 5 * 60 * 1000; // 5 minutes
const API_BASE = (((globalThis as typeof globalThis & {
  process?: { env?: Record<string, string | undefined> };
}).process?.env?.REACT_APP_API_URL) || 'http://localhost:5000').replace(/\/api$/, '');
const ALERTS_URL = `${API_BASE}/api/iot/alerts`;

interface AlertItem {
  _id: string;
  type: string;
  sensor: string;
  location: string;
  status: 'active' | 'resolved';
  timestamp: string;
}

function formatDateTime(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return { date: 'Unknown date', time: 'Unknown time' };

  return {
    date: date.toLocaleDateString('en-GB', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    }),
    time: date.toLocaleTimeString('en-GB', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    }),
  };
}

export default function FireAlerts() {
  const theme = useTheme();
  const [alerts, setAlerts] = useState<AlertItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // RECENT_THRESHOLD_MS declared at module scope

  const fetchAlerts = useCallback(async (showSpinner = false) => {
    try {
      if (showSpinner) setRefreshing(true);
      setError(null);

      const res = await axios.get(ALERTS_URL);
      const payload = res.data;

      const list = Array.isArray(payload)
        ? payload
        : Array.isArray(payload?.alerts)
          ? payload.alerts
          : [];

      const normalized = list
        .map((item: any) => {
          const _id = String(item._id ?? item.id ?? crypto.randomUUID());
          // Do not default unknown types to 'FIRE' — default to empty to avoid false positives
          const type = String(item.type ?? '');
          const sensor = String(item.sensor ?? 'flame_sensor');
          const location = String(item.location ?? 'Unknown');
          const timestamp = String(item.timestamp ?? item.createdAt ?? new Date().toISOString());

          // Normalize status: only treat explicit "active" as active; unknown/default -> resolved
          const rawStatus = String(item.status ?? '').toLowerCase();
          const status: 'active' | 'resolved' = rawStatus === 'active' ? 'active' : rawStatus === 'resolved' ? 'resolved' : 'resolved';

          return { _id, type, sensor, location, status, timestamp };
        })
        .sort((a: AlertItem, b: AlertItem) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

      setAlerts(normalized);

      // Debug info: show normalized alerts and counts in console (dev only)
      try {
        // eslint-disable-next-line no-console
        console.debug('FireAlerts normalized:', normalized);
        // eslint-disable-next-line no-console
        console.debug('FireAlerts stats:', {
          total: normalized.length,
          active: normalized.filter((a: AlertItem) => a.status === 'active').length,
          recentFireActive: normalized.reduce((count: number, a: AlertItem) => {
            const now = Date.now();
            const t = new Date(a.timestamp).getTime();
            if (a.status !== 'active' || Number.isNaN(t) || now - t > RECENT_THRESHOLD_MS) return count;
            return String(a.type ?? '').toLowerCase().includes('fire') ? count + 1 : count;
          }, 0),
        });
      } catch (e) {
        // ignore debug errors
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load fire alerts');
      setAlerts([]);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  const resolveAlert = async (id: string) => {
    try {
      await axios.put(`${ALERTS_URL}/${id}/resolve`);
      await fetchAlerts(true);
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to resolve alert');
    }
  };

  const stats = useMemo(() => {
    const active = alerts.filter((a) => a.status === 'active').length;
    const resolved = alerts.filter((a) => a.status === 'resolved').length;
    return { active, resolved, total: alerts.length };
  }, [alerts]);

  // recentFireActiveCount not needed here; global overlay handles full-screen behavior

  useEffect(() => {
    fetchAlerts();
    const interval = window.setInterval(() => fetchAlerts(), 5000);
    return () => window.clearInterval(interval);
  }, [fetchAlerts]);

  // The global overlay handles full-screen fire alerts across the app.
  // Keep this page rendering its normal content; do not return a full-screen overlay here.

  return (
    <Box sx={{ p: { xs: 2, md: 3 } }}>

      <Stack
        direction={{ xs: 'column', md: 'row' }}
        spacing={1.5}
        alignItems={{ xs: 'flex-start', md: 'center' }}
        justifyContent="space-between"
        sx={{ mb: 3 }}
      >
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 900, letterSpacing: -0.6 }}>
            Fire Alerts
          </Typography>
          <Typography sx={{ color: 'text.secondary', fontWeight: 650, mt: 0.5 }}>
            Live fire incidents and alert history from the backend.
          </Typography>
        </Box>

        <Stack direction="row" spacing={1}>
          <Chip
            icon={<FireIcon />}
            label={`${stats.active} active`}
            sx={{ bgcolor: alpha(theme.palette.error.main, 0.14), color: theme.palette.error.light, fontWeight: 800 }}
          />
          <Button
            variant="contained"
            startIcon={<RefreshIcon />}
            onClick={() => fetchAlerts(true)}
            disabled={refreshing}
          >
            {refreshing ? 'Refreshing...' : 'Refresh'}
          </Button>
        </Stack>
      </Stack>

      {error ? (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      ) : null}

      <Grid container spacing={3} sx={{ mb: 1 }}>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Stack direction="row" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography sx={{ color: 'text.secondary', fontWeight: 900, fontSize: 12, letterSpacing: 0.8 }}>
                    ACTIVE ALERTS
                  </Typography>
                  <Typography sx={{ fontSize: 34, fontWeight: 1000, color: 'error.main', lineHeight: 1.1 }}>
                    {loading ? '—' : stats.active}
                  </Typography>
                </Box>
                <Box sx={{ width: 48, height: 48, borderRadius: 3, display: 'grid', placeItems: 'center', bgcolor: alpha(theme.palette.error.main, 0.12), color: 'error.main' }}>
                  <WarningIcon />
                </Box>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Stack direction="row" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography sx={{ color: 'text.secondary', fontWeight: 900, fontSize: 12, letterSpacing: 0.8 }}>
                    RESOLVED
                  </Typography>
                  <Typography sx={{ fontSize: 34, fontWeight: 1000, color: 'success.main', lineHeight: 1.1 }}>
                    {loading ? '—' : stats.resolved}
                  </Typography>
                </Box>
                <Box sx={{ width: 48, height: 48, borderRadius: 3, display: 'grid', placeItems: 'center', bgcolor: alpha(theme.palette.success.main, 0.12), color: 'success.main' }}>
                  <CheckIcon />
                </Box>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Stack direction="row" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography sx={{ color: 'text.secondary', fontWeight: 900, fontSize: 12, letterSpacing: 0.8 }}>
                    TOTAL RECORDS
                  </Typography>
                  <Typography sx={{ fontSize: 34, fontWeight: 1000, color: 'primary.main', lineHeight: 1.1 }}>
                    {loading ? '—' : stats.total}
                  </Typography>
                </Box>
                <Box sx={{ width: 48, height: 48, borderRadius: 3, display: 'grid', placeItems: 'center', bgcolor: alpha(theme.palette.primary.main, 0.10), color: 'primary.main' }}>
                  <FireIcon />
                </Box>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Card sx={{ overflow: 'hidden' }}>
        <CardContent sx={{ p: { xs: 2, md: 3 } }}>
          <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 2 }}>
            <Typography variant="h6" sx={{ fontWeight: 900 }}>
              Alert History
            </Typography>
            <Typography variant="body2" sx={{ color: 'text.secondary', fontWeight: 650 }}>
              Newest first
            </Typography>
          </Stack>

          <Divider sx={{ mb: 2.5 }} />

          {loading ? (
            <Box sx={{ display: 'grid', placeItems: 'center', minHeight: 240 }}>
              <CircularProgress />
            </Box>
          ) : alerts.length === 0 ? (
            <Box sx={{ minHeight: 260, display: 'grid', placeItems: 'center', textAlign: 'center', px: 2 }}>
              <Box>
                <Typography sx={{ fontSize: 52, lineHeight: 1 }}>🔥</Typography>
                <Typography sx={{ mt: 1.5, fontWeight: 900, fontSize: 20 }}>
                  No fire alerts yet ✅
                </Typography>
                <Typography sx={{ mt: 0.75, color: 'text.secondary', fontWeight: 600 }}>
                  When the backend receives a fire event, it will appear here automatically.
                </Typography>
              </Box>
            </Box>
          ) : (
            <Stack spacing={2}>
              {alerts.map((alert, index) => {
                const isActive = alert.status === 'active';
                const { date, time } = formatDateTime(alert.timestamp);

                return (
                  <motion.div
                    key={alert._id}
                    initial={{ opacity: 0, y: 14 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.28, delay: index * 0.03 }}
                  >
                    <Box
                      sx={{
                        borderRadius: 3,
                        p: 2.2,
                        bgcolor: isActive
                          ? alpha(theme.palette.error.main, 0.10)
                          : alpha(theme.palette.success.main, 0.08),
                        border: `1px solid ${isActive ? alpha(theme.palette.error.main, 0.20) : alpha(theme.palette.success.main, 0.20)}`,
                      }}
                    >
                      <Stack
                        direction={{ xs: 'column', md: 'row' }}
                        spacing={2}
                        alignItems={{ xs: 'flex-start', md: 'center' }}
                        justifyContent="space-between"
                      >
                        <Stack direction="row" spacing={2} alignItems="flex-start" sx={{ flex: 1, minWidth: 0 }}>
                          <Box
                            sx={{
                              width: 48,
                              height: 48,
                              borderRadius: 3,
                              display: 'grid',
                              placeItems: 'center',
                              bgcolor: isActive ? alpha(theme.palette.error.main, 0.16) : alpha(theme.palette.success.main, 0.14),
                              flexShrink: 0,
                            }}
                          >
                            <FireIcon sx={{ color: isActive ? 'error.main' : 'success.main' }} />
                          </Box>

                          <Box sx={{ minWidth: 0 }}>
                            <Typography sx={{ fontWeight: 900, fontSize: 18, mb: 0.5 }} noWrap>
                              FIRE DETECTED
                            </Typography>
                            <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
                              <Chip size="small" label={isActive ? 'Active' : 'Resolved'} color={isActive ? 'error' : 'success'} />
                              <Chip size="small" variant="outlined" label={`Sensor: ${alert.sensor}`} />
                              <Chip size="small" variant="outlined" label={alert.location} />
                            </Stack>
                            <Typography sx={{ mt: 1.2, color: 'text.secondary', fontWeight: 650 }}>
                              Date: {date} · Time: {time}
                            </Typography>
                          </Box>
                        </Stack>

                        {isActive ? (
                          <Button
                            variant="contained"
                            color="error"
                            onClick={() => resolveAlert(alert._id)}
                            sx={{ minWidth: 150, fontWeight: 800 }}
                          >
                            Resolve Alert
                          </Button>
                        ) : (
                          <Chip label="Acknowledged" color="success" />
                        )}
                      </Stack>
                    </Box>
                  </motion.div>
                );
              })}
            </Stack>
          )}
        </CardContent>
      </Card>
    </Box>
  );
}