import React, { useEffect, useState } from 'react';
import { Box, Typography, Paper, List, ListItem, ListItemText, Divider, Button } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { request } from '../services/api';

type Guest = {
  _id: string;
  guestId: string;
  name?: string;
  phone?: string;
  email?: string;
  visitDate?: string;
  host?: string;
  status?: string;
  createdAt?: string;
};

export default function Guests() {
  const [guests, setGuests] = useState<Guest[]>([]);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchGuests = async () => {
      try {
        const data = await request<{ success: boolean; count: number; guests: any[] }>('/guests/admin/all');
        setGuests(data?.guests ?? []);
      } catch (err) {
        console.error('Failed to fetch guests', err);
      }
    };
    fetchGuests();
  }, []);

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 2, fontWeight: 900 }}>Guests</Typography>
      <Paper>
        <List>
          {guests.map((g) => (
            <React.Fragment key={g._id}>
              <ListItem secondaryAction={
                <Button variant="outlined" size="small" onClick={() => navigate(`/guests/${g.guestId}`)}>
                  View
                </Button>
              }>
                <ListItemText
                  primary={g.name ?? 'Guest'}
                  secondary={`${g.phone ?? ''}${g.email ? ` · ${g.email}` : ''} · Host: ${g.host ?? '—'}`}
                />
              </ListItem>
              <Divider />
            </React.Fragment>
          ))}
          {guests.length === 0 && <ListItem><ListItemText primary="No guests yet" /></ListItem>}
        </List>
      </Paper>
    </Box>
  );
}
