import React, { useState, useEffect, useCallback } from 'react';
import Grid from '@mui/material/Grid';
import Paper from '@mui/material/Paper';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import IconButton from '@mui/material/IconButton';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import Select from '@mui/material/Select';
import MenuItem from '@mui/material/MenuItem';
import Chip from '@mui/material/Chip';
import Avatar from '@mui/material/Avatar';
import Tab from '@mui/material/Tab';
import Tabs from '@mui/material/Tabs';
import Alert from '@mui/material/Alert';
import Snackbar from '@mui/material/Snackbar';
import CircularProgress from '@mui/material/CircularProgress';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Person as PersonIcon,
  Security as SecurityIcon,
  Search as SearchIcon,
  Refresh as RefreshIcon,
  ToggleOn as ToggleOnIcon,
  ToggleOff as ToggleOffIcon,
} from '@mui/icons-material';
import { alpha, useTheme } from '@mui/material/styles';
import { useAuth } from '../context/AuthContext';
import { residencesAPI, Residence } from '../services/residences';

// Types
interface User {
  id: string;
  name: string;
  email: string;
  phone: string;
  role: 'resident' | 'security' | 'admin' | 'maintenance' | 'facility_manager';
  apartment?: string;
  residence?: string;
  building?: string;
  status: 'active' | 'inactive' | 'pending';
  joinDate: string;
  specialization?: string | null;
}

