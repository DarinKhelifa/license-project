import React, { useEffect, useState, useMemo } from 'react';
import { Box, Button, Card, CardContent, Divider, IconButton, List, ListItem, ListItemAvatar, Avatar, ListItemText, Typography, Stack, Pagination, CircularProgress } from '@mui/material';
import { Delete as DeleteIcon, MarkEmailRead as MarkReadIcon, Notifications as NotificationsIcon } from '@mui/icons-material';
import { useAuth } from '../context/AuthContext';
import { notificationsAPI, NotificationItem } from '../services/notifications';
import { formatDistanceToNow } from 'date-fns';

const PAGE_SIZE = 12;

export default function Notifications() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [page, setPage] = useState(1);

  const fetchNotifications = async () => {
    if (!user?.id) return;
    setLoading(true);
    try {
      const res = await notificationsAPI.list(user.id);
      if (res && res.success) setNotifications(res.notifications ?? []);
    } catch (err) {
      console.error('fetchNotifications error', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotifications();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user?.id]);

  const pageCount = useMemo(() => Math.max(1, Math.ceil(notifications.length / PAGE_SIZE)), [notifications.length]);

  const visible = useMemo(() => {
    const start = (page - 1) * PAGE_SIZE;
    return notifications.slice(start, start + PAGE_SIZE);
  }, [notifications, page]);

  const handleMarkAll = async () => {
    if (!user?.id) return;
    try {
      await notificationsAPI.markAllRead(user.id);
      setNotifications((prev) => prev.map((n) => ({ ...n, isRead: true })));
    } catch (err) {
      console.error('markAll error', err);
    }
  };

  const handleMarkRead = async (id?: string) => {
    if (!id) return;
    try {
      await notificationsAPI.markRead(id);
      setNotifications((prev) => prev.map((n) => (n._id === id ? { ...n, isRead: true } : n)));
    } catch (err) {
      console.error('markRead error', err);
    }
  };

  const handleDelete = async (id?: string) => {
    if (!id) return;
    try {
      await notificationsAPI.delete(id);
      setNotifications((prev) => prev.filter((n) => n._id !== id));
    } catch (err) {
      console.error('delete error', err);
    }
  };

  if (loading) return <Box sx={{ display: 'grid', placeItems: 'center', py: 8 }}><CircularProgress /></Box>;

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <NotificationsIcon />
          <Typography variant="h5" sx={{ fontWeight: 800 }}>Notifications</Typography>
        </Box>
        <Box>
          <Button variant="outlined" onClick={fetchNotifications} sx={{ mr: 1 }}>Refresh</Button>
          <Button variant="contained" onClick={handleMarkAll}>Mark all read</Button>
        </Box>
      </Stack>

      {notifications.length === 0 ? (
        <Card>
          <CardContent>
            <Typography>No notifications yet.</Typography>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent>
            <List>
              {visible.map((n) => (
                <React.Fragment key={n._id}>
                  <ListItem sx={{ bgcolor: n.isRead ? 'transparent' : (theme) => theme.palette.action.hover }} secondaryAction={(
                    <Stack direction="row" spacing={1}>
                      <IconButton edge="end" aria-label="mark-read" onClick={() => handleMarkRead(n._id)}>
                        <MarkReadIcon fontSize="small" />
                      </IconButton>
                      <IconButton edge="end" aria-label="delete" onClick={() => handleDelete(n._id)}>
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </Stack>
                  )}>
                    <ListItemAvatar>
                      <Avatar>{(n.type?.[0] ?? 'N').toUpperCase()}</Avatar>
                    </ListItemAvatar>
                    <ListItemText
                      primary={<Typography sx={{ fontWeight: 700 }}>{n.title ?? 'Notification'}</Typography>}
                      secondary={<>
                        <Typography component="span" variant="body2" color="text.primary">{n.message ?? (n as any).body ?? ''}</Typography>
                        <Typography variant="caption" display="block" color="text.secondary">{n.createdAt ? formatDistanceToNow(new Date(n.createdAt), { addSuffix: true }) : ''}</Typography>
                      </>}
                    />
                  </ListItem>
                  <Divider />
                </React.Fragment>
              ))}
            </List>

            <Box sx={{ display: 'flex', justifyContent: 'center', mt: 2 }}>
              <Pagination count={pageCount} page={page} onChange={(e, p) => setPage(p)} color="primary" />
            </Box>
          </CardContent>
        </Card>
      )}
    </Box>
  );
}
