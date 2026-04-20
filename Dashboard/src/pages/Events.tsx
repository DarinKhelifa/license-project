import React, { useState, useEffect, useCallback } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Grid from '@mui/material/Grid';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import CardMedia from '@mui/material/CardMedia';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TextField from '@mui/material/TextField';
import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import Select from '@mui/material/Select';
import MenuItem from '@mui/material/MenuItem';
import Chip from '@mui/material/Chip';
import CircularProgress from '@mui/material/CircularProgress';
import Snackbar from '@mui/material/Snackbar';
import Alert from '@mui/material/Alert';
import Paper from '@mui/material/Paper';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import {
  CheckCircle as ApproveIcon,
  Cancel as RejectIcon,
  CalendarToday as CalendarIcon,
  LocationOn as LocationIcon,
  People as PeopleIcon,
  Info as InfoIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { motion, AnimatePresence } from 'framer-motion';
import { useAuth } from '../context/AuthContext';

const API_BASE = 'http://localhost:5000';

interface Event {
  _id: string;
  id: string;
  title: string;
  description: string;
  date: string;
  time: string;
  location: string;
  category: string;
  imageBase64?: string;
  capacity: number;
  currentRegistrations: number;
  status: 'pending' | 'approved' | 'rejected' | 'cancelled';
  createdBy: string;
  createdByName: string;
  createdAt: string;
  approvedBy?: string;
  approvedAt?: string;
  rejectionReason?: string;
}

const CATEGORY_COLORS: Record<string, { bg: string; color: string }> = {
  social: { bg: '#E3F2FD', color: '#1976D2' },
  sports: { bg: '#E8F5E9', color: '#388E3C' },
  educational: { bg: '#FFF3E0', color: '#F57C00' },
  workshop: { bg: '#F3E5F5', color: '#7B1FA2' },
  festival: { bg: '#FCE4EC', color: '#C2185B' },
  other: { bg: '#F5F5F5', color: '#616161' },
};

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`event-tabpanel-${index}`}
      aria-labelledby={`event-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ py: 3 }}>{children}</Box>}
    </div>
  );
}

export default function Events() {
  const { user } = useAuth();
  const [events, setEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(true);
  const [tabValue, setTabValue] = useState(0);
  const [selectedEvent, setSelectedEvent] = useState<Event | null>(null);
  const [rejectDialog, setRejectDialog] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');
  const [editDialog, setEditDialog] = useState(false);
  const [eventToEdit, setEventToEdit] = useState<Event | null>(null);
  const [editForm, setEditForm] = useState({
    title: '',
    description: '',
    date: '',
    time: '',
    location: '',
    category: 'social',
    capacity: 0,
  });
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

  const fetchEvents = useCallback(async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('auth_token');

      let eventsData: Event[] = [];

      if (user?.role === 'admin') {
        const pendingRes = await fetch(`${API_BASE}/api/events/admin/pending`, {
          headers: { 'Authorization': `Bearer ${token}` },
        });

        if (!pendingRes.ok) throw new Error('Failed to fetch pending events');
        const pendingData = await pendingRes.json();

        const allRes = await fetch(`${API_BASE}/api/events/admin/all`, {
          headers: { 'Authorization': `Bearer ${token}` },
        });

        if (!allRes.ok) throw new Error('Failed to fetch all events');
        const allData = await allRes.json();

        eventsData = [...pendingData, ...allData];
      } else {
        const myRes = await fetch(`${API_BASE}/api/events/my-events`, {
          headers: { 'Authorization': `Bearer ${token}` },
        });

        if (!myRes.ok) throw new Error('Failed to fetch my events');
        eventsData = await myRes.json();
      }

      setEvents(eventsData);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching events:', error);
      setSnackbar({ open: true, message: 'Failed to fetch events', severity: 'error' });
      setLoading(false);
    }
  }, [user]);

  // ── Fetch events ──────────────────────────────────────────────────────────
  useEffect(() => {
    if (user) {
      fetchEvents();
    }
  }, [user, fetchEvents]);

  // ── Approve event ─────────────────────────────────────────────────────────
  const handleApproveEvent = async (eventId: string) => {
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch(`${API_BASE}/api/events/admin/${eventId}/approve`, {
        method: 'PUT',
        headers: { 'Authorization': `Bearer ${token}` },
      });

      if (!response.ok) throw new Error('Failed to approve event');

      setSnackbar({ open: true, message: 'Event approved successfully', severity: 'success' });
      fetchEvents();
    } catch (error) {
      console.error('Error approving event:', error);
      setSnackbar({ open: true, message: 'Failed to approve event', severity: 'error' });
    }
  };

  // ── Reject event ──────────────────────────────────────────────────────────
  const handleRejectEvent = async () => {
    if (!selectedEvent) return;

    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch(`${API_BASE}/api/events/admin/${selectedEvent.id}/reject`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ reason: rejectionReason }),
      });

      if (!response.ok) throw new Error('Failed to reject event');

      setSnackbar({ open: true, message: 'Event rejected successfully', severity: 'success' });
      setRejectDialog(false);
      setRejectionReason('');
      setSelectedEvent(null);
      fetchEvents();
    } catch (error) {
      console.error('Error rejecting event:', error);
      setSnackbar({ open: true, message: 'Failed to reject event', severity: 'error' });
    }
  };

  const handleDeleteEvent = async (eventId: string) => {
    const confirmed = window.confirm('Are you sure you want to delete this event? This action cannot be undone.');
    if (!confirmed) return;

    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch(`${API_BASE}/api/events/${eventId}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` },
      });

      if (!response.ok) throw new Error('Failed to delete event');

      setSnackbar({ open: true, message: 'Event deleted successfully', severity: 'success' });
      fetchEvents();
    } catch (error) {
      console.error('Error deleting event:', error);
      setSnackbar({ open: true, message: 'Failed to delete event', severity: 'error' });
    }
  };

  const handleSaveEventChanges = async () => {
    if (!eventToEdit) return;

    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch(`${API_BASE}/api/events/${eventToEdit.id}`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(editForm),
      });

      if (!response.ok) throw new Error('Failed to update event');

      setSnackbar({ open: true, message: 'Event updated successfully', severity: 'success' });
      setEditDialog(false);
      setEventToEdit(null);
      fetchEvents();
    } catch (error) {
      console.error('Error updating event:', error);
      setSnackbar({ open: true, message: 'Failed to update event', severity: 'error' });
    }
  };

  // ── Filter events by status ───────────────────────────────────────────────
  const pendingEvents = events.filter((e) => e.status === 'pending');
  const approvedEvents = events.filter((e) => e.status === 'approved');
  const rejectedEvents = events.filter((e) => e.status === 'rejected');
  const allStatusEvents = events;

  // ── Render event card ─────────────────────────────────────────────────────
  const renderEventCard = (event: Event) => {
    const catColor = CATEGORY_COLORS[event.category] ?? CATEGORY_COLORS.other;
    const eventDate = new Date(event.date).toLocaleDateString('en-GB', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
    const imageUrl = event.imageBase64 ? `data:image/jpeg;base64,${event.imageBase64}` : null;

    return (
      <motion.div
        key={event._id}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -20 }}
      >
        <Card
          sx={{
            height: '100%',
            display: 'flex',
            flexDirection: 'column',
            borderRadius: 2,
            overflow: 'hidden',
            boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
            transition: 'all 0.3s ease',
            '&:hover': {
              boxShadow: '0 8px 24px rgba(0,0,0,0.15)',
              transform: 'translateY(-4px)',
            },
          }}
        >
          {imageUrl && (
            <CardMedia
              component="img"
              height="200"
              image={imageUrl}
              alt={event.title}
              sx={{ objectFit: 'cover' }}
            />
          )}
          <CardContent sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1 }}>
              <Typography variant="h6" sx={{ fontWeight: 600, color: '#034808', flex: 1 }}>
                {event.title}
              </Typography>
              <Chip
                label={event.status}
                size="small"
                sx={{
                  bgcolor: event.status === 'pending' ? '#FFC107' : event.status === 'approved' ? '#4CAF50' : '#F44336',
                  color: 'white',
                  fontWeight: 600,
                  textTransform: 'capitalize',
                  ml: 1,
                }}
              />
            </Box>

            <Chip
              label={event.category}
              size="small"
              sx={{ bgcolor: catColor.bg, color: catColor.color, mb: 2, width: 'fit-content' }}
            />

            <Typography variant="body2" color="text.secondary" sx={{ mb: 2, flex: 1 }}>
              {event.description.substring(0, 100)}...
            </Typography>

            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1, mb: 2, fontSize: '0.875rem' }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <CalendarIcon sx={{ fontSize: 18, color: '#034808' }} />
                <span>
                  {eventDate} at {event.time}
                </span>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <LocationIcon sx={{ fontSize: 18, color: '#034808' }} />
                <span>{event.location}</span>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <PeopleIcon sx={{ fontSize: 18, color: '#034808' }} />
                <span>
                  {event.currentRegistrations} / {event.capacity} registered
                </span>
              </Box>
            </Box>

            <Typography variant="caption" color="text.secondary" sx={{ mb: 2 }}>
              Created by: <strong>{event.createdByName}</strong> on{' '}
              {new Date(event.createdAt).toLocaleDateString()}
            </Typography>

            {event.status === 'pending' && (
              <Box sx={{ display: 'flex', gap: 1, mt: 'auto', flexWrap: 'wrap' }}>
                {user?.role === 'admin' && (
                  <>
                    <Button
                      variant="contained"
                      size="small"
                      startIcon={<ApproveIcon />}
                      onClick={() => handleApproveEvent(event.id)}
                      sx={{ bgcolor: '#4CAF50', '&:hover': { bgcolor: '#45a049' } }}
                    >
                      Approve
                    </Button>
                    <Button
                      variant="contained"
                      size="small"
                      startIcon={<RejectIcon />}
                      onClick={() => {
                        setSelectedEvent(event);
                        setRejectDialog(true);
                      }}
                      sx={{ bgcolor: '#F44336', '&:hover': { bgcolor: '#da190b' } }}
                    >
                      Reject
                    </Button>
                  </>
                )}
                {event.createdBy === user?.id && (
                  <>
                    <Button
                      variant="outlined"
                      size="small"
                      startIcon={<EditIcon />}
                      onClick={() => {
                        setEventToEdit(event);
                        setEditForm({
                          title: event.title,
                          description: event.description,
                          date: event.date.slice(0, 10),
                          time: event.time,
                          location: event.location,
                          category: event.category,
                          capacity: event.capacity,
                        });
                        setEditDialog(true);
                      }}
                      sx={{ borderColor: '#1976D2', color: '#1976D2' }}
                    >
                      Edit
                    </Button>
                    <Button
                      variant="outlined"
                      size="small"
                      startIcon={<DeleteIcon />}
                      onClick={() => handleDeleteEvent(event.id)}
                      sx={{ borderColor: '#F44336', color: '#F44336' }}
                    >
                      Delete
                    </Button>
                  </>
                )}
              </Box>
            )}

            {event.status === 'rejected' && event.rejectionReason && (
              <Paper sx={{ p: 1.5, bgcolor: '#FFEBEE', borderRadius: 1, mt: 'auto' }}>
                <Box sx={{ display: 'flex', gap: 1 }}>
                  <InfoIcon sx={{ color: '#F44336', fontSize: 18 }} />
                  <Box>
                    <Typography variant="caption" sx={{ color: '#F44336', fontWeight: 600 }}>
                      Rejection Reason:
                    </Typography>
                    <Typography variant="caption" sx={{ color: '#F44336', display: 'block' }}>
                      {event.rejectionReason}
                    </Typography>
                  </Box>
                </Box>
              </Paper>
            )}

            {event.status === 'approved' && event.approvedAt && (
              <Typography variant="caption" color="success.main" sx={{ mt: 'auto' }}>
                ✓ Approved on {new Date(event.approvedAt).toLocaleDateString()}
              </Typography>
            )}
          </CardContent>
        </Card>
      </motion.div>
    );
  };

  return (
    <Box>
      <Typography variant="h4" sx={{ color: '#034808', mb: 4, fontWeight: 700 }}>
        Manage Events
      </Typography>

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
          <CircularProgress />
        </Box>
      ) : (
        <>
          <Paper sx={{ mb: 3, borderRadius: 2 }}>
            <Tabs
              value={tabValue}
              onChange={(e, newValue) => setTabValue(newValue)}
              indicatorColor="primary"
              textColor="inherit"
              sx={{
                bgcolor: '#F5F5F5',
                '& .MuiTabs-indicator': { bgcolor: '#034808', height: 3 },
              }}
            >
              <Tab label={`Pending (${pendingEvents.length})`} />
              <Tab label={`Approved (${approvedEvents.length})`} />
              <Tab label={`Rejected (${rejectedEvents.length})`} />
              <Tab label={`All Events (${allStatusEvents.length})`} />
            </Tabs>
          </Paper>

          <AnimatePresence>
            <TabPanel value={tabValue} index={0}>
              {pendingEvents.length === 0 ? (
                <Paper
                  sx={{
                    p: 6,
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    textAlign: 'center',
                  }}
                >
                  <Typography variant="h6" color="text.secondary">
                    No pending events
                  </Typography>
                </Paper>
              ) : (
                <Grid container spacing={3}>
                  {pendingEvents.map((event) => (
                    <Grid item xs={12} sm={6} md={4} key={event._id}>
                      {renderEventCard(event)}
                    </Grid>
                  ))}
                </Grid>
              )}
            </TabPanel>

            <TabPanel value={tabValue} index={1}>
              {approvedEvents.length === 0 ? (
                <Paper
                  sx={{
                    p: 6,
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    textAlign: 'center',
                  }}
                >
                  <Typography variant="h6" color="text.secondary">
                    No approved events
                  </Typography>
                </Paper>
              ) : (
                <Grid container spacing={3}>
                  {approvedEvents.map((event) => (
                    <Grid item xs={12} sm={6} md={4} key={event._id}>
                      {renderEventCard(event)}
                    </Grid>
                  ))}
                </Grid>
              )}
            </TabPanel>

            <TabPanel value={tabValue} index={2}>
              {rejectedEvents.length === 0 ? (
                <Paper
                  sx={{
                    p: 6,
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    textAlign: 'center',
                  }}
                >
                  <Typography variant="h6" color="text.secondary">
                    No rejected events
                  </Typography>
                </Paper>
              ) : (
                <Grid container spacing={3}>
                  {rejectedEvents.map((event) => (
                    <Grid item xs={12} sm={6} md={4} key={event._id}>
                      {renderEventCard(event)}
                    </Grid>
                  ))}
                </Grid>
              )}
            </TabPanel>

            <TabPanel value={tabValue} index={3}>
              {allStatusEvents.length === 0 ? (
                <Paper
                  sx={{
                    p: 6,
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    textAlign: 'center',
                  }}
                >
                  <Typography variant="h6" color="text.secondary">
                    No events
                  </Typography>
                </Paper>
              ) : (
                <Grid container spacing={3}>
                  {allStatusEvents.map((event) => (
                    <Grid item xs={12} sm={6} md={4} key={event._id}>
                      {renderEventCard(event)}
                    </Grid>
                  ))}
                </Grid>
              )}
            </TabPanel>
          </AnimatePresence>
        </>
      )}

      {/* Rejection reason dialog */}
      <Dialog open={rejectDialog} onClose={() => setRejectDialog(false)} fullWidth maxWidth="sm">
        <DialogTitle sx={{ color: '#034808', fontWeight: 600 }}>
          Reject Event
        </DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Please provide a reason for rejecting this event:
          </Typography>
          <TextField
            fullWidth
            multiline
            rows={4}
            placeholder="Reason for rejection..."
            value={rejectionReason}
            onChange={(e) => setRejectionReason(e.target.value)}
            variant="outlined"
          />
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setRejectDialog(false)}>Cancel</Button>
          <Button
            onClick={handleRejectEvent}
            variant="contained"
            sx={{ bgcolor: '#F44336', '&:hover': { bgcolor: '#da190b' } }}
            disabled={!rejectionReason.trim()}
          >
            Reject
          </Button>
        </DialogActions>
      </Dialog>

      <Dialog open={editDialog} onClose={() => setEditDialog(false)} fullWidth maxWidth="sm">
        <DialogTitle sx={{ color: '#034808', fontWeight: 600 }}>
          Edit Event
        </DialogTitle>
        <DialogContent sx={{ pt: 2, display: 'grid', gap: 2 }}>
          <TextField
            label="Title"
            fullWidth
            value={editForm.title}
            onChange={(e) => setEditForm({ ...editForm, title: e.target.value })}
          />
          <TextField
            label="Description"
            fullWidth
            multiline
            rows={4}
            value={editForm.description}
            onChange={(e) => setEditForm({ ...editForm, description: e.target.value })}
          />
          <TextField
            label="Location"
            fullWidth
            value={editForm.location}
            onChange={(e) => setEditForm({ ...editForm, location: e.target.value })}
          />
          <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2 }}>
            <TextField
              label="Date"
              fullWidth
              type="date"
              value={editForm.date}
              onChange={(e) => setEditForm({ ...editForm, date: e.target.value })}
              InputLabelProps={{ shrink: true }}
            />
            <TextField
              label="Time"
              fullWidth
              type="time"
              value={editForm.time}
              onChange={(e) => setEditForm({ ...editForm, time: e.target.value })}
              InputLabelProps={{ shrink: true }}
            />
          </Box>
          <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2 }}>
            <FormControl fullWidth>
              <InputLabel id="edit-category-label">Category</InputLabel>
              <Select
                labelId="edit-category-label"
                value={editForm.category}
                label="Category"
                onChange={(e) => setEditForm({ ...editForm, category: e.target.value })}
              >
                <MenuItem value="social">Social</MenuItem>
                <MenuItem value="sports">Sports</MenuItem>
                <MenuItem value="educational">Educational</MenuItem>
                <MenuItem value="workshop">Workshop</MenuItem>
                <MenuItem value="festival">Festival</MenuItem>
                <MenuItem value="other">Other</MenuItem>
              </Select>
            </FormControl>
            <TextField
              label="Capacity"
              fullWidth
              type="number"
              value={editForm.capacity}
              onChange={(e) => setEditForm({ ...editForm, capacity: Number(e.target.value) })}
            />
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setEditDialog(false)}>Cancel</Button>
          <Button
            onClick={handleSaveEventChanges}
            variant="contained"
            sx={{ bgcolor: '#034808', '&:hover': { bgcolor: '#022205' } }}
          >
            Save Changes
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar notification */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
      >
        <Alert
          onClose={() => setSnackbar({ ...snackbar, open: false })}
          severity={snackbar.severity}
          sx={{ width: '100%' }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
