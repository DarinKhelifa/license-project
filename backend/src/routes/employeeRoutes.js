const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { getAllEmployees, getEmployeeById, createEmployee, deleteEmployee } = require('../controllers/employeeController');

// Multer storage — save to /uploads folder
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  },
});

const fileFilter = (req, file, cb) => {
  if (file.fieldname === 'casierJudiciaire') {
    // Only allow PDF for criminal record
    if (file.mimetype === 'application/pdf') {
      cb(null, true);
    } else {
      cb(new Error('Criminal record must be a PDF file'), false);
    }
  } else {
    // Allow images for photo
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Photo must be an image file'), false);
    }
  }
};

const upload = multer({ storage, fileFilter });

// Routes
router.get('/', getAllEmployees);
router.get('/:id', getEmployeeById);
router.post(
  '/',
  upload.fields([
    { name: 'photo', maxCount: 1 },
    { name: 'casierJudiciaire', maxCount: 1 },
  ]),
  createEmployee
);
router.delete('/:id', deleteEmployee);

module.exports = router;
