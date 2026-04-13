import React, { useState, useEffect, useRef } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Grid from '@mui/material/Grid';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Avatar from '@mui/material/Avatar';
import IconButton from '@mui/material/IconButton';
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
import Menu from '@mui/material/Menu';
import Divider from '@mui/material/Divider';
import Tooltip from '@mui/material/Tooltip';
import {
  Add as AddIcon,
  MoreVert as MoreVertIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  FilterList as FilterIcon,
  Delete as DeleteIcon,
  Badge as BadgeIcon,
  CloudUpload as CloudUploadIcon,
  PictureAsPdf as PdfIcon,
} from '@mui/icons-material';
import { motion, AnimatePresence } from 'framer-motion';

const API_BASE = 'http://localhost:5000';

// ── Types ─────────────────────────────────────────────────────────────────────
interface Employee {
  _id: string;
  firstName: string;
  lastName: string;
  photo: string;
  cinId: string;
  address: string;
  phone: string;
  email: string;
  workCategory: 'Cleaning' | 'Plumber' | 'Electrician' | 'Repair';
  experience: string;
  casierJudiciaire: string;
  status: 'online' | 'offline';
  hiredDate: string;
  createdAt: string;
}

const WORK_CATEGORIES = ['Cleaning', 'Plumber', 'Electrician', 'Repair'];

const CATEGORY_COLORS: Record<string, { bg: string; color: string }> = {
  Cleaning: { bg: '#E8F5E9', color: '#2E7D32' },
  Plumber: { bg: '#E3F2FD', color: '#1565C0' },
  Electrician: { bg: '#FFF3E0', color: '#E65100' },
  Repair: { bg: '#F3E5F5', color: '#6A1B9A' },
};

// ── Empty form state ──────────────────────────────────────────────────────────
const emptyForm = {
  firstName: '',
  lastName: '',
  cinId: '',
  address: '',
  phone: '',
  email: '',
  workCategory: '',
  experience: '',
};

