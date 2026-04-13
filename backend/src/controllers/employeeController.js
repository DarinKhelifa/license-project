const Employee = require('../models/Employee');
const path = require('path');

// GET /api/employees — return all employees
const getAllEmployees = async (req, res) => {
  try {
    const employees = await Employee.find().sort({ createdAt: -1 });
    res.json({ success: true, employees });
  } catch (err) {
    console.error('getAllEmployees error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
};

// POST /api/employees — create employee with optional file uploads
const createEmployee = async (req, res) => {
  try {
    const {
      firstName,
      lastName,
      cinId,
      address,
      phone,
      email,
      workCategory,
      experience,
    } = req.body;

    // Validate required fields
    if (!firstName || !lastName || !cinId || !address || !phone || !email || !workCategory || !experience) {
      return res.status(400).json({ success: false, error: 'All fields are required' });
    }

    const photo = req.files?.photo?.[0]?.filename || '';
    const casierJudiciaire = req.files?.casierJudiciaire?.[0]?.filename || '';

    const employee = new Employee({
      firstName,
      lastName,
      cinId,
      address,
      phone,
      email,
      workCategory,
      experience,
      photo,
      casierJudiciaire,
    });

    const saved = await employee.save();
    res.status(201).json({ success: true, employee: saved });
  } catch (err) {
    console.error('createEmployee error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
};

// DELETE /api/employees/:id — remove employee
const deleteEmployee = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await Employee.findByIdAndDelete(id);
    if (!deleted) {
      return res.status(404).json({ success: false, error: 'Employee not found' });
    }
    res.json({ success: true, message: 'Employee deleted successfully' });
  } catch (err) {
    console.error('deleteEmployee error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
};

module.exports = { getAllEmployees, createEmployee, deleteEmployee };
