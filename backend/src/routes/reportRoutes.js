const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  createReport,
  getMyReports,
  getReportById,
  getAllReports,
  updateReportStatus,
  deleteReport,
} = require('../controllers/reportController');

// User routes
router.post('/', protect, createReport);
router.get('/my-reports', protect, getMyReports);
router.get('/:id', protect, getReportById);

// Admin/Maintenance/Security routes
router.get('/admin/all', protect, authorize('admin', 'maintenance', 'security'), getAllReports);
router.put('/:id/status', protect, authorize('admin', 'maintenance', 'security'), updateReportStatus);
router.delete('/:id', protect, authorize('admin'), deleteReport);

module.exports = router;