// ── Employee Card ─────────────────────────────────────────────────────────────
function EmployeeCard({
  employee,
  onDelete,
}: {
  employee: Employee;
  onDelete: (id: string) => void;
}) {
  const [menuAnchor, setMenuAnchor] = useState<null | HTMLElement>(null);
  const fullName = `${employee.firstName} ${employee.lastName}`;
  const initials = `${employee.firstName[0] ?? ''}${employee.lastName[0] ?? ''}`.toUpperCase();
  const photoUrl = employee.photo ? `${API_BASE}/uploads/${employee.photo}` : '';
  const catColor = CATEGORY_COLORS[employee.workCategory] ?? { bg: '#F5F5F5', color: '#555' };
  const hiredFormatted = employee.hiredDate
    ? new Date(employee.hiredDate).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
    : '—';

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ duration: 0.25 }}
      style={{ height: '100%' }}
    >
      <Card
        sx={{
          height: '100%',
          borderRadius: 3,
          boxShadow: '0 2px 12px rgba(0,0,0,0.08)',
          transition: 'box-shadow 0.2s, transform 0.2s',
          '&:hover': {
            boxShadow: '0 6px 24px rgba(3,72,8,0.15)',
            transform: 'translateY(-2px)',
          },
          position: 'relative',
          overflow: 'visible',
        }}
      >
        {/* Three-dot menu */}
        <Box sx={{ position: 'absolute', top: 10, right: 10, zIndex: 1 }}>
          <IconButton
            size="small"
            onClick={(e) => setMenuAnchor(e.currentTarget)}
            sx={{ color: '#9e9e9e' }}
          >
            <MoreVertIcon fontSize="small" />
          </IconButton>
          <Menu
            anchorEl={menuAnchor}
            open={Boolean(menuAnchor)}
            onClose={() => setMenuAnchor(null)}
            anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            transformOrigin={{ vertical: 'top', horizontal: 'right' }}
          >
            <MenuItem
              onClick={() => {
                setMenuAnchor(null);
                onDelete(employee._id);
              }}
              sx={{ color: '#f44336', gap: 1 }}
            >
              <DeleteIcon fontSize="small" />
              Delete
            </MenuItem>
          </Menu>
        </Box>

        <CardContent sx={{ pt: 3, pb: 2, px: 2.5 }}>
          {/* Avatar + status */}
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', mb: 2 }}>
            <Box sx={{ position: 'relative', mb: 1.5 }}>
              <Avatar
                src={photoUrl}
                sx={{
                  width: 72,
                  height: 72,
                  bgcolor: '#034808',
                  fontSize: 24,
                  fontWeight: 700,
                  border: '3px solid #f5f5f5',
                  boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
                }}
              >
                {!photoUrl && initials}
              </Avatar>
              {/* Online status dot */}
              <Box
                sx={{
                  position: 'absolute',
                  bottom: 2,
                  right: 2,
                  width: 14,
                  height: 14,
                  borderRadius: '50%',
                  bgcolor: employee.status === 'online' ? '#4CAF50' : '#9E9E9E',
                  border: '2px solid white',
                }}
              />
            </Box>

            {/* Name */}
            <Typography variant="body1" fontWeight={700} textAlign="center" sx={{ color: '#1a1a1a', lineHeight: 1.2 }}>
              {fullName}
            </Typography>

            {/* Work category chip */}
            <Chip
              label={employee.workCategory}
              size="small"
              sx={{
                mt: 0.75,
                bgcolor: catColor.bg,
                color: catColor.color,
                fontWeight: 600,
                fontSize: 11,
                height: 22,
              }}
            />
          </Box>

          <Divider sx={{ mb: 1.5 }} />

          {/* Department + Hired Date */}
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1.5, flexWrap: 'wrap', gap: 0.5 }}>
            <Chip
              label={employee.workCategory}
              size="small"
              variant="outlined"
              sx={{ borderColor: '#034808', color: '#034808', fontSize: 10, height: 20 }}
            />
            <Typography variant="caption" color="text.secondary" sx={{ fontSize: 11 }}>
              Hired {hiredFormatted}
            </Typography>
          </Box>

          {/* Email */}
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.75 }}>
            <EmailIcon sx={{ fontSize: 14, color: '#757575', flexShrink: 0 }} />
            <Tooltip title={employee.email}>
              <Typography
                variant="caption"
                noWrap
                sx={{ fontSize: 12, color: '#555', maxWidth: '90%' }}
              >
                {employee.email}
              </Typography>
            </Tooltip>
          </Box>

          {/* Phone */}
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <PhoneIcon sx={{ fontSize: 14, color: '#757575', flexShrink: 0 }} />
            <Typography variant="caption" sx={{ fontSize: 12, color: '#555' }}>
              {employee.phone}
            </Typography>
          </Box>
        </CardContent>
      </Card>
    </motion.div>
  );
}