// Tab Panel Component
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
      id={`simple-tabpanel-${index}`}
      aria-labelledby={`simple-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ pt: 3 }}>{children}</Box>}
    </div>
  );
}

export default function ManageAccounts() {
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';

  const {
    user,
    getAllUsers,
    updateUserRole,
    updateUserStatus,
    deleteUser,
    createUser,
    updateUser,
    loading: authLoading,
  } = useAuth();
  
  const [tabValue, setTabValue] = useState(0);
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [deleteDialog, setDeleteDialog] = useState(false);
  const [userToDelete, setUserToDelete] = useState<User | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });
  const [employeeSpecFilter, setEmployeeSpecFilter] = useState<string>('');
  
  // Residences and cascade state
  const [residences, setResidences] = useState<Residence[]>([]);
  const [residencesLoading, setResidencesLoading] = useState(false);
  
  // Form state
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    role: 'security' as User['role'],
    status: 'active' as User['status'],
    password: '',
    confirmPassword: '',
    apartment: '',
    residence: '',
    building: '',
  });

  // Load residences when dialog opens for resident edit
  useEffect(() => {
    if (openDialog && editingUser?.role === 'resident') {
      loadResidences();
    }
  }, [openDialog, editingUser?.role]);

  const loadResidences = async () => {
    setResidencesLoading(true);
    try {
      const data = await residencesAPI.list();
      setResidences(data.residences);
    } catch (error) {
      console.error('Failed to load residences:', error);
      setSnackbar({
        open: true,
        message: 'Failed to load residences',
        severity: 'error',
      });
    } finally {
      setResidencesLoading(false);
    }
  };

  // Check if current user is admin
  const isAdmin = user?.role === 'admin';

  // Load users from API
  const loadUsers = useCallback(async () => {
    setLoading(true);
    try {
      const allUsers = await getAllUsers();
      const formattedUsers: User[] = allUsers.map(u => ({
        id: u._id || u.id || u.uid,
        name: u.name,
        email: u.email,
        phone: u.phone,
        role: (((u as any).role === 'facilities_manager') ? 'facility_manager' : (u as any).role) as User['role'],
        apartment: u.apartment,
        residence: (u as any).residence || '',
        building: (u as any).building || '',
        status: u.status,
        joinDate: u.joinDate,
        specialization: (u as any).specialization || null,
      }));
      setUsers(formattedUsers);
    } catch (error) {
      console.error('Error loading users:', error);
      setSnackbar({
        open: true,
        message: 'Failed to load users',
        severity: 'error',
      });
    } finally {
      setLoading(false);
    }
  }, [getAllUsers]);

  useEffect(() => {
    if (isAdmin) {
      loadUsers();
      // Preload residences to make selectors responsive
      void loadResidences();
    }
  }, [isAdmin, loadUsers]);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleOpenAddDialog = () => {
    setEditingUser(null);
    setFormData({
      name: '',
      email: '',
      phone: '',
      role: 'security',
      status: 'active',
      password: '',
      confirmPassword: '',
      apartment: '',
      residence: '',
      building: '',
    });
    setOpenDialog(true);
  };

  const handleOpenEditDialog = (user: User) => {
    setEditingUser(user);
    setFormData({
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      status: user.status,
      password: '',
      confirmPassword: '',
      apartment: user.apartment || '',
      residence: (user as any).residence || '',
      building: (user as any).building || '',
    });
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setEditingUser(null);
  };

  const handleOpenDeleteDialog = (user: User) => {
    setUserToDelete(user);
    setDeleteDialog(true);
  };

  const handleCloseDeleteDialog = () => {
    setDeleteDialog(false);
    setUserToDelete(null);
  };

  const handleDeleteUser = async () => {
    if (userToDelete) {
      try {
        await deleteUser(userToDelete.id);
        await loadUsers();
        setSnackbar({
          open: true,
          message: `User ${userToDelete.name} deleted successfully`,
          severity: 'success',
        });
      } catch (error) {
        setSnackbar({
          open: true,
          message: 'Failed to delete user',
          severity: 'error',
        });
      }
      handleCloseDeleteDialog();
    }
  };

  const handleSaveUser = async () => {
    if (!formData.name || !formData.email || !formData.phone) {
      setSnackbar({
        open: true,
        message: 'Please fill all required fields',
        severity: 'error',
      });
      return;
    }

    const normalizedPhone = (formData.phone || '').replace(/\s+/g, '');

    if (!editingUser) {
      if (!/^0\d{9}$/.test(normalizedPhone)) {
        setSnackbar({
          open: true,
          message: 'Incorrect phone number. It must start with 0 and be exactly 10 digits.',
          severity: 'error',
        });
        return;
      }

      const allowedCreateRoles: User['role'][] = ['security', 'maintenance', 'facility_manager'];
      if (!allowedCreateRoles.includes(formData.role)) {
        setSnackbar({
          open: true,
          message: 'You can only create Agent, Maintenance, or Facilities Manager accounts.',
          severity: 'error',
        });
        return;
      }

      const hasPassword = !!formData.password;
      const hasConfirm = !!formData.confirmPassword;
      if (hasPassword || hasConfirm) {
        if (!hasPassword || !hasConfirm) {
          setSnackbar({
            open: true,
            message: 'Please enter and confirm the password (or leave both blank to auto-generate).',
            severity: 'error',
          });
          return;
        }

        if (formData.password.length < 8) {
          setSnackbar({
            open: true,
            message: 'Password must be at least 8 characters.',
            severity: 'error',
          });
          return;
        }

        if (!/^(?=.*[A-Za-z])(?=.*\d)(?=.*[._@])[A-Za-z\d._@]+$/.test(formData.password)) {
          setSnackbar({
            open: true,
            message: 'Password must include letters, numbers, and at least one symbol (._@).',
            severity: 'error',
          });
          return;
        }

        if (formData.password !== formData.confirmPassword) {
          setSnackbar({
            open: true,
            message: 'Passwords do not match.',
            severity: 'error',
          });
          return;
        }
      }
    }

    try {
      if (editingUser) {
        // Update existing user (send role + status + location fields together)
        const payload: any = {
          name: formData.name,
          phone: normalizedPhone,
          role: formData.role,
          status: formData.status,
        };

        if (formData.role === 'resident') {
          payload.apartment = formData.apartment || '';
          payload.residence = formData.residence || null;
          payload.building = formData.building || null;
        } else {
          payload.apartment = undefined;
          payload.residence = null;
          payload.building = null;
        }

        await updateUser(editingUser.id, payload);
        await loadUsers();
        setSnackbar({ open: true, message: `User ${formData.name} updated successfully`, severity: 'success' });
      } else {
        // Add new user via admin API
        const res = await createUser({
          name: formData.name,
          email: formData.email,
          phone: normalizedPhone,
          role: formData.role,
          password: formData.password,
          residence: formData.residence || undefined,
          building: formData.building || undefined,
        });
        await loadUsers();
        const tempPass = (res as any)?.tempPassword;
        setSnackbar({
          open: true,
          message: `User ${formData.name} added successfully` + (tempPass ? ` (temp password: ${tempPass})` : ''),
          severity: 'success',
        });
      }
      handleCloseDialog();
    } catch (error) {
      setSnackbar({
        open: true,
        message: error instanceof Error ? error.message : 'Failed to save user',
        severity: 'error',
      });
    }
  };

  const filteredUsers = users.filter(user => {
    const matchesSearch =
      user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.phone.includes(searchTerm) ||
      (user.apartment && user.apartment.toLowerCase().includes(searchTerm.toLowerCase()));

    // Exclude admin from Manage Accounts entirely
    if (user.role === 'admin') return false;

    // tabValue 0 => Residents only
    if (tabValue === 0) return matchesSearch && user.role === 'resident';

    // tabValue 1 => Agents (security staff)
    if (tabValue === 1) return matchesSearch && user.role === 'security';

    // tabValue 2 => Maintenance staff
    if (tabValue === 2) return matchesSearch && user.role === 'maintenance';

    // tabValue 3 => Facilities managers
    if (tabValue === 3) return matchesSearch && user.role === 'facility_manager';

    return matchesSearch;
  });

  const getRoleChipColor = (role: string) => {
    switch(role) {
      case 'admin':
        return { bg: theme.palette.primary.main, color: theme.palette.primary.contrastText };
      case 'security':
        return { bg: theme.palette.secondary.main, color: theme.palette.primary.dark };
      case 'maintenance':
        return { bg: theme.palette.error.main, color: theme.palette.error.contrastText };
      case 'facility_manager':
        return { bg: '#FFA726', color: '#fff' };
      default:
        return {
          bg: alpha(theme.palette.text.primary, isDark ? 0.12 : 0.08),
          color: theme.palette.text.primary,
        };
    }
  };

  const getStatusChip = (status: string) => {
    switch(status) {
      case 'active':
        return <Chip label="Active" size="small" sx={{ bgcolor: '#4CAF50', color: 'white' }} />;
      case 'inactive':
        return <Chip label="Inactive" size="small" sx={{ bgcolor: '#9E9E9E', color: 'white' }} />;
      case 'pending':
        return <Chip label="Pending" size="small" sx={{ bgcolor: '#FFC107', color: '#333' }} />;
      default:
        return null;
    }
  };

  if (authLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
        <CircularProgress />
      </Box>
    );
  }

  // Access denied if not admin
  if (!isAdmin) {
    return (
      <Box sx={{ textAlign: 'center', py: 8 }}>
        <Typography variant="h5" color="error">
          Access Denied
        </Typography>
        <Typography>You don't have permission to view this page.</Typography>
      </Box>
    );
  }

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" sx={{ color: 'text.primary' }}>
          Manage Accounts
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleOpenAddDialog}
          sx={{
            bgcolor: 'primary.main',
            color: 'primary.contrastText',
            '&:hover': { bgcolor: 'primary.dark' }
          }}
        >
          Add New Account
        </Button>
      </Box>

      {/* Search Bar */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              variant="outlined"
              placeholder="Search by name, email, phone, or apartment..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
              }}
            />
          </Grid>
          <Grid item xs={12} md={6}>
            <Box sx={{ display: 'flex', gap: 1, justifyContent: 'flex-end' }}>
              <Chip
                icon={<PersonIcon />}
                label={`Total: ${users.length}`}
                sx={{ bgcolor: 'primary.main', color: 'primary.contrastText' }}
              />
              <Chip
                icon={<PersonIcon />}
                label={`Residents: ${users.filter(u => u.role === 'resident').length}`}
                sx={{ bgcolor: 'secondary.main', color: 'primary.dark' }}
              />
              <Chip
                icon={<SecurityIcon />}
                label={`Staff: ${users.filter(u => u.role !== 'resident').length}`}
                sx={{ bgcolor: alpha(theme.palette.text.primary, isDark ? 0.12 : 0.08) }}
              />
                  {/* specialization filters moved to Employees page */}
              <IconButton onClick={loadUsers} size="small">
                <RefreshIcon />
              </IconButton>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Tabs */}
      <Paper sx={{ width: '100%' }}>
        <Tabs
          value={tabValue}
          onChange={handleTabChange}
          sx={{
            borderBottom: 1,
            borderColor: 'divider',
            '& .MuiTab-root.Mui-selected': { color: theme.palette.primary.main },
            '& .MuiTabs-indicator': { bgcolor: theme.palette.primary.main },
          }}
        >
          <Tab label="Residents" />
          <Tab label="Agents" />
          <Tab label="Maintenance" />
          <Tab label="Facilities" />
        </Tabs>

        {/* Residents Tab */}
        <TabPanel value={tabValue} index={0}>
          <UserTable
            users={filteredUsers}
            onEdit={handleOpenEditDialog}
            onDelete={handleOpenDeleteDialog}
            onToggleActive={(u) => {
              const newStatus = u.status === 'active' ? 'inactive' : 'active';
              updateUserStatus(u.id, newStatus).then(() => loadUsers());
            }}
            getRoleChipColor={getRoleChipColor}
            getStatusChip={getStatusChip}
          />
        </TabPanel>

        {/* Agents Tab */}
        <TabPanel value={tabValue} index={1}>
          <UserTable
            users={filteredUsers}
            onEdit={handleOpenEditDialog}
            onDelete={handleOpenDeleteDialog}
            onToggleActive={(u) => {
              const newStatus = u.status === 'active' ? 'inactive' : 'active';
              updateUserStatus(u.id, newStatus).then(() => loadUsers());
            }}
            getRoleChipColor={getRoleChipColor}
            getStatusChip={getStatusChip}
          />
        </TabPanel>

        {/* Maintenance Tab */}
        <TabPanel value={tabValue} index={2}>
          <UserTable
            users={filteredUsers}
            onEdit={handleOpenEditDialog}
            onDelete={handleOpenDeleteDialog}
            onToggleActive={(u) => {
              const newStatus = u.status === 'active' ? 'inactive' : 'active';
              updateUserStatus(u.id, newStatus).then(() => loadUsers());
            }}
            getRoleChipColor={getRoleChipColor}
            getStatusChip={getStatusChip}
          />
        </TabPanel>
        {/* Facilities Tab */}
        <TabPanel value={tabValue} index={3}>
          <UserTable
            users={filteredUsers}
            onEdit={handleOpenEditDialog}
            onDelete={handleOpenDeleteDialog}
            onToggleActive={(u) => {
              const newStatus = u.status === 'active' ? 'inactive' : 'active';
              updateUserStatus(u.id, newStatus).then(() => loadUsers());
            }}
            getRoleChipColor={getRoleChipColor}
            getStatusChip={getStatusChip}
          />
        </TabPanel>
      </Paper>

      {/* Add/Edit User Dialog */}
      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ bgcolor: '#034808', color: 'white' }}>
          {editingUser ? 'Edit Account' : 'Add New Account'}
        </DialogTitle>
        <DialogContent sx={{ pt: 3 }}>
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Full Name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
                margin="normal"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Email"
                type="email"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                required
                margin="normal"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Phone"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                required
                margin="normal"
                inputProps={{ inputMode: 'numeric', pattern: '0\\d{9}' }}
                helperText="Must start with 0 and be 10 digits"
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <FormControl fullWidth margin="normal">
                <InputLabel>Role</InputLabel>
                <Select
                  value={formData.role}
                  label="Role"
                  onChange={(e) => setFormData({ ...formData, role: e.target.value as User['role'] })}
                >
                  {editingUser && <MenuItem value="resident">Resident</MenuItem>}
                  <MenuItem value="security">Agent</MenuItem>
                  <MenuItem value="maintenance">Maintenance</MenuItem>
                  <MenuItem value="facility_manager">Facilities Manager</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            {editingUser && (
              <Grid item xs={12} md={6}>
                <FormControl fullWidth margin="normal">
                  <InputLabel>Account Status</InputLabel>
                  <Select
                    value={formData.status}
                    label="Account Status"
                    onChange={(e) => setFormData({ ...formData, status: e.target.value as User['status'] })}
                  >
                    <MenuItem value="pending">Pending (Waiting for Approval)</MenuItem>
                    <MenuItem value="active">Active (Approved)</MenuItem>
                    <MenuItem value="inactive">Inactive</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
            )}
            {!editingUser && (
              <>
                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    label="Password"
                    type="password"
                    value={formData.password}
                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                    margin="normal"
                    helperText="Min 8 chars; include letters + numbers + one of (._@). Leave blank to auto-generate"
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    label="Confirm Password"
                    type="password"
                    value={formData.confirmPassword}
                    onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
                    margin="normal"
                  />
                </Grid>
              </>
            )}
            {editingUser && formData.role === 'resident' && (
              <>
                <Grid item xs={12}>
                  <FormControl fullWidth margin="normal" disabled={residencesLoading}>
                    <InputLabel>Residence</InputLabel>
                    <Select
                      value={formData.residence}
                      label="Residence"
                      onChange={(e) => setFormData({ ...formData, residence: e.target.value, building: '', apartment: '' })}
                    >
                      <MenuItem value="">-- Select Residence --</MenuItem>
                      {residences.map((res) => (
                        <MenuItem key={res._id} value={res._id}>
                          {res.name}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </Grid>
                {formData.residence && (
                  <>
                    <Grid item xs={12}>
                      <FormControl fullWidth margin="normal">
                        <InputLabel>Building</InputLabel>
                        <Select
                          value={formData.building}
                          label="Building"
                          onChange={(e) => setFormData({ ...formData, building: e.target.value, apartment: '' })}
                        >
                          <MenuItem value="">-- Select Building --</MenuItem>
                          {residences
                            .find((res) => res._id === formData.residence)
                            ?.buildings.map((bldg) => (
                              <MenuItem key={bldg.id} value={bldg.id}>
                                {bldg.name}
                              </MenuItem>
                            ))}
                        </Select>
                      </FormControl>
                    </Grid>
                    {formData.building && (
                      <Grid item xs={12}>
                        <FormControl fullWidth margin="normal">
                          <InputLabel>Apartment Number</InputLabel>
                          <Select
                            value={formData.apartment}
                            label="Apartment Number"
                            onChange={(e) => setFormData({ ...formData, apartment: e.target.value })}
                          >
                            <MenuItem value="">-- Select Apartment --</MenuItem>
                            {Array.from({ length: residences.find((res) => res._id === formData.residence)?.buildings.find((b) => b.id === formData.building)?.apartments || 0 }, (_, i) => i + 1).map((num) => (
                              <MenuItem key={num} value={num.toString()}>
                                {num}
                              </MenuItem>
                            ))}
                          </Select>
                        </FormControl>
                      </Grid>
                    )}
                  </>
                )}
              </>
            )}
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button
            onClick={handleSaveUser}
            variant="contained"
            sx={{ bgcolor: '#034808', '&:hover': { bgcolor: '#023206' } }}
          >
            {editingUser ? 'Update' : 'Add'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialog} onClose={handleCloseDeleteDialog}>
        <DialogTitle>Confirm Delete</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete {userToDelete?.name}?
          </Typography>
          <Typography variant="caption" color="error">
            This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDeleteDialog}>Cancel</Button>
          <Button onClick={handleDeleteUser} color="error" variant="contained">
            Delete
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar for notifications */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={3000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert severity={snackbar.severity} sx={{ width: '100%' }}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}

// User Table Component
interface UserTableProps {
  users: User[];
  onEdit: (user: User) => void;
  onDelete: (user: User) => void;
  onToggleActive?: (user: User) => void;
  getRoleChipColor: (role: string) => { bg: string; color: string };
  getStatusChip: (status: string) => JSX.Element | null;
}

function UserTable({ users, onEdit, onDelete, onToggleActive, getRoleChipColor, getStatusChip }: UserTableProps) {
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';
  return (
    <TableContainer>
      <Table>
        <TableHead sx={{ bgcolor: isDark ? alpha(theme.palette.text.primary, 0.06) : '#f5f5f5' }}>
          <TableRow>
            <TableCell>User</TableCell>
            <TableCell>Contact</TableCell>
            <TableCell>Role</TableCell>
            <TableCell>Apartment</TableCell>
            <TableCell>Status</TableCell>
            <TableCell>Join Date</TableCell>
            <TableCell align="center">Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {users.length === 0 ? (
            <TableRow>
              <TableCell colSpan={7} align="center" sx={{ py: 3 }}>
                <Typography color="textSecondary">No users found</Typography>
              </TableCell>
            </TableRow>
          ) : (
            users.map((user) => (
              <TableRow key={user.id} hover>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <Avatar sx={{ bgcolor: '#034808', mr: 2 }}>
                      {user.name.charAt(0)}
                    </Avatar>
                    <Box>
                      <Typography variant="body2" fontWeight={500}>
                        {user.name}
                      </Typography>
                      <Typography variant="caption" color="textSecondary">
                        ID: {user.id}
                      </Typography>
                    </Box>
                  </Box>
                </TableCell>
                <TableCell>
                  <Typography variant="body2">{user.email}</Typography>
                  <Typography variant="caption" color="textSecondary">
                    {user.phone}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip
                    label={user.role.charAt(0).toUpperCase() + user.role.slice(1)}
                    size="small"
                    sx={{
                      bgcolor: getRoleChipColor(user.role).bg,
                      color: getRoleChipColor(user.role).color,
                      fontWeight: 500,
                    }}
                  />
                </TableCell>
                <TableCell>
                  {user.apartment ? (
                    <Chip label={user.apartment} size="small" variant="outlined" />
                  ) : (
                    <Typography variant="caption" color="textSecondary">—</Typography>
                  )}
                </TableCell>
                <TableCell>{getStatusChip(user.status)}</TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {new Date(user.joinDate).toLocaleDateString()}
                  </Typography>
                </TableCell>
                <TableCell align="center">
                  <IconButton
                    size="small"
                    onClick={() => onToggleActive && onToggleActive(user)}
                    sx={{ color: user.status === 'active' ? '#4CAF50' : '#9E9E9E', mr: 1 }}
                  >
                    {user.status === 'active' ? <ToggleOffIcon /> : <ToggleOnIcon />}
                  </IconButton>
                  <IconButton
                    size="small"
                    onClick={() => onEdit(user)}
                    sx={{ color: '#034808', mr: 1 }}
                  >
                    <EditIcon />
                  </IconButton>
                  <IconButton
                    size="small"
                    onClick={() => onDelete(user)}
                    sx={{ color: '#f44336' }}
                  >
                    <DeleteIcon />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>
    </TableContainer>
  );
}