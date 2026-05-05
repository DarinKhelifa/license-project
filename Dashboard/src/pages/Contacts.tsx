import React, { useEffect, useState } from 'react';
import { Box, Paper, Typography, Table, TableHead, TableRow, TableCell, TableBody, TableContainer } from '@mui/material';

export default function Contacts() {
  const [messages, setMessages] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchMessages();
  }, []);

  async function fetchMessages() {
    try {
      const res = await fetch('/api/contacts');
      if (res.ok) {
        const data = await res.json();
        setMessages(data || []);
      }
    } catch (err) {
      console.error('Fetch contacts error', err);
    } finally {
      setLoading(false);
    }
  }

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 2 }}>User Contact Messages</Typography>
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Phone</TableCell>
              <TableCell>Message</TableCell>
              <TableCell>Submitted</TableCell>
              <TableCell>Status</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {messages.map((m) => (
              <TableRow key={m._id}>
                <TableCell>{m.name || 'Anonymous'}</TableCell>
                <TableCell>{m.email}</TableCell>
                <TableCell>{m.phone}</TableCell>
                <TableCell style={{ maxWidth: 420, whiteSpace: 'normal' }}>{m.message}</TableCell>
                <TableCell>{new Date(m.createdAt).toLocaleString()}</TableCell>
                <TableCell>{m.status}</TableCell>
              </TableRow>
            ))}
            {messages.length === 0 && !loading && (
              <TableRow>
                <TableCell colSpan={6} align="center">No messages</TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
}