// ── Main Page ─────────────────────────────────────────────────────────────────
export default function Employees() {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [loading, setLoading] = useState(true);
  const [openModal, setOpenModal] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [formData, setFormData] = useState(emptyForm);
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string>('');
  const [pdfFile, setPdfFile] = useState<File | null>(null);
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });
  const [deleteDialog, setDeleteDialog] = useState<{ open: boolean; id: string; name: string }>({
    open: false,
    id: '',
    name: '',
  });

  const photoInputRef = useRef<HTMLInputElement>(null);
  const pdfInputRef = useRef<HTMLInputElement>(null);

  // ── Fetch employees ──────────────────────────────────────────────────────────
  const fetchEmployees = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/api/employees`);
      const data = await res.json();
      if (data.success) setEmployees(data.employees);
    } catch (err) {
      console.error('fetchEmployees error:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEmployees();
  }, []);

  // ── Open / close modal ───────────────────────────────────────────────────────
  const handleOpenModal = () => {
    setFormData(emptyForm);
    setPhotoFile(null);
    setPhotoPreview('');
    setPdfFile(null);
    setFormErrors({});
    setOpenModal(true);
  };

  const handleCloseModal = () => setOpenModal(false);

  // ── Validation ───────────────────────────────────────────────────────────────
  const validate = (): boolean => {
    const errors: Record<string, string> = {};
    if (!formData.firstName.trim()) errors.firstName = 'Required';
    if (!formData.lastName.trim()) errors.lastName = 'Required';
    if (!formData.cinId.trim()) errors.cinId = 'Required';
    if (!formData.address.trim()) errors.address = 'Required';
    if (!formData.phone.trim()) errors.phone = 'Required';
    if (!formData.email.trim()) errors.email = 'Required';
    else if (!/\S+@\S+\.\S+/.test(formData.email)) errors.email = 'Invalid email';
    if (!formData.workCategory) errors.workCategory = 'Required';
    if (!formData.experience.trim()) errors.experience = 'Required';
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  // ── Submit ────────────────────────────────────────────────────────────────────
  const handleSubmit = async () => {
    if (!validate()) return;
    setSubmitting(true);
    try {
      const fd = new FormData();
      Object.entries(formData).forEach(([k, v]) => fd.append(k, v));
      if (photoFile) fd.append('photo', photoFile);
      if (pdfFile) fd.append('casierJudiciaire', pdfFile);

      const res = await fetch(`${API_BASE}/api/employees`, {
        method: 'POST',
        body: fd,
      });
      const data = await res.json();

      if (data.success) {
        // Optimistic update — prepend new employee to state immediately
        setEmployees((prev) => [data.employee, ...prev]);
        setSnackbar({ open: true, message: `${formData.firstName} ${formData.lastName} added successfully!`, severity: 'success' });
        handleCloseModal();
      } else {
        setSnackbar({ open: true, message: data.error || 'Failed to add employee', severity: 'error' });
      }
    } catch (err) {
      setSnackbar({ open: true, message: 'Connection error. Please check the server.', severity: 'error' });
    } finally {
      setSubmitting(false);
    }
  };

  // ── Delete ────────────────────────────────────────────────────────────────────
  const confirmDelete = (id: string, name: string) => {
    setDeleteDialog({ open: true, id, name });
  };

  const handleDelete = async () => {
    try {
      const res = await fetch(`${API_BASE}/api/employees/${deleteDialog.id}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        setEmployees((prev) => prev.filter((e) => e._id !== deleteDialog.id));
        setSnackbar({ open: true, message: 'Employee deleted', severity: 'success' });
      }
    } catch {
      setSnackbar({ open: true, message: 'Delete failed', severity: 'error' });
    } finally {
      setDeleteDialog({ open: false, id: '', name: '' });
    }
  };

  // ── Photo upload ──────────────────────────────────────────────────────────────
  const handlePhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setPhotoFile(file);
    const reader = new FileReader();
    reader.onload = () => setPhotoPreview(reader.result as string);
    reader.readAsDataURL(file);
  };

  const handlePdfChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) setPdfFile(file);
  };

  const field = (key: keyof typeof formData) => ({
    value: formData[key],
    onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
      setFormData((prev) => ({ ...prev, [key]: e.target.value })),
    error: !!formErrors[key],
    helperText: formErrors[key],
  });

  // ── Render ────────────────────────────────────────────────────────────────────
  return (
    <Box>
      {/* ── Page Header ── */}
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          mb: 4,
          flexWrap: 'wrap',
          gap: 2,
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'baseline', gap: 1.5 }}>
          <Typography
            variant="h4"
            sx={{ color: '#034808', fontWeight: 700 }}
          >
            {employees.length}
          </Typography>
          <Typography variant="h4" sx={{ color: '#034808' }}>
            Employees
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5 }}>
          <Button
            variant="outlined"
            startIcon={<FilterIcon />}
            sx={{
              borderColor: '#034808',
              color: '#034808',
              '&:hover': { borderColor: '#023206', bgcolor: 'rgba(3,72,8,0.04)' },
            }}
          >
            Filter
          </Button>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={handleOpenModal}
            sx={{
              bgcolor: '#FFD700',
              color: '#034808',
              fontWeight: 700,
              '&:hover': { bgcolor: '#CCAC00' },
              boxShadow: '0 2px 8px rgba(255,215,0,0.4)',
            }}
          >
            Add Employee
          </Button>
        </Box>
      </Box>

      {/* ── Content ── */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 10 }}>
          <CircularProgress sx={{ color: '#034808' }} />
        </Box>
      ) : employees.length === 0 ? (
        /* ── Empty State ── */
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            minHeight: '50vh',
            gap: 3,
          }}
        >
          <Box
            sx={{
              width: 100,
              height: 100,
              borderRadius: '50%',
              bgcolor: 'rgba(3,72,8,0.06)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <BadgeIcon sx={{ fontSize: 48, color: '#034808', opacity: 0.4 }} />
          </Box>
          <Typography variant="h6" color="text.secondary">
            No employees yet
          </Typography>
          <motion.div whileHover={{ scale: 1.04 }} whileTap={{ scale: 0.97 }}>
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              onClick={handleOpenModal}
              sx={{
                bgcolor: '#FFD700',
                color: '#034808',
                fontWeight: 700,
                px: 4,
                py: 1.5,
                fontSize: 16,
                borderRadius: 3,
                boxShadow: '0 4px 20px rgba(255,215,0,0.5)',
                '&:hover': { bgcolor: '#CCAC00' },
              }}
            >
              + Add Employee
            </Button>
          </motion.div>
        </Box>
      ) : (
        /* ── Cards Grid ── */
        <AnimatePresence>
          <Grid container spacing={3}>
            {employees.map((emp) => (
              <Grid
                item
                key={emp._id}
                xs={12}
                sm={6}
                md={4}
              >
                <EmployeeCard employee={emp} onDelete={(id) => confirmDelete(id, `${emp.firstName} ${emp.lastName}`)} />
              </Grid>
            ))}
          </Grid>
        </AnimatePresence>
      )}

      {/* ── Add Employee Modal ── */}
      <Dialog
        open={openModal}
        onClose={handleCloseModal}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3 } }}
      >
        <DialogTitle
          sx={{
            bgcolor: '#034808',
            color: 'white',
            fontWeight: 700,
            display: 'flex',
            alignItems: 'center',
            gap: 1.5,
          }}
        >
          <BadgeIcon />
          Add New Employee
        </DialogTitle>

        <DialogContent dividers sx={{ py: 3, px: 3 }}>
          {/* ── Personal Information ── */}
          <Typography
            variant="overline"
            sx={{ color: '#034808', fontWeight: 700, letterSpacing: 1.2, display: 'block', mb: 1.5 }}
          >
            Personal Information
          </Typography>

          <Grid container spacing={2}>
            <Grid item xs={12} sm={6}>
              <TextField fullWidth label="First Name" {...field('firstName')} required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField fullWidth label="Last Name" {...field('lastName')} required />
            </Grid>

            {/* Profile Photo */}
            <Grid item xs={12}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Avatar
                  src={photoPreview}
                  sx={{ width: 56, height: 56, bgcolor: '#034808', fontSize: 20 }}
                >
                  {!photoPreview && (formData.firstName[0] ?? '') + (formData.lastName[0] ?? '')}
                </Avatar>
                <Box>
                  <input
                    ref={photoInputRef}
                    type="file"
                    accept="image/*"
                    hidden
                    onChange={handlePhotoChange}
                  />
                  <Button
                    variant="outlined"
                    startIcon={<CloudUploadIcon />}
                    onClick={() => photoInputRef.current?.click()}
                    size="small"
                    sx={{ borderColor: '#034808', color: '#034808', mb: 0.5 }}
                  >
                    Upload Photo
                  </Button>
                  {photoFile && (
                    <Typography variant="caption" display="block" color="text.secondary">
                      {photoFile.name}
                    </Typography>
                  )}
                </Box>
              </Box>
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField fullWidth label="Identity Card ID (CIN)" {...field('cinId')} required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField fullWidth label="Phone Number" {...field('phone')} required />
            </Grid>
            <Grid item xs={12}>
              <TextField fullWidth label="Home Address" {...field('address')} required />
            </Grid>
            <Grid item xs={12}>
              <TextField fullWidth label="Email Address" type="email" {...field('email')} required />
            </Grid>
          </Grid>

          <Divider sx={{ my: 3 }} />

          {/* ── Professional Information ── */}
          <Typography
            variant="overline"
            sx={{ color: '#034808', fontWeight: 700, letterSpacing: 1.2, display: 'block', mb: 1.5 }}
          >
            Professional Information
          </Typography>

          <Grid container spacing={2}>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth required error={!!formErrors.workCategory}>
                <InputLabel>Work Category</InputLabel>
                <Select
                  value={formData.workCategory}
                  label="Work Category"
                  onChange={(e) =>
                    setFormData((prev) => ({ ...prev, workCategory: e.target.value }))
                  }
                >
                  {WORK_CATEGORIES.map((cat) => (
                    <MenuItem key={cat} value={cat}>
                      {cat}
                    </MenuItem>
                  ))}
                </Select>
                {formErrors.workCategory && (
                  <Typography variant="caption" color="error" sx={{ ml: 1.5, mt: 0.5 }}>
                    {formErrors.workCategory}
                  </Typography>
                )}
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Experience"
                placeholder="e.g. 3 years"
                {...field('experience')}
                required
              />
            </Grid>

            {/* Criminal Record PDF */}
            <Grid item xs={12}>
              <Typography variant="body2" sx={{ mb: 1, color: '#555', fontWeight: 500 }}>
                Criminal Record / Casier judiciaire — Bulletin n°3{' '}
                <Typography component="span" variant="caption" color="text.secondary">
                  (PDF only, optional)
                </Typography>
              </Typography>
              <input
                ref={pdfInputRef}
                type="file"
                accept="application/pdf"
                hidden
                onChange={handlePdfChange}
              />
              <Button
                variant="outlined"
                startIcon={pdfFile ? <PdfIcon sx={{ color: '#f44336' }} /> : <CloudUploadIcon />}
                onClick={() => pdfInputRef.current?.click()}
                sx={{
                  borderColor: pdfFile ? '#f44336' : '#034808',
                  color: pdfFile ? '#f44336' : '#034808',
                  '&:hover': {
                    borderColor: pdfFile ? '#c62828' : '#023206',
                    bgcolor: 'transparent',
                  },
                }}
              >
                {pdfFile ? pdfFile.name : 'Upload PDF'}
              </Button>
            </Grid>
          </Grid>
        </DialogContent>

        <DialogActions sx={{ px: 3, py: 2, gap: 1 }}>
          <Button onClick={handleCloseModal} disabled={submitting}>
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={handleSubmit}
            disabled={submitting}
            startIcon={submitting ? <CircularProgress size={16} color="inherit" /> : <AddIcon />}
            sx={{
              bgcolor: '#FFD700',
              color: '#034808',
              fontWeight: 700,
              '&:hover': { bgcolor: '#CCAC00' },
              '&:disabled': { bgcolor: '#e0c800', color: '#034808' },
            }}
          >
            {submitting ? 'Adding...' : 'Add Employee'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* ── Delete Confirm Dialog ── */}
      <Dialog open={deleteDialog.open} onClose={() => setDeleteDialog({ open: false, id: '', name: '' })}>
        <DialogTitle>Delete Employee</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete <strong>{deleteDialog.name}</strong>?
          </Typography>
          <Typography variant="caption" color="error">
            This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialog({ open: false, id: '', name: '' })}>Cancel</Button>
          <Button onClick={handleDelete} color="error" variant="contained">
            Delete
          </Button>
        </DialogActions>
      </Dialog>

      {/* ── Snackbar ── */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={3500}
        onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert severity={snackbar.severity} sx={{ width: '100%' }}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
