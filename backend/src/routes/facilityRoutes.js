const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  createFacility,
  getAllFacilities,
  getFacilityById,
  updateFacility,
  deleteFacility,
} = require('../controllers/facilityController');

// Public routes (residents can view)
router.get('/', getAllFacilities);
router.get('/:id', getFacilityById);

// Admin/Facility Manager only routes
router.post('/', protect, authorize('admin', 'facilities_manager'), createFacility);
router.put('/:id', protect, authorize('admin', 'facilities_manager'), updateFacility);
router.delete('/:id', protect, authorize('admin', 'facilities_manager'), deleteFacility);

module.exports = router;