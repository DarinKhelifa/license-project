import React, { useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import { Box, Button, Typography, useTheme } from '@mui/material';
import { motion } from 'framer-motion';

interface AlertItem {
  _id: string;
  type: string;
  sensor: string;
  location: string;
  status: 'active' | 'resolved';
  timestamp: string;
}

const API_BASE = (((globalThis as typeof globalThis & {
  process?: { env?: Record<string, string | undefined> };
}).process?.env?.REACT_APP_API_URL) || 'http://localhost:5000').replace(/\/api$/, '');
const ALERTS_URL = `${API_BASE}/api/iot/alerts`;

export default function GlobalFireOverlay() {
  const theme = useTheme();
  const [alerts, setAlerts] = useState<AlertItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [forceShow, setForceShow] = useState(false);

  const RECENT_THRESHOLD_MS = 5 * 60 * 1000; // 5 minutes

  const fetchAlerts = async (): Promise<AlertItem[]> => {
    try {
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
          const type = String(item.type ?? '');
          const sensor = String(item.sensor ?? '');
          const location = String(item.location ?? '');
          const timestamp = String(item.timestamp ?? item.createdAt ?? new Date().toISOString());
          const rawStatus = String(item.status ?? '').toLowerCase();
          const status: 'active' | 'resolved' = rawStatus === 'active' ? 'active' : rawStatus === 'resolved' ? 'resolved' : 'resolved';
          return { _id, type, sensor, location, status, timestamp };
        })
        .sort((a: AlertItem, b: AlertItem) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

      setAlerts(normalized);
      // eslint-disable-next-line no-console
      console.debug('GlobalFireOverlay.fetchAlerts ->', { count: normalized.length });
      return normalized;
    } catch (e: any) {
      // eslint-disable-next-line no-console
      console.error('GlobalFireOverlay.fetchAlerts error', e?.message || e);
      setAlerts([]);
      return [];
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    try {
      // eslint-disable-next-line no-console
      console.debug('GlobalFireOverlay: manual refresh button clicked');
      setForceShow(true);
      setRefreshing(true);
      
      const normalized = await fetchAlerts();
      // eslint-disable-next-line no-console
      console.debug('GlobalFireOverlay: refresh returned', { count: normalized.length });
      
      // compute recent fire count from returned data
      const now = Date.now();
      const recent = normalized.reduce((count, a) => {
        if (a.status !== 'active') return count;
        const t = new Date(a.timestamp).getTime();
        if (Number.isNaN(t)) return count;
        if (now - t > RECENT_THRESHOLD_MS) return count;
        return String(a.type ?? '').toLowerCase().includes('fire') ? count + 1 : count;
      }, 0);
      
      // eslint-disable-next-line no-console
      console.debug('GlobalFireOverlay: recent fire count after refresh', recent);
      
      if (recent === 0) {
        // hide immediately if no recent fire alerts reported
        setForceShow(false);
      } else {
        // keep the overlay visible while alerts still active
        setForceShow(true);
      }
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('GlobalFireOverlay.handleRefresh error', err);
    } finally {
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchAlerts();
    const interval = window.setInterval(() => fetchAlerts(), 5000);
    return () => window.clearInterval(interval);
  }, [setLoading, setAlerts]);

  const recentFireActiveCount = useMemo(() => {
    const now = Date.now();
    return alerts.reduce((count, a) => {
      if (a.status !== 'active') return count;
      const t = new Date(a.timestamp).getTime();
      if (Number.isNaN(t)) return count;
      if (now - t > RECENT_THRESHOLD_MS) return count;
      const type = String(a.type ?? '').toLowerCase();
      return type.includes('fire') ? count + 1 : count;
    }, 0);
  }, [alerts, RECENT_THRESHOLD_MS]);

  if (!forceShow && (loading || recentFireActiveCount === 0)) return null;

  return (
    <Box
      role="alert"
      aria-live="assertive"
      sx={{
        position: 'fixed',
        inset: 0,
        zIndex: theme.zIndex.modal + 30,
        bgcolor: '#cc0000',
        color: 'white',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        textAlign: 'center',
        px: 2,
        py: 4,
      }}
    >
      <Box>
        <motion.div animate={{ scale: [1, 1.15, 1] }} transition={{ duration: 0.6, repeat: Infinity }}>
          <Typography sx={{ fontSize: 120 }}>🔥</Typography>
        </motion.div>

        <Typography sx={{ fontSize: { xs: 32, md: 48 }, fontWeight: 900, mt: 2 }}>FIRE DETECTED!</Typography>
        <Typography sx={{ color: 'rgba(255,255,255,0.85)', mt: 1 }}>Immediate action required</Typography>
        <Typography sx={{ color: 'rgba(255,255,255,0.75)', mt: 1 }}>{recentFireActiveCount} active fire alert{recentFireActiveCount > 1 ? 's' : ''}</Typography>

        <Button
          variant="contained"
          onClick={handleRefresh}
          disabled={refreshing}
          sx={{
            mt: 3,
            bgcolor: 'white',
            color: '#cc0000',
            fontWeight: 800,
            pointerEvents: 'auto',
            cursor: refreshing ? 'wait' : 'pointer',
            '&:disabled': {
              opacity: 0.8,
            },
          }}
        >
          {refreshing ? 'Refreshing...' : 'Refresh Alerts'}
        </Button>
      </Box>
    </Box>
  );
}
