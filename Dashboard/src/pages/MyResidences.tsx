import React, { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Avatar,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  FormControl,
  Grid,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Stack,
  Tab,
  Tabs,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import { alpha, useTheme } from '@mui/material/styles';
import {
  Add as AddIcon,
  AddBusiness as AddBusinessIcon,
  Apartment as ApartmentIcon,
  CheckCircle as CheckCircleIcon,
  LocalParking as LocalParkingIcon,
  LocationOn as LocationOnIcon,
  PendingActions as PendingActionsIcon,
} from '@mui/icons-material';
import {
  Residence,
  ReservationStatus,
  residencesAPI,
} from '../services/residences';
import { adminAPI } from '../services/api';

type TabValue = 'overview' | 'buildings' | 'parking' | 'reservations' | 'residents';

function statusChipColor(status: ReservationStatus): 'warning' | 'success' | 'error' {
  if (status === 'approved') return 'success';
  if (status === 'denied') return 'error';
  return 'warning';
}

export default function MyResidences() {
  const theme = useTheme();

  const [residences, setResidences] = useState<Residence[]>([]);
  const [activeResidenceId, setActiveResidenceId] = useState<string>('');
  const [activeTab, setActiveTab] = useState<TabValue>('overview');
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [saving, setSaving] = useState<boolean>(false);

  const [buildingName, setBuildingName] = useState('');
  const [buildingApartments, setBuildingApartments] = useState<number>(40);

  const [newSpotCount, setNewSpotCount] = useState<number>(10);

  const [reservationResident, setReservationResident] = useState('');
  const [reservationApartment, setReservationApartment] = useState('');
  const [reservationBuilding, setReservationBuilding] = useState('');
  const [reservationSpotCode, setReservationSpotCode] = useState('');

  // Create residence dialog
  const [openCreateDialog, setOpenCreateDialog] = useState(false);
  const [newResidenceName, setNewResidenceName] = useState('');
  const [newResidenceAddress, setNewResidenceAddress] = useState('');
  const [newResidenceBuildingCount, setNewResidenceBuildingCount] = useState<number>(1);
  const [newResidenceApartmentsPerBuilding, setNewResidenceApartmentsPerBuilding] = useState<number>(40);
  const [newResidenceParkingCount, setNewResidenceParkingCount] = useState<number>(40);

  // Residents list
  const [residents, setResidents] = useState<any[]>([]);
  const [residentsLoading, setResidentsLoading] = useState(false);

  const activeResidence = useMemo(
    () => residences.find((r) => r._id === activeResidenceId) ?? residences[0],
    [activeResidenceId, residences]
  );

  const allStats = useMemo(() => {
    const totalBuildings = residences.reduce((sum, r) => sum + r.buildings.length, 0);
    const totalApartments = residences.reduce(
      (sum, r) => sum + r.buildings.reduce((inner, b) => inner + b.apartments, 0),
      0
    );
    const totalParkingSpots = residences.reduce((sum, r) => sum + r.parkingSpots.length, 0);
    const totalPendingReservations = residences.reduce(
      (sum, r) => sum + r.reservations.filter((item) => item.status === 'pending').length,
      0
    );

    return {
      totalBuildings,
      totalApartments,
      totalParkingSpots,
      totalPendingReservations,
    };
  }, [residences]);

  async function fetchResidences() {
    setLoading(true);
    setError(null);
    try {
      const data = await residencesAPI.list();
      setResidences(data.residences);
      if (!activeResidenceId || !data.residences.some((r) => r._id === activeResidenceId)) {
        setActiveResidenceId(data.residences[0]?._id ?? '');
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load residences');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void fetchResidences();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (activeTab === 'residents' && activeResidenceId) {
      loadResidents();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab, activeResidenceId]);

  async function loadResidents() {
    setResidentsLoading(true);
    try {
      const allUsers = await adminAPI.getAllUsers();
      const residentsInActiveResidence = allUsers.filter(
        (user: any) => user.role === 'resident' && user.residence === activeResidenceId
      );
      setResidents(residentsInActiveResidence);
    } catch (e) {
      console.error('Failed to load residents:', e);
    } finally {
      setResidentsLoading(false);
    }
  }

  async function handleAddBuilding() {
    if (!activeResidence) return;
    if (!buildingName.trim()) {
      setMessage('Please enter a building name.');
      return;
    }
    if (buildingApartments <= 0) {
      setMessage('Apartments per building must be greater than 0.');
      return;
    }

    setSaving(true);
    try {
      const result = await residencesAPI.addBuilding(activeResidence._id, {
        name: buildingName.trim(),
        apartments: buildingApartments,
      });

      setResidences((prev) =>
        prev.map((residence) =>
          residence._id === result.residence._id ? result.residence : residence
        )
      );
      setBuildingName('');
      setBuildingApartments(40);
      setMessage('Building added successfully.');
    } catch (e) {
      setMessage(e instanceof Error ? e.message : 'Failed to add building');
    } finally {
      setSaving(false);
    }
  }

  async function handleAddParkingSpots() {
    if (!activeResidence) return;
    if (newSpotCount <= 0) {
      setMessage('Number of parking spots must be greater than 0.');
      return;
    }

    setSaving(true);
    try {
      const result = await residencesAPI.addParkingSpots(activeResidence._id, {
        count: newSpotCount,
      });

      setResidences((prev) =>
        prev.map((residence) =>
          residence._id === result.residence._id ? result.residence : residence
        )
      );

      setNewSpotCount(10);
      setMessage(`${result.addedCount} parking spot(s) added.`);
    } catch (e) {
      setMessage(e instanceof Error ? e.message : 'Failed to add parking spots');
    } finally {
      setSaving(false);
    }
  }

  async function handleCreateReservation() {
    if (!activeResidence) return;

    if (
      !reservationResident.trim() ||
      !reservationApartment.trim() ||
      !reservationBuilding.trim() ||
      !reservationSpotCode.trim()
    ) {
      setMessage('Please complete all reservation fields.');
      return;
    }

    setSaving(true);
    try {
      const result = await residencesAPI.createReservation(activeResidence._id, {
        residentName: reservationResident.trim(),
        apartmentRef: reservationApartment.trim(),
        buildingRef: reservationBuilding.trim(),
        spotCode: reservationSpotCode.trim(),
      });

      setResidences((prev) =>
        prev.map((residence) =>
          residence._id === result.residence._id ? result.residence : residence
        )
      );

      setReservationResident('');
      setReservationApartment('');
      setReservationBuilding('');
      setReservationSpotCode('');
      setMessage('Parking reservation request created.');
    } catch (e) {
      setMessage(e instanceof Error ? e.message : 'Failed to create reservation');
    } finally {
      setSaving(false);
    }
  }

  async function handleReservationDecision(
    reservationId: string,
    status: Extract<ReservationStatus, 'approved' | 'denied'>
  ) {
    if (!activeResidence) return;

    setSaving(true);
    try {
      const result = await residencesAPI.updateReservationStatus(
        activeResidence._id,
        reservationId,
        { status }
      );

      setResidences((prev) =>
        prev.map((residence) =>
          residence._id === result.residence._id ? result.residence : residence
        )
      );

      setMessage(`Reservation ${status}.`);
    } catch (e) {
      setMessage(e instanceof Error ? e.message : 'Failed to update reservation status');
    } finally {
      setSaving(false);
    }
  }

  async function handleCreateResidence() {
    if (!newResidenceName.trim() || !newResidenceAddress.trim()) {
      setMessage('Please fill in residence name and address.');
      return;
    }

    if (
      newResidenceBuildingCount <= 0 ||
      newResidenceApartmentsPerBuilding <= 0 ||
      newResidenceParkingCount <= 0
    ) {
      setMessage('Counts must be greater than 0.');
      return;
    }

    setSaving(true);
    try {
      const result = await residencesAPI.create({
        name: newResidenceName.trim(),
        address: newResidenceAddress.trim(),
        buildingCount: newResidenceBuildingCount,
        apartmentsPerBuilding: newResidenceApartmentsPerBuilding,
        parkingCount: newResidenceParkingCount,
      });

      setResidences((prev) => [...prev, result.residence]);
      setActiveResidenceId(result.residence._id);
      setActiveTab('overview');

      setNewResidenceName('');
      setNewResidenceAddress('');
      setNewResidenceBuildingCount(1);
      setNewResidenceApartmentsPerBuilding(40);
      setNewResidenceParkingCount(40);
      setMessage('New residence created successfully.');
    } catch (e) {
      setMessage(e instanceof Error ? e.message : 'Failed to create residence');
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <Box sx={{ py: 8, display: 'flex', justifyContent: 'center' }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" action={<Button color="inherit" size="small" onClick={() => void fetchResidences()}>Retry</Button>}>
        {error}
      </Alert>
    );
  }

  if (!activeResidence) {
    return <Alert severity="error">No residence available. Please add a residence first.</Alert>;
  }

  const availableSpots = activeResidence.parkingSpots.filter((spot) => spot.status === 'available').length;
  const pendingReservations = activeResidence.reservations.filter((item) => item.status === 'pending').length;

  return (
    <Box>
      <Stack
        direction={{ xs: 'column', md: 'row' }}
        spacing={1.5}
        alignItems={{ xs: 'flex-start', md: 'center' }}
        sx={{ mb: 3 }}
      >
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Typography variant="h4" sx={{ mb: 0.4 }}>
            My Residences
          </Typography>
          <Typography sx={{ color: 'text.secondary', fontWeight: 650 }}>
            Manage all Orelax residences, buildings, apartments, parking spots, and resident parking reservations.
          </Typography>
        </Box>
        <Stack direction="row" spacing={1} alignItems="center">
          <Button
            variant="contained"
            startIcon={<AddBusinessIcon />}
            onClick={() => setOpenCreateDialog(true)}
            sx={{ bgcolor: '#034808', '&:hover': { bgcolor: '#023206' } }}
          >
            Add New Residence
          </Button>
          <Chip
            icon={<AddBusinessIcon />}
            label={`${residences.length} residence(s)`}
            sx={{
              bgcolor: alpha(theme.palette.primary.main, 0.06),
              border: `1px solid ${alpha(theme.palette.primary.main, 0.14)}`,
              fontWeight: 800,
            }}
          />
        </Stack>
      </Stack>

      {message ? (
        <Alert severity="info" onClose={() => setMessage(null)} sx={{ mb: 2 }}>
          {message}
        </Alert>
      ) : null}

      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Stack spacing={0.8}>
                <Typography color="text.secondary">Total Buildings</Typography>
                <Typography variant="h5" sx={{ fontWeight: 900 }}>{allStats.totalBuildings}</Typography>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Stack spacing={0.8}>
                <Typography color="text.secondary">Total Apartments</Typography>
                <Typography variant="h5" sx={{ fontWeight: 900 }}>{allStats.totalApartments}</Typography>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Stack spacing={0.8}>
                <Typography color="text.secondary">Parking Spots</Typography>
                <Typography variant="h5" sx={{ fontWeight: 900 }}>{allStats.totalParkingSpots}</Typography>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Stack spacing={0.8}>
                <Typography color="text.secondary">Pending Reservations</Typography>
                <Typography variant="h5" sx={{ fontWeight: 900 }}>{allStats.totalPendingReservations}</Typography>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Paper sx={{ p: 2.2, mb: 2.2 }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems={{ xs: 'stretch', md: 'center' }}>
          <FormControl sx={{ minWidth: 280 }}>
            <InputLabel id="residence-selector">Select Residence</InputLabel>
            <Select
              labelId="residence-selector"
              label="Select Residence"
              value={activeResidence._id}
              onChange={(event) => setActiveResidenceId(event.target.value)}
            >
              {residences.map((residence) => (
                <MenuItem key={residence._id} value={residence._id}>
                  {residence.name}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
            <Chip icon={<LocationOnIcon />} label={activeResidence.address} />
            <Chip icon={<ApartmentIcon />} label={`${activeResidence.buildings.length} buildings`} />
            <Chip icon={<LocalParkingIcon />} label={`${activeResidence.parkingSpots.length} parking spots`} />
            <Chip icon={<PendingActionsIcon />} label={`${pendingReservations} pending`} color="warning" />
          </Stack>
        </Stack>
      </Paper>

      <Paper sx={{ mb: 2.2 }}>
        <Tabs
          value={activeTab}
          onChange={(_, value: TabValue) => setActiveTab(value)}
          variant="scrollable"
          scrollButtons="auto"
        >
          <Tab value="overview" label="Overview" />
          <Tab value="buildings" label="Buildings" />
          <Tab value="parking" label="Parking" />
          <Tab value="reservations" label="Reservations" />
          <Tab value="residents" label="Residents" />
        </Tabs>
      </Paper>

      {activeTab === 'overview' ? (
        <Grid container spacing={2}>
          <Grid item xs={12} md={6}>
            <Card sx={{ height: '100%' }}>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 1.2 }}>Residence Information</Typography>
                <Divider sx={{ mb: 1.5 }} />
                <Stack spacing={1}>
                  <Typography><strong>Name:</strong> {activeResidence.name}</Typography>
                  <Typography><strong>Address:</strong> {activeResidence.address}</Typography>
                  <Typography><strong>Buildings:</strong> {activeResidence.buildings.length}</Typography>
                  <Typography><strong>Total Apartments:</strong> {activeResidence.buildings.reduce((sum, b) => sum + b.apartments, 0)}</Typography>
                  <Typography><strong>Parking Spots:</strong> {activeResidence.parkingSpots.length}</Typography>
                  <Typography><strong>Available Spots:</strong> {availableSpots}</Typography>
                </Stack>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} md={6}>
            <Card sx={{ height: '100%' }}>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 1.2 }}>Reservations Summary</Typography>
                <Divider sx={{ mb: 1.5 }} />
                <Stack direction="row" spacing={1.2} flexWrap="wrap" useFlexGap>
                  <Chip label={`Pending: ${activeResidence.reservations.filter((item) => item.status === 'pending').length}`} color="warning" />
                  <Chip label={`Approved: ${activeResidence.reservations.filter((item) => item.status === 'approved').length}`} color="success" />
                  <Chip label={`Denied: ${activeResidence.reservations.filter((item) => item.status === 'denied').length}`} color="error" />
                </Stack>
                <Typography sx={{ mt: 2, color: 'text.secondary' }}>
                  You can approve or deny resident parking requests in the Reservations tab.
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      ) : null}

      {activeTab === 'buildings' ? (
        <Grid container spacing={2}>
          <Grid item xs={12} lg={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 1.5 }}>Add Building</Typography>
                <Stack spacing={1.5}>
                  <TextField
                    label="Building Name"
                    value={buildingName}
                    onChange={(event) => setBuildingName(event.target.value)}
                    placeholder="Example: Building 41"
                  />
                  <TextField
                    label="Apartments"
                    type="number"
                    value={buildingApartments}
                    onChange={(event) => setBuildingApartments(Number(event.target.value))}
                    inputProps={{ min: 1 }}
                  />
                  <Button variant="contained" onClick={() => void handleAddBuilding()} disabled={saving}>Add Building</Button>
                </Stack>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} lg={8}>
            <Card>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 1.5 }}>Buildings List</Typography>
                <TableContainer sx={{ maxHeight: 420 }}>
                  <Table stickyHeader size="small">
                    <TableHead>
                      <TableRow>
                        <TableCell>Building</TableCell>
                        <TableCell align="right">Apartments</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {activeResidence.buildings.map((building) => (
                        <TableRow key={building.id} hover>
                          <TableCell>{building.name}</TableCell>
                          <TableCell align="right">{building.apartments}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      ) : null}

      {activeTab === 'parking' ? (
        <Grid container spacing={2}>
          <Grid item xs={12} lg={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 1.5 }}>Add Parking Spots</Typography>
                <Stack spacing={1.5}>
                  <TextField
                    label="How many new spots?"
                    type="number"
                    value={newSpotCount}
                    onChange={(event) => setNewSpotCount(Number(event.target.value))}
                    inputProps={{ min: 1 }}
                  />
                  <Button variant="contained" onClick={() => void handleAddParkingSpots()} disabled={saving}>Add Spots</Button>
                </Stack>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} lg={8}>
            <Card>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 1.5 }}>Parking Spots</Typography>
                <TableContainer sx={{ maxHeight: 420 }}>
                  <Table stickyHeader size="small">
                    <TableHead>
                      <TableRow>
                        <TableCell>Spot Code</TableCell>
                        <TableCell>Status</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {activeResidence.parkingSpots.map((spot) => (
                        <TableRow key={spot.id} hover>
                          <TableCell>{spot.code}</TableCell>
                          <TableCell>
                            <Chip
                              size="small"
                              color={spot.status === 'available' ? 'success' : 'warning'}
                              label={spot.status}
                            />
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      ) : null}

      {activeTab === 'reservations' ? (
        <Grid container spacing={2}>
          <Grid item xs={12} lg={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 1.5 }}>New Reservation Request</Typography>
                <Stack spacing={1.5}>
                  <TextField
                    label="Resident Name"
                    value={reservationResident}
                    onChange={(event) => setReservationResident(event.target.value)}
                  />
                  <TextField
                    label="Apartment"
                    value={reservationApartment}
                    onChange={(event) => setReservationApartment(event.target.value)}
                    placeholder="Example: A-14"
                  />
                  <TextField
                    label="Building"
                    value={reservationBuilding}
                    onChange={(event) => setReservationBuilding(event.target.value)}
                    placeholder="Example: Building 03"
                  />
                  <TextField
                    label="Requested Spot Code"
                    value={reservationSpotCode}
                    onChange={(event) => setReservationSpotCode(event.target.value)}
                    placeholder="Example: P-010"
                  />
                  <Button variant="contained" onClick={() => void handleCreateReservation()} disabled={saving}>Create Request</Button>
                </Stack>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} lg={8}>
            <Card>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 1.5 }}>Reservation Management</Typography>
                <TableContainer sx={{ maxHeight: 460 }}>
                  <Table stickyHeader size="small">
                    <TableHead>
                      <TableRow>
                        <TableCell>Resident</TableCell>
                        <TableCell>Apartment</TableCell>
                        <TableCell>Building</TableCell>
                        <TableCell>Spot</TableCell>
                        <TableCell>Status</TableCell>
                        <TableCell align="right">Actions</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {activeResidence.reservations.length === 0 ? (
                        <TableRow>
                          <TableCell colSpan={6}>
                            <Typography color="text.secondary">No reservation requests yet.</Typography>
                          </TableCell>
                        </TableRow>
                      ) : (
                        activeResidence.reservations.map((item) => (
                          <TableRow key={item._id} hover>
                            <TableCell>{item.residentName}</TableCell>
                            <TableCell>{item.apartmentRef}</TableCell>
                            <TableCell>{item.buildingRef}</TableCell>
                            <TableCell>{item.spotCode}</TableCell>
                            <TableCell>
                              <Chip size="small" color={statusChipColor(item.status)} label={item.status} />
                            </TableCell>
                            <TableCell align="right">
                              <Stack direction="row" spacing={1} justifyContent="flex-end">
                                <Button
                                  size="small"
                                  color="success"
                                  variant="contained"
                                  startIcon={<CheckCircleIcon />}
                                  disabled={item.status === 'approved' || saving}
                                  onClick={() => void handleReservationDecision(item._id, 'approved')}
                                >
                                  Approve
                                </Button>
                                <Button
                                  size="small"
                                  color="error"
                                  variant="outlined"
                                  disabled={item.status === 'denied' || saving}
                                  onClick={() => void handleReservationDecision(item._id, 'denied')}
                                >
                                  Deny
                                </Button>
                              </Stack>
                            </TableCell>
                          </TableRow>
                        ))
                      )}
                    </TableBody>
                  </Table>
                </TableContainer>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      ) : null}

      {activeTab === 'residents' ? (
        <Card>
          <CardContent>
            <Typography variant="h6" sx={{ mb: 1.5 }}>Residents in {activeResidence?.name || 'This Residence'}</Typography>
            {residentsLoading ? (
              <Box sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
                <CircularProgress />
              </Box>
            ) : (
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Name</TableCell>
                      <TableCell>Email</TableCell>
                      <TableCell>Phone</TableCell>
                      <TableCell>Building</TableCell>
                      <TableCell>Apartment</TableCell>
                      <TableCell>Status</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {residents.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={6}>
                          <Typography color="text.secondary" sx={{ py: 2 }}>No residents in this residence yet.</Typography>
                        </TableCell>
                      </TableRow>
                    ) : (
                      residents.map((resident: any) => (
                        <TableRow key={resident._id} hover>
                          <TableCell>
                            <Stack direction="row" alignItems="center" spacing={1}>
                              <Avatar sx={{ width: 32, height: 32, bgcolor: '#034808', fontSize: '0.875rem' }}>
                                {resident.name?.charAt(0) || 'R'}
                              </Avatar>
                              <Typography variant="body2" sx={{ fontWeight: 500 }}>{resident.name}</Typography>
                            </Stack>
                          </TableCell>
                          <TableCell>{resident.email}</TableCell>
                          <TableCell>{resident.phone}</TableCell>
                          <TableCell>{resident.building || '--'}</TableCell>
                          <TableCell>{resident.apartment || '--'}</TableCell>
                          <TableCell>
                            <Chip
                              size="small"
                              label={resident.status}
                              color={resident.status === 'active' ? 'success' : 'warning'}
                            />
                          </TableCell>
                        </TableRow>
                      ))
                    )}
                  </TableBody>
                </Table>
              </TableContainer>
            )}
          </CardContent>
        </Card>
      ) : null}

      {/* Create Residence Dialog */}
      <Dialog open={openCreateDialog} onClose={() => setOpenCreateDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ bgcolor: '#034808', color: 'white' }}>Create New Residence</DialogTitle>
        <DialogContent sx={{ pt: 3 }}>
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Residence Name"
                value={newResidenceName}
                onChange={(event) => setNewResidenceName(event.target.value)}
                placeholder="Example: Orelax Residence Downtown"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Address"
                value={newResidenceAddress}
                onChange={(event) => setNewResidenceAddress(event.target.value)}
                placeholder="Example: Ali Mendjli"
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                type="number"
                label="Number of Buildings"
                value={newResidenceBuildingCount}
                onChange={(event) => setNewResidenceBuildingCount(Number(event.target.value))}
                inputProps={{ min: 1 }}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                type="number"
                label="Apartments per Building"
                value={newResidenceApartmentsPerBuilding}
                onChange={(event) => setNewResidenceApartmentsPerBuilding(Number(event.target.value))}
                inputProps={{ min: 1 }}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                type="number"
                label="Initial Parking Spots"
                value={newResidenceParkingCount}
                onChange={(event) => setNewResidenceParkingCount(Number(event.target.value))}
                inputProps={{ min: 1 }}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenCreateDialog(false)}>Cancel</Button>
          <Button
            onClick={() => void handleCreateResidence()}
            disabled={saving}
            variant="contained"
            sx={{ bgcolor: '#034808', '&:hover': { bgcolor: '#023206' } }}
          >
            Create Residence
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
