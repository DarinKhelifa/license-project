const Residence = require('../models/Residence');

const DEFAULT_RESIDENCES = [
  {
    name: 'Orelax Residence Ali Mendjli',
    address: 'Ali Mendjli',
    buildings: 20,
  },
  {
    name: 'Orelax Residence Zouaghi Seliman',
    address: 'Zouaghi Seliman',
    buildings: 30,
  },
  {
    name: 'Orelax Residence Boussouf',
    address: 'Boussouf',
    buildings: 40,
  },
];

function slugify(input) {
  return String(input || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function createBuildings(prefix, count, apartmentsPerBuilding = 40) {
  return Array.from({ length: count }, (_, index) => {
    const idx = String(index + 1).padStart(2, '0');
    return {
      id: `${prefix}-building-${idx}`,
      name: `Building ${idx}`,
      apartments: apartmentsPerBuilding,
    };
  });
}

function createParkingSpots(prefix, count) {
  return Array.from({ length: count }, (_, index) => {
    const idx = String(index + 1).padStart(3, '0');
    return {
      id: `${prefix}-spot-${idx}`,
      code: `P-${idx}`,
      status: 'available',
    };
  });
}

function createParkingLotsFromSpots(prefix, spots) {
  return [
    {
      id: `${prefix}-lot-01`,
      name: 'Parking 1',
      totalSpots: spots.length,
      spots: spots.map((spot) => ({
        id: spot.id,
        code: spot.code,
        status: spot.status || 'available',
      })),
    },
  ];
}

function defaultParkingCountFromBuildings(buildingCount) {
  // Same ratio used in dashboard defaults: 6 spots per building.
  return Math.max(10, buildingCount * 6);
}

async function ensureDefaultResidences() {
  const count = await Residence.countDocuments();
  if (count > 0) return;

  const docs = DEFAULT_RESIDENCES.map((item) => {
    const prefix = slugify(item.name);
    const parkingSpots = createParkingSpots(prefix, defaultParkingCountFromBuildings(item.buildings));
    return {
      name: item.name,
      address: item.address,
      buildings: createBuildings(prefix, item.buildings, 40),
      parkingSpots,
      parkingLots: createParkingLotsFromSpots(prefix, parkingSpots),
      reservations: [],
    };
  });

  await Residence.insertMany(docs);
}

exports.getResidences = async (req, res) => {
  try {
    await ensureDefaultResidences();
    const residences = await Residence.find().sort({ createdAt: 1 });
    return res.json({ residences });
  } catch (error) {
    console.error('getResidences error:', error);
    return res.status(500).json({ message: 'Failed to load residences' });
  }
};

exports.createResidence = async (req, res) => {
  try {
    const {
      name,
      address,
      buildingCount,
      apartmentsPerBuilding,
      parkingCount,
    } = req.body;

    if (!name || !address) {
      return res.status(400).json({ message: 'Name and address are required' });
    }

    const safeBuildingCount = Number(buildingCount) > 0 ? Number(buildingCount) : 1;
    const safeApartments = Number(apartmentsPerBuilding) > 0 ? Number(apartmentsPerBuilding) : 40;
    const safeParking = Number(parkingCount) > 0 ? Number(parkingCount) : defaultParkingCountFromBuildings(safeBuildingCount);

    const prefix = `${slugify(name)}-${Date.now()}`;
    const parkingSpots = createParkingSpots(prefix, safeParking);

    const residence = await Residence.create({
      name: String(name).trim(),
      address: String(address).trim(),
      buildings: createBuildings(prefix, safeBuildingCount, safeApartments),
      parkingSpots,
      parkingLots: createParkingLotsFromSpots(prefix, parkingSpots),
      reservations: [],
    });

    return res.status(201).json({ message: 'Residence created', residence });
  } catch (error) {
    if (error && error.code === 11000) {
      return res.status(409).json({ message: 'A residence with same name and address already exists' });
    }
    console.error('createResidence error:', error);
    return res.status(500).json({ message: 'Failed to create residence' });
  }
};

exports.addBuilding = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, apartments } = req.body;

    if (!name) {
      return res.status(400).json({ message: 'Building name is required' });
    }

    const safeApartments = Number(apartments) > 0 ? Number(apartments) : 40;

    const residence = await Residence.findById(id);
    if (!residence) return res.status(404).json({ message: 'Residence not found' });

    const building = {
      id: `${residence._id}-building-${Date.now()}`,
      name: String(name).trim(),
      apartments: safeApartments,
    };

    residence.buildings.push(building);
    await residence.save();

    return res.status(201).json({ message: 'Building added', residence });
  } catch (error) {
    console.error('addBuilding error:', error);
    return res.status(500).json({ message: 'Failed to add building' });
  }
};

