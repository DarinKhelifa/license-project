
const Report = require('../models/Report');
const { v4: uuidv4 } = require('uuid');

// @desc    Create a new report
// @route   POST /api/reports
const createReport = async (req, res) => {
  try {
    const { category, subCategory, location, description, photoBase64, timeIsNow, customTime } = req.body;
    
    const report = new Report({
      id: uuidv4(),
      category,
      subCategory,
      location,
      description,
      photoBase64: photoBase64 || '',
      timeIsNow: timeIsNow !== undefined ? timeIsNow : true,
      customTime: customTime || '',
      status: 'pending',
      createdBy: req.user.id,
      createdByName: req.user.name,
    });
    
    await report.save();
    
    res.status(201).json({
      success: true,
      message: 'Report submitted successfully',
      report
    });
  } catch (error) {
    console.error('Create report error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get user's own reports
// @route   GET /api/reports/my-reports
const getMyReports = async (req, res) => {
  try {
    const reports = await Report.find({ createdBy: req.user.id }).sort({ createdAt: -1 });
    res.json(reports);
  } catch (error) {
    console.error('Get my reports error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get report by ID
// @route   GET /api/reports/:id
const getReportById = async (req, res) => {
  try {
    const report = await Report.findOne({ id: req.params.id });
    if (!report) {
      return res.status(404).json({ message: 'Report not found' });
    }
    res.json(report);
  } catch (error) {
    console.error('Get report error:', error);
    res.status(500).json({ message: error.message });
  }
};

// ========== ADMIN/STAFF FUNCTIONS ==========

// @desc    Get all reports (Admin/Maintenance/Security)
// @route   GET /api/reports/all
const getAllReports = async (req, res) => {
  try {
    const { status, category } = req.query;
    let query = {};
    
    if (status) query.status = status;
    if (category) query.category = category;
    
    const reports = await Report.find(query).sort({ createdAt: -1 });
    res.json(reports);
  } catch (error) {
    console.error('Get all reports error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update report status (Admin/Maintenance/Security)
// @route   PUT /api/reports/:id/status
const updateReportStatus = async (req, res) => {
  try {
    const { status, resolutionNotes } = req.body;
    const report = await Report.findOne({ id: req.params.id });
    
    if (!report) {
      return res.status(404).json({ message: 'Report not found' });
    }
    
    report.status = status;
    if (status === 'resolved') {
      report.resolvedAt = new Date();
      report.resolvedBy = req.user.id;
    }
    if (resolutionNotes) report.resolutionNotes = resolutionNotes;
    
    await report.save();
    
    res.json({ message: `Report ${status} successfully`, report });
  } catch (error) {
    console.error('Update report status error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete report (Admin only)
// @route   DELETE /api/reports/:id
const deleteReport = async (req, res) => {
  try {
    const report = await Report.findOne({ id: req.params.id });
    
    if (!report) {
      return res.status(404).json({ message: 'Report not found' });
    }
    
    await report.deleteOne();
    res.json({ message: 'Report deleted successfully' });
  } catch (error) {
    console.error('Delete report error:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createReport,
  getMyReports,
  getReportById,
  getAllReports,
  updateReportStatus,
  deleteReport,
};