import React, { useState, useEffect } from 'react';
import Grid from '@mui/material/Grid';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
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
} from '@mui/icons-material';
import { useAuth } from '../context/AuthContext';

// Types
interface User {
  id: string;
  name: string;
  email: string;
  phone: string;
  role: 'resident' | 'security' | 'admin' | 'maintenance';
  apartment?: string;
  status: 'active' | 'inactive' | 'pending';
  joinDate: string;
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
  const {
    user,
    getAllUsers,
    updateUserRole,
    updateUserStatus,
    deleteUser,
    createUser,
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
  
  // Form state
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    role: 'resident' as User['role'],
    apartment: '',
    status: 'active' as User['status'],
  });

  // Check if current user is admin
  const isAdmin = user?.role === 'admin';

  // Load users from API
  const loadUsers = async () => {
    setLoading(true);
    try {
      const allUsers = await getAllUsers();
      const formattedUsers: User[] = allUsers.map(u => ({
        id: u.id || u.uid,
        name: u.name,
        email: u.email,
        phone: u.phone,
        role: u.role,
        apartment: u.apartment,
        status: u.status,
        joinDate: u.joinDate,
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
  };

  useEffect(() => {
    if (isAdmin) {
      loadUsers();
    }
  }, [isAdmin]);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleOpenAddDialog = () => {
    setEditingUser(null);
    setFormData({
      name: '',
      email: '',
      phone: '',
      role: 'resident',
      apartment: '',
      status: 'active',
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
      apartment: user.apartment || '',
      status: user.status,
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

    try {
      if (editingUser) {
        // Update existing user
        await updateUserRole(editingUser.id, formData.role);
        await updateUserStatus(editingUser.id, formData.status);
        await loadUsers();
        setSnackbar({
          open: true,
          message: `User ${formData.name} updated successfully`,
          severity: 'success',
        });
      } else {
        // Add new user
        await createUser({
          name: formData.name,
          email: formData.email,
          phone: formData.phone,
          role: formData.role,
          apartment: formData.apartment,
          status: formData.status,
        });
        await loadUsers();
        setSnackbar({
          open: true,
          message: `User ${formData.name} added successfully`,
          severity: 'success',
        });
      }
      handleCloseDialog();
    } catch (error) {
      setSnackbar({
        open: true,
        message: 'Failed to save user',
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
    
    if (tabValue === 0) return matchesSearch; // All
    if (tabValue === 1) return matchesSearch && user.role === 'resident';
    if (tabValue === 2) return matchesSearch && ['security', 'admin', 'maintenance'].includes(user.role);
    return matchesSearch;
  });

  const getRoleChipColor = (role: string) => {
    switch(role) {
      case 'admin': return { bg: '#034808', color: 'white' };
      case 'security': return { bg: '#FFD700', color: '#034808' };
      case 'maintenance': return { bg: '#FF6B6B', color: 'white' };
      default: return { bg: '#E0E0E0', color: '#333' };
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
        <Typography variant="h4" sx={{ color: '#034808' }}>
          Manage Accounts
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleOpenAddDialog}
          sx={{
            bgcolor: '#034808',
            '&:hover': { bgcolor: '#023206' }
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
                startAdornment: <SearchIcon sx={{ mr: 1, color: 'gray' }} />,
              }}
            />
          </Grid>
          <Grid item xs={12} md={6}>
            <Box sx={{ display: 'flex', gap: 1, justifyContent: 'flex-end' }}>
              <Chip
                icon={<PersonIcon />}
                label={`Total: ${users.length}`}
                sx={{ bgcolor: '#034808', color: 'white' }}
              />
              <Chip
                icon={<PersonIcon />}
                label={`Residents: ${users.filter(u => u.role === 'resident').length}`}
                sx={{ bgcolor: '#FFD700', color: '#034808' }}
              />
              <Chip
                icon={<SecurityIcon />}
                label={`Staff: ${users.filter(u => u.role !== 'resident').length}`}
                sx={{ bgcolor: '#E0E0E0' }}
              />
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
            '& .MuiTab-root.Mui-selected': { color: '#034808' },
            '& .MuiTabs-indicator': { bgcolor: '#034808' },
          }}
        >
          <Tab label="All Accounts" />
          <Tab label="Residents" />
          <Tab label="Employees" />
        </Tabs>

        {/* All Accounts Tab */}
        <TabPanel value={tabValue} index={0}>
          <UserTable
            users={filteredUsers}
            onEdit={handleOpenEditDialog}
            onDelete={handleOpenDeleteDialog}
            getRoleChipColor={getRoleChipColor}
            getStatusChip={getStatusChip}
          />
        </TabPanel>

        {/* Residents Tab */}
        <TabPanel value={tabValue} index={1}>
          <UserTable
            users={filteredUsers}
            onEdit={handleOpenEditDialog}
            onDelete={handleOpenDeleteDialog}
            getRoleChipColor={getRoleChipColor}
            getStatusChip={getStatusChip}
          />
        </TabPanel>

        {/* Employees Tab */}
        <TabPanel value={tabValue} index={2}>
          <UserTable
            users={filteredUsers}
            onEdit={handleOpenEditDialog}
            onDelete={handleOpenDeleteDialog}
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
                  <MenuItem value="resident">Resident</MenuItem>
                  <MenuItem value="security">Security</MenuItem>
                  <MenuItem value="admin">Admin</MenuItem>
                  <MenuItem value="maintenance">Maintenance</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={6}>
              <FormControl fullWidth margin="normal">
                <InputLabel>Status</InputLabel>
                <Select
                  value={formData.status}
                  label="Status"
                  onChange={(e) => setFormData({ ...formData, status: e.target.value as User['status'] })}
                >
                  <MenuItem value="active">Active</MenuItem>
                  <MenuItem value="inactive">Inactive</MenuItem>
                  <MenuItem value="pending">Pending</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            {formData.role === 'resident' && (
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Apartment Number"
                  value={formData.apartment}
                  onChange={(e) => setFormData({ ...formData, apartment: e.target.value })}
                  margin="normal"
                />
              </Grid>
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
  getRoleChipColor: (role: string) => { bg: string; color: string };
  getStatusChip: (status: string) => JSX.Element | null;
}

function UserTable({ users, onEdit, onDelete, getRoleChipColor, getStatusChip }: UserTableProps) {
  return (
    <TableContainer>
      <Table>
        <TableHead sx={{ bgcolor: '#f5f5f5' }}>
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