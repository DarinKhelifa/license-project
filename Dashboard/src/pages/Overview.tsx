import React, { useEffect, useMemo, useState } from 'react';
import { alpha, useTheme } from '@mui/material/styles';
import {
  Alert,
  Box,
  Card,
  CardContent,
  Chip,
  Grid,
  Skeleton,
  Stack,
  Typography,
} from '@mui/material';
import {
  FlashOn as FlashOnIcon,
  People as PeopleIcon,
  Security as SecurityIcon,
  Event as EventIcon,
  Badge as BadgeIcon,
  TrendingUp as TrendingUpIcon,
} from '@mui/icons-material';
import { motion } from 'framer-motion';
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

import { useAuth } from '../context/AuthContext';
import { adminAPI } from '../services/api';
import { dashboardAPI, EventDTO, ReportDTO } from '../services/dashboard';

type OverviewStat = {
  title: string;
  value: string;
  caption?: string;
  icon: React.ReactNode;
  tone: 'primary' | 'secondary';
};

function formatNumber(n: number) {
  return new Intl.NumberFormat().format(n);
}

function formatHour(h: number) {
  return `${String(h).padStart(2, '0')}h`;
}

export default function Overview() {
  const theme = useTheme();
  const { user } = useAuth();

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [reports, setReports] = useState<ReportDTO[]>([]);
  const [events, setEvents] = useState<EventDTO[]>([]);
  const [myEvents, setMyEvents] = useState<EventDTO[]>([]);
  const [pendingEvents, setPendingEvents] = useState<EventDTO[]>([]);
  const [employeesCount, setEmployeesCount] = useState<number>(0);
  const [usersCount, setUsersCount] = useState<number | null>(null);
  const [activeResidentsCount, setActiveResidentsCount] = useState<number | null>(null);

  const [energyChart, setEnergyChart] = useState<Array<{ hour: number; average: number }>>([]);
  const [energySummary, setEnergySummary] = useState<{ total: number; average: number; peak: number } | null>(null);

  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      setError(null);

      try {
        const role = user?.role;

        const employeesPromise = dashboardAPI.employees
          .list()
          .then((list) => list.length)
          .catch(() => 0);

        const energyPromise = dashboardAPI.energy
          .historical({ days: 7 })
          .catch(() => ({ chartData: [], summary: { total: 0, average: 0, peak: 0 } }));

        const reportsPromise =
          role === 'admin' || role === 'security' || role === 'maintenance'
            ? dashboardAPI.reports.allForStaff()
            : dashboardAPI.reports.my();

        const eventsPromise = dashboardAPI.events.approvedUpcoming().catch(() => []);
        const myEventsPromise = role === 'resident' ? dashboardAPI.events.my().catch(() => []) : Promise.resolve([]);

        const pendingEventsPromise = role === 'admin' ? dashboardAPI.events.pendingAdmin() : Promise.resolve([]);

        const usersPromise = role === 'admin' ? adminAPI.getAllUsers().catch(() => []) : Promise.resolve(null);

        const [employeesTotal, energyRes, reportsRes, eventsRes, myEventsRes, pendingRes, usersRes] = await Promise.all([
          employeesPromise,
          energyPromise,
          reportsPromise,
          eventsPromise,
          myEventsPromise,
          pendingEventsPromise,
          usersPromise,
        ]);

        if (cancelled) return;

        setEmployeesCount(employeesTotal);
        setEnergyChart(energyRes.chartData ?? []);
        setEnergySummary(energyRes.summary ?? null);

        setReports(reportsRes ?? []);
        setEvents(eventsRes ?? []);
        setMyEvents(myEventsRes ?? []);
        setPendingEvents(pendingRes ?? []);

        if (usersRes && Array.isArray(usersRes)) {
          setUsersCount(usersRes.length);
          const activeResidents = usersRes.filter((u) => u.role === 'resident' && u.status === 'active').length;
          setActiveResidentsCount(activeResidents);
        } else {
          setUsersCount(null);
          setActiveResidentsCount(null);
        }
      } catch (e: any) {
        if (cancelled) return;
        setError(e?.message ?? 'Failed to load overview data');
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    load();
    return () => {
      cancelled = true;
    };
  }, [user?.role]);

  const reportCounts = useMemo(() => {
    const counts = { pending: 0, inProgress: 0, resolved: 0, rejected: 0 };
    for (const r of reports) {
      if (r.status === 'pending') counts.pending++;
      else if (r.status === 'in-progress') counts.inProgress++;
      else if (r.status === 'resolved') counts.resolved++;
      else if (r.status === 'rejected') counts.rejected++;
    }
    return counts;
  }, [reports]);

  const recentActivity = useMemo(() => {
    const items: Array<{ type: 'report' | 'event'; title: string; subtitle: string; createdAt: string }> = [];

    for (const r of reports.slice(0, 50)) {
      items.push({
        type: 'report',
        title: `${r.category} report · ${r.subCategory}`,
        subtitle: `${r.location} · ${r.status}`,
        createdAt: r.createdAt,
      });
    }

    const eventsForActivity = user?.role === 'resident' ? myEvents : events;
    for (const e of eventsForActivity.slice(0, 50)) {
      items.push({
        type: 'event',
        title: `Event · ${e.title}`,
        subtitle: `${new Date(e.date).toLocaleDateString()} · ${e.location}`,
        createdAt: e.createdAt,
      });
    }

    return items
      .filter((x) => Boolean(x.createdAt))
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(0, 6);
  }, [events, myEvents, reports, user?.role]);

  const stats: OverviewStat[] = useMemo(() => {
    const role = user?.role;

    const base: OverviewStat[] = [];

    if (role === 'admin') {
      base.push({
        title: 'Active residents',
        value: loading ? '—' : formatNumber(activeResidentsCount ?? 0),
        caption: usersCount != null ? `${formatNumber(usersCount)} total users` : undefined,
        icon: <PeopleIcon />,
        tone: 'primary',
      });
      base.push({
        title: 'Pending events',
        value: loading ? '—' : formatNumber(pendingEvents.length),
        caption: `${formatNumber(events.length)} approved upcoming`,
        icon: <EventIcon />,
        tone: 'secondary',
      });
    } else {
      base.push({
        title: role === 'resident' ? 'My reports' : 'Reports',
        value: loading ? '—' : formatNumber(reports.length),
        caption: `${formatNumber(reportCounts.pending + reportCounts.inProgress)} open`,
        icon: <SecurityIcon />,
        tone: 'primary',
      });
      base.push({
        title: role === 'resident' ? 'My events' : 'Upcoming events',
        value: loading ? '—' : formatNumber(role === 'resident' ? myEvents.length : events.length),
        caption: role === 'resident' ? `${formatNumber(events.length)} approved upcoming` : 'Approved only',
        icon: <EventIcon />,
        tone: 'secondary',
      });
    }

    base.push({
      title: 'Employees',
      value: loading ? '—' : formatNumber(employeesCount),
      caption: 'Service staff',
      icon: <BadgeIcon />,
      tone: 'primary',
    });

    base.push({
      title: 'Energy avg',
      value: loading ? '—' : formatNumber(Math.round(energySummary?.average ?? 0)),
      caption: 'Last 7 days (avg/hour)',
      icon: <FlashOnIcon />,
      tone: 'secondary',
    });

    return base;
  }, [activeResidentsCount, employeesCount, energySummary?.average, events.length, loading, myEvents.length, pendingEvents.length, reportCounts.inProgress, reportCounts.pending, reports.length, user?.role, usersCount]);

  return (
    <Box>
      <Stack direction={{ xs: 'column', md: 'row' }} spacing={1.5} alignItems={{ xs: 'flex-start', md: 'center' }} sx={{ mb: 3 }}>
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Typography variant="h4" sx={{ mb: 0.4 }}>
            Dashboard
          </Typography>
          <Typography sx={{ color: 'text.secondary', fontWeight: 650 }}>
            Live status from your Orelax backend (reports, events, employees, energy).
          </Typography>
        </Box>
        {user?.role ? (
          <Chip
            icon={<TrendingUpIcon />}
            label={`Role: ${String(user.role).toUpperCase()}`}
            sx={{
              bgcolor: alpha(theme.palette.primary.main, 0.06),
              border: `1px solid ${alpha(theme.palette.primary.main, 0.12)}`,
              fontWeight: 900,
            }}
          />
        ) : null}
      </Stack>

      {error ? <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert> : null}

      <Grid container spacing={3}>
        {stats.map((s, idx) => (
          <Grid item xs={12} sm={6} md={3} key={s.title}>
            <motion.div
              initial={{ opacity: 0, y: 14 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.35, delay: idx * 0.05 }}
            >
              <Card>
                <CardContent sx={{ p: 2.7 }}>
                  <Stack direction="row" spacing={2} alignItems="flex-start" justifyContent="space-between">
                    <Box sx={{ minWidth: 0 }}>
                      <Typography sx={{ color: 'text.secondary', fontWeight: 900, fontSize: 12, letterSpacing: 0.8, textTransform: 'uppercase' }}>
                        {s.title}
                      </Typography>
                      {loading ? (
                        <Skeleton width={120} height={44} />
                      ) : (
                        <Typography sx={{ mt: 0.6, fontSize: 34, fontWeight: 1000, color: 'primary.main', lineHeight: 1 }}>
                          {s.value}
                        </Typography>
                      )}
                      {s.caption ? (
                        <Typography sx={{ mt: 0.9, color: 'text.secondary', fontWeight: 650 }} noWrap>
                          {s.caption}
                        </Typography>
                      ) : null}
                    </Box>

                    <Box
                      sx={{
                        width: 48,
                        height: 48,
                        borderRadius: 3,
                        display: 'grid',
                        placeItems: 'center',
                        color: s.tone === 'secondary' ? theme.palette.secondary.main : theme.palette.primary.main,
                        bgcolor:
                          s.tone === 'secondary'
                            ? alpha(theme.palette.secondary.main, 0.16)
                            : alpha(theme.palette.primary.main, 0.10),
                        border:
                          s.tone === 'secondary'
                            ? `1px solid ${alpha(theme.palette.secondary.main, 0.24)}`
                            : `1px solid ${alpha(theme.palette.primary.main, 0.12)}`,
                      }}
                    >
                      {React.cloneElement(s.icon as any, { fontSize: 'medium' })}
                    </Box>
                  </Stack>
                </CardContent>
              </Card>
            </motion.div>
          </Grid>
        ))}

        <Grid item xs={12} md={8}>
          <Card sx={{ height: '100%' }}>
            <CardContent sx={{ p: 3 }}>
              <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 2.2 }}>
                <FlashOnIcon sx={{ color: 'secondary.main' }} />
                <Typography variant="h6">Energy (avg by hour)</Typography>
                <Box sx={{ flex: 1 }} />
                {energySummary ? (
                  <Chip
                    size="small"
                    label={`Peak: ${formatNumber(Math.round(energySummary.peak))}`}
                    sx={{ bgcolor: alpha(theme.palette.primary.main, 0.06), fontWeight: 850 }}
                  />
                ) : null}
              </Stack>

              <Box sx={{ height: 320 }}>
                {loading ? (
                  <Skeleton variant="rounded" height={320} />
                ) : energyChart.length === 0 ? (
                  <Box sx={{ height: 320, display: 'grid', placeItems: 'center', color: 'text.secondary' }}>
                    <Typography sx={{ fontWeight: 750 }}>
                      No energy readings yet.
                    </Typography>
                    <Typography variant="body2" sx={{ mt: 0.6 }}>
                      When devices publish MQTT readings, this chart will populate automatically.
                    </Typography>
                  </Box>
                ) : (
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={energyChart} margin={{ top: 10, right: 10, left: -16, bottom: 0 }}>
                      <defs>
                        <linearGradient id="energyFill" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor={theme.palette.primary.main} stopOpacity={0.22} />
                          <stop offset="95%" stopColor={theme.palette.primary.main} stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={alpha(theme.palette.common.white, 0.10)} />
                      <XAxis
                        dataKey="hour"
                        axisLine={false}
                        tickLine={false}
                        tick={{ fill: alpha(theme.palette.text.primary, 0.75), fontSize: 12 }}
                        tickFormatter={formatHour}
                        dy={10}
                      />
                      <YAxis
                        axisLine={false}
                        tickLine={false}
                        tick={{ fill: alpha(theme.palette.text.primary, 0.75), fontSize: 12 }}
                      />
                      <Tooltip
                        contentStyle={{
                          borderRadius: 14,
                          border: `1px solid ${alpha(theme.palette.common.white, 0.10)}`,
                          backgroundColor: alpha(theme.palette.background.paper, 0.92),
                          color: theme.palette.text.primary,
                        }}
                        cursor={{ stroke: theme.palette.primary.main, strokeWidth: 1, strokeDasharray: '4 4' }}
                        labelFormatter={(label) => formatHour(Number(label))}
                      />
                      <Area
                        type="monotone"
                        dataKey="average"
                        stroke={theme.palette.primary.main}
                        strokeWidth={3}
                        fill="url(#energyFill)"
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                )}
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card sx={{ height: '100%' }}>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" sx={{ mb: 2 }}>
                Recent activity
              </Typography>
              {loading ? (
                <Stack spacing={1.2}>
                  <Skeleton height={56} />
                  <Skeleton height={56} />
                  <Skeleton height={56} />
                </Stack>
              ) : recentActivity.length === 0 ? (
                <Typography sx={{ color: 'text.secondary', fontWeight: 650 }}>
                  No recent activity yet.
                </Typography>
              ) : (
                <Stack spacing={1.2}>
                  {recentActivity.map((a, idx) => (
                    <Box
                      key={`${a.type}-${idx}`}
                      sx={{
                        p: 1.4,
                        borderRadius: 3,
                        border: `1px solid ${alpha(theme.palette.common.white, 0.10)}`,
                        bgcolor: alpha(theme.palette.background.paper, 0.55),
                      }}
                    >
                      <Stack direction="row" spacing={1.2} alignItems="center">
                        <Box
                          sx={{
                            width: 34,
                            height: 34,
                            borderRadius: 2.5,
                            display: 'grid',
                            placeItems: 'center',
                            bgcolor: a.type === 'report' ? alpha(theme.palette.secondary.main, 0.18) : alpha(theme.palette.primary.main, 0.10),
                            color: a.type === 'report' ? theme.palette.secondary.main : theme.palette.primary.main,
                          }}
                        >
                          {a.type === 'report' ? <SecurityIcon fontSize="small" /> : <EventIcon fontSize="small" />}
                        </Box>
                        <Box sx={{ minWidth: 0, flex: 1 }}>
                          <Typography sx={{ fontWeight: 900 }} noWrap>
                            {a.title}
                          </Typography>
                          <Typography sx={{ color: 'text.secondary', fontWeight: 650 }} noWrap>
                            {a.subtitle}
                          </Typography>
                        </Box>
                      </Stack>
                    </Box>
                  ))}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}