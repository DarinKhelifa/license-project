import React from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Paper from '@mui/material/Paper';
import { Assessment as AssessmentIcon } from '@mui/icons-material';

export default function Report() {
  return (
    <Box>
      {/* Page header */}
      <Typography variant="h4" sx={{ color: '#034808', mb: 4 }}>
        Report
      </Typography>

      <Paper
        sx={{
          borderRadius: 3,
          p: 6,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '50vh',
          boxShadow: '0 2px 12px rgba(0,0,0,0.08)',
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
            mb: 3,
          }}
        >
          <AssessmentIcon sx={{ fontSize: 52, color: '#034808', opacity: 0.45 }} />
        </Box>
        <Typography variant="h5" sx={{ color: '#034808', fontWeight: 600, mb: 1 }}>
          Reports
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Reports coming soon...
        </Typography>
      </Paper>
    </Box>
  );
}
