import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { Box, Typography, Paper, Button } from '@mui/material';
import { request } from '../services/api';

type GuestFull = {
  guestId: string;
  name?: string;
  phone?: string;
  email?: string;
  visitDate?: string;
  host?: string;
  qrCode?: string; // base64 image
  status?: string;
  createdAt?: string;
};

export default function GuestDetail() {
  const { guestId } = useParams<{ guestId: string }>();
  const [guest, setGuest] = useState<GuestFull | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!guestId) return;
    const fetchGuest = async () => {
      try {
        const data = await request<{ success: boolean; guest: any }>(`/guests/${guestId}`);
        setGuest(data?.guest ?? null);
      } catch (err) {
        console.error('Failed to fetch guest', err);
      } finally {
        setLoading(false);
      }
    };
    fetchGuest();
  }, [guestId]);

  if (loading) return <Typography>Loading...</Typography>;
  if (!guest) return <Typography>Guest not found</Typography>;

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 2, fontWeight: 900 }}>Guest: {guest.name}</Typography>
      <Paper sx={{ p: 2 }}>
        <Typography><strong>Host:</strong> {guest.host}</Typography>
        <Typography><strong>Visit:</strong> {guest.visitDate}</Typography>
        <Typography><strong>Phone:</strong> {guest.phone}</Typography>
        <Typography><strong>Email:</strong> {guest.email}</Typography>
        <Typography><strong>Status:</strong> {guest.status}</Typography>
        {guest.qrCode && (
          <Box sx={{ mt: 2 }}>
            <Typography sx={{ mb: 1 }}>Guest QR:</Typography>
            <img src={guest.qrCode} alt="Guest QR" style={{ maxWidth: 320 }} />
          </Box>
        )}
      </Paper>
      <Box sx={{ mt: 2 }}>
        {guest.qrCode ? (
          <Button variant="contained" component="a" href={guest.qrCode} target="_blank" rel="noreferrer">
            Open QR Image
          </Button>
        ) : (
          <Button variant="contained" disabled>No QR</Button>
        )}
      </Box>
    </Box>
  );
}
