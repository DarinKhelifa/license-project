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
import Select from '@mui/material/Select';
import MenuItem from '@mui/material/MenuItem';
import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import Chip from '@mui/material/Chip';
import CircularProgress from '@mui/material/CircularProgress';
import Snackbar from '@mui/material/Snackbar';
import Alert from '@mui/material/Alert';
import Paper from '@mui/material/Paper';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import {
  Edit as EditIcon,
  LocationOn as LocationIcon,
} from '@mui/icons-material';
import { motion, AnimatePresence } from 'framer-motion';

const API_BASE = 'http://localhost:5000';

interface ReportItem {
  _id: string;
  id: string;
  category: string;
  subCategory: string;
  location: string;
  description: string;
  photoBase64?: string;
  status: 'pending' | 'in-progress' | 'resolved' | 'rejected';
  createdBy: string;
  createdByName: string;
  createdAt: string;
  resolvedAt?: string;
  resolvedBy?: string;
  resolutionNotes?: string;
  timeIsNow: boolean;
  customTime?: string;
}

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
      id={`report-tabpanel-${index}`}
      aria-labelledby={`report-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ py: 3 }}>{children}</Box>}
    </div>
  );
}

const STATUS_COLORS: Record<string, { bg: string; color: string }> = {
  pending: { bg: '#FFC107', color: '#333' },
  'in-progress': { bg: '#2196F3', color: 'white' },
  resolved: { bg: '#4CAF50', color: 'white' },
  rejected: { bg: '#F44336', color: 'white' },
};

export default function Report() {
  const [reports, setReports] = useState<ReportItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [tabValue, setTabValue] = useState(0);
  const [selectedReport, setSelectedReport] = useState<ReportItem | null>(null);
  const [statusDialog, setStatusDialog] = useState(false);
  const [newStatus, setNewStatus] = useState<'in-progress' | 'resolved' | 'rejected'>('in-progress');
  const [resolutionNotes, setResolutionNotes] = useState('');
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

  const fetchReports = useCallback(async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('auth_token');

      const response = await fetch(`${API_BASE}/api/reports/admin/all`, {
        headers: { 'Authorization': `Bearer ${token}` },
      });

      if (!response.ok) throw new Error('Failed to fetch reports');
      const data = await response.json();
      setReports(data);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching reports:', error);
      setSnackbar({ open: true, message: 'Failed to fetch reports', severity: 'error' });
      setLoading(false);
    }
  }, []);

  // ── Fetch reports ─────────────────────────────────────────────────────────
  useEffect(() => {
    fetchReports();
  }, [fetchReports]);

  // ── Update report status ──────────────────────────────────────────────────
  const handleUpdateStatus = async () => {
    if (!selectedReport) return;

    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch(`${API_BASE}/api/reports/${selectedReport._id}/status`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ status: newStatus, resolutionNotes }),
      });

      if (!response.ok) throw new Error('Failed to update report status');

      setSnackbar({ open: true, message: 'Report status updated successfully', severity: 'success' });
      setStatusDialog(false);
      setNewStatus('in-progress');
      setResolutionNotes('');
      setSelectedReport(null);
      fetchReports();
    } catch (error) {
      console.error('Error updating report:', error);
      setSnackbar({ open: true, message: 'Failed to update report', severity: 'error' });
    }
  };

  // ── Filter reports by status ──────────────────────────────────────────────
  const pendingReports = reports.filter((r) => r.status === 'pending');
  const inProgressReports = reports.filter((r) => r.status === 'in-progress');
  const resolvedReports = reports.filter((r) => r.status === 'resolved');
  const rejectedReports = reports.filter((r) => r.status === 'rejected');
  const allReports = reports;

  // ── Render report card ────────────────────────────────────────────────────
  const renderReportCard = (report: ReportItem) => {
    const statusColor = STATUS_COLORS[report.status];
    const imageUrl = report.photoBase64 ? `data:image/jpeg;base64,${report.photoBase64}` : null;
    const reportDate = new Date(report.createdAt).toLocaleDateString('en-GB', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });

    return (
      <motion.div
        key={report._id}
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
            borderLeft: `4px solid ${statusColor.bg}`,
            '&:hover': {
              boxShadow: '0 8px 24px rgba(0,0,0,0.15)',
              transform: 'translateY(-4px)',
            },
          }}
        >
          {imageUrl && (
            <CardMedia
              component="img"
              height="180"
              image={imageUrl}
              alt={report.category}
              sx={{ objectFit: 'cover' }}
            />
          )}
          <CardContent sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
              <Box>
                <Typography variant="h6" sx={{ fontWeight: 800, color: 'text.primary' }}>
                  {report.category} - {report.subCategory}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Report ID: {report.id.substring(0, 8)}...
                </Typography>
              </Box>
              <Chip
                label={report.status}
                size="small"
                sx={{
                  bgcolor: statusColor.bg,
                  color: statusColor.color,
                  fontWeight: 600,
                  textTransform: 'capitalize',
                }}
              />
            </Box>

            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                gap: 1,
                mb: 2,
                color: 'text.secondary',
                fontSize: '0.875rem',
              }}
            >
              <LocationIcon sx={{ fontSize: 18 }} />
              <span>{report.location}</span>
            </Box>

            <Typography variant="body2" sx={{ mb: 2, flex: 1, color: 'text.primary' }}>
              {report.description}
            </Typography>

            <Typography variant="caption" color="text.secondary" sx={{ mb: 2 }}>
              Reported by: <strong>{report.createdByName}</strong> on {reportDate}
            </Typography>

            {report.status !== 'pending' && report.resolutionNotes && (
              <Paper sx={{ p: 1.5, bgcolor: 'background.default', borderRadius: 1, mb: 2 }}>
                <Typography variant="caption" sx={{ fontWeight: 800, color: 'text.primary' }}>
                  Resolution Notes:
                </Typography>
                <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block' }}>
                  {report.resolutionNotes}
                </Typography>
              </Paper>
            )}

            {report.status === 'resolved' && report.resolvedAt && (
              <Typography variant="caption" color="success.main" sx={{ mb: 2 }}>
                ✓ Resolved on {new Date(report.resolvedAt).toLocaleDateString()}
              </Typography>
            )}

            {(report.status === 'pending' || report.status === 'in-progress') && (
              <Button
                variant="contained"
                size="small"
                startIcon={<EditIcon />}
                onClick={() => {
                  setSelectedReport(report);
                  setNewStatus(report.status === 'pending' ? 'in-progress' : 'resolved');
                  setStatusDialog(true);
                }}
                sx={{
                  mt: 'auto',
                  bgcolor: 'primary.main',
                  color: 'primary.contrastText',
                  '&:hover': { bgcolor: 'primary.dark' },
                }}
              >
                Update Status
              </Button>
            )}
          </CardContent>
        </Card>
      </motion.div>
    );
  };

  return (
    <Box>
      <Typography variant="h4" sx={{ color: 'text.primary', mb: 4, fontWeight: 900 }}>
        Manage Reports
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
                bgcolor: 'background.default',
                '& .MuiTabs-indicator': { bgcolor: 'primary.main', height: 3 },
              }}
            >
              <Tab label={`Pending (${pendingReports.length})`} />
              <Tab label={`In Progress (${inProgressReports.length})`} />
              <Tab label={`Resolved (${resolvedReports.length})`} />
              <Tab label={`Rejected (${rejectedReports.length})`} />
              <Tab label={`All Reports (${allReports.length})`} />
            </Tabs>
          </Paper>

          <AnimatePresence>
            <TabPanel value={tabValue} index={0}>
              {pendingReports.length === 0 ? (
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
                    No pending reports
                  </Typography>
                </Paper>
              ) : (
                <Grid container spacing={3}>
                  {pendingReports.map((report) => (
                    <Grid item xs={12} sm={6} md={4} key={report._id}>
                      {renderReportCard(report)}
                    </Grid>
                  ))}
                </Grid>
              )}
            </TabPanel>

            <TabPanel value={tabValue} index={1}>
              {inProgressReports.length === 0 ? (
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
                    No in-progress reports
                  </Typography>
                </Paper>
              ) : (
                <Grid container spacing={3}>
                  {inProgressReports.map((report) => (
                    <Grid item xs={12} sm={6} md={4} key={report._id}>
                      {renderReportCard(report)}
                    </Grid>
                  ))}
                </Grid>
              )}
            </TabPanel>

            <TabPanel value={tabValue} index={2}>
              {resolvedReports.length === 0 ? (
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
                    No resolved reports
                  </Typography>
                </Paper>
              ) : (
                <Grid container spacing={3}>
                  {resolvedReports.map((report) => (
                    <Grid item xs={12} sm={6} md={4} key={report._id}>
                      {renderReportCard(report)}
                    </Grid>
                  ))}
                </Grid>
              )}
            </TabPanel>

            <TabPanel value={tabValue} index={3}>
              {rejectedReports.length === 0 ? (
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
                    No rejected reports
                  </Typography>
                </Paper>
              ) : (
                <Grid container spacing={3}>
                  {rejectedReports.map((report) => (
                    <Grid item xs={12} sm={6} md={4} key={report._id}>
                      {renderReportCard(report)}
                    </Grid>
                  ))}
                </Grid>
              )}
            </TabPanel>

            <TabPanel value={tabValue} index={4}>
              {allReports.length === 0 ? (
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
                    No reports
                  </Typography>
                </Paper>
              ) : (
                <Grid container spacing={3}>
                  {allReports.map((report) => (
                    <Grid item xs={12} sm={6} md={4} key={report._id}>
                      {renderReportCard(report)}
                    </Grid>
                  ))}
                </Grid>
              )}
            </TabPanel>
          </AnimatePresence>
        </>
      )}

      {/* Status Update Dialog */}
      <Dialog open={statusDialog} onClose={() => setStatusDialog(false)} fullWidth maxWidth="sm">
        <DialogTitle sx={{ color: 'text.primary', fontWeight: 900 }}>
          Update Report Status
        </DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <FormControl fullWidth sx={{ mb: 2 }}>
            <InputLabel>Select New Status</InputLabel>
            <Select value={newStatus} onChange={(e) => setNewStatus(e.target.value as any)} label="Select New Status">
              <MenuItem value="in-progress">In Progress</MenuItem>
              <MenuItem value="resolved">Resolved</MenuItem>
              <MenuItem value="rejected">Rejected</MenuItem>
            </Select>
          </FormControl>

          <TextField
            fullWidth
            multiline
            rows={4}
            label="Resolution Notes"
            placeholder="Add notes about this report..."
            value={resolutionNotes}
            onChange={(e) => setResolutionNotes(e.target.value)}
            variant="outlined"
          />
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setStatusDialog(false)}>Cancel</Button>
          <Button
            onClick={handleUpdateStatus}
            variant="contained"
            sx={{ bgcolor: 'primary.main', color: 'primary.contrastText', '&:hover': { bgcolor: 'primary.dark' } }}
            disabled={!resolutionNotes.trim()}
          >
            Update Status
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