exports.addParkingSpots = async (req, res) => {
  try {
    const { id } = req.params;
    const { count } = req.body;

    const safeCount = Number(count);
    if (!Number.isFinite(safeCount) || safeCount <= 0) {
      return res.status(400).json({ message: 'A valid parking spot count is required' });
    }

    const residence = await Residence.findById(id);
    if (!residence) return res.status(404).json({ message: 'Residence not found' });

    const start = residence.parkingSpots.length;
    const added = Array.from({ length: safeCount }, (_, index) => {
      const sequence = String(start + index + 1).padStart(3, '0');
      return {
        id: `${residence._id}-spot-${sequence}`,
        code: `P-${sequence}`,
        status: 'available',
      };
    });

    residence.parkingSpots.push(...added);
    if (residence.parkingLots.length === 0) {
      residence.parkingLots.push({
        id: `${residence._id}-lot-01`,
        name: 'Parking 1',
        totalSpots: residence.parkingSpots.length,
        spots: residence.parkingSpots.map((spot) => ({
          id: spot.id,
          code: spot.code,
          status: spot.status,
        })),
      });
    } else if (residence.parkingLots[0]) {
      residence.parkingLots[0].totalSpots = residence.parkingSpots.length;
      residence.parkingLots[0].spots = residence.parkingSpots.map((spot) => ({
        id: spot.id,
        code: spot.code,
        status: spot.status,
      }));
    }
    await residence.save();

    return res.status(201).json({ message: 'Parking spots added', residence, addedCount: added.length });
  } catch (error) {
    console.error('addParkingSpots error:', error);
    return res.status(500).json({ message: 'Failed to add parking spots' });
  }
};

exports.createReservation = async (req, res) => {
  try {
    const { id } = req.params;
    const { residentName, apartmentRef, buildingRef, spotCode } = req.body;

    if (!residentName || !apartmentRef || !buildingRef || !spotCode) {
      return res.status(400).json({ message: 'residentName, apartmentRef, buildingRef, and spotCode are required' });
    }

    const residence = await Residence.findById(id);
    if (!residence) return res.status(404).json({ message: 'Residence not found' });

    const spot = residence.parkingSpots.find((item) => item.code === String(spotCode).trim());
    if (!spot) {
      return res.status(400).json({ message: 'Spot does not exist in this residence' });
    }

    if (spot.status === 'reserved') {
      return res.status(409).json({ message: 'Spot is already reserved' });
    }

    const reservation = {
      residentName: String(residentName).trim(),
      apartmentRef: String(apartmentRef).trim(),
      buildingRef: String(buildingRef).trim(),
      spotCode: String(spotCode).trim(),
      status: 'pending',
      createdAt: new Date(),
    };

    residence.reservations.unshift(reservation);
    await residence.save();

    return res.status(201).json({ message: 'Reservation created', residence });
  } catch (error) {
    console.error('createReservation error:', error);
    return res.status(500).json({ message: 'Failed to create reservation' });
  }
};

exports.updateReservationStatus = async (req, res) => {
  try {
    const { id, reservationId } = req.params;
    const { status } = req.body;

    if (!['approved', 'denied'].includes(status)) {
      return res.status(400).json({ message: "Status must be either 'approved' or 'denied'" });
    }

    const residence = await Residence.findById(id);
    if (!residence) return res.status(404).json({ message: 'Residence not found' });

    const reservation = residence.reservations.id(reservationId);
    if (!reservation) return res.status(404).json({ message: 'Reservation not found' });

    reservation.status = status;

    const spot = residence.parkingSpots.find((item) => item.code === reservation.spotCode);
    if (spot) {
      spot.status = status === 'approved' ? 'reserved' : 'available';
    }

    await residence.save();

    return res.json({ message: `Reservation ${status}`, residence });
  } catch (error) {
    console.error('updateReservationStatus error:', error);
    return res.status(500).json({ message: 'Failed to update reservation status' });
  }
};
