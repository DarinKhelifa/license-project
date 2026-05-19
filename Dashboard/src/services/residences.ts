import { request } from './api';

export type ReservationStatus = 'pending' | 'approved' | 'rejected';

export type Building = {
  id: string;
  name: string;
  apartments: number;
};

export type ParkingSpot = {
  id: string;
  code: string;
  status: 'available' | 'reserved';
};

export type ParkingReservation = {
  _id: string;
  residentId?: any;
  residenceId?: any;
  parkingLotId: string;
  residentName: string;
  apartmentRef: string;
  spotCode: string;
  status: ReservationStatus;
  createdAt: string;
  startDate?: string;
  endDate?: string;
  approvedBy?: any;
  approvedAt?: string | null;
  rejectionReason?: string | null;
};

export type Residence = {
  _id: string;
  name: string;
  address: string;
  buildings: Building[];
  parkingSpots: ParkingSpot[];
  reservations: ParkingReservation[];
};

export type Reservation = {
  _id: string;
  residentName: string;
  apartmentRef: string;
  buildingRef: string;
  spotCode: string;
  status: ReservationStatus;
};

export const residencesAPI = {
  list: () => request<{ residences: Residence[] }>('/residences'),

  create: (payload: {
    name: string;
    address: string;
    buildingCount: number;
    apartmentsPerBuilding: number;
    parkingCount: number;
  }) =>
    request<{ message: string; residence: Residence }>('/residences', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),

  addBuilding: (residenceId: string, payload: { name: string; apartments: number }) =>
    request<{ message: string; residence: Residence }>(`/residences/${residenceId}/buildings`, {
      method: 'POST',
      body: JSON.stringify(payload),
    }),

  addParkingSpots: (residenceId: string, payload: { count: number }) =>
    request<{ message: string; residence: Residence; addedCount: number }>(`/residences/${residenceId}/parking-spots`, {
      method: 'POST',
      body: JSON.stringify(payload),
    }),

  createReservation: (
    residenceId: string,
    payload: {
      residentName: string;
      apartmentRef: string;
      buildingRef: string;
      spotCode: string;
    }
  ) =>
    request<{ message: string; residence: Residence }>(`/residences/${residenceId}/reservations`, {
      method: 'POST',
      body: JSON.stringify(payload),
    }),

  updateReservationStatus: (
    residenceId: string,
    reservationId: string,
    payload: { status: 'approved' | 'rejected' }
  ) =>
    request<{ message: string; residence: Residence }>(
      `/residences/${residenceId}/reservations/${reservationId}`,
      {
        method: 'PATCH',
        body: JSON.stringify(payload),
      }
    ),

  getParkingReservations: (residenceId: string) =>
    request<ParkingReservation[]>(`/parking/${residenceId}/reservations`),

  approveParkingReservation: (residenceId: string, reservationId: string) =>
    request<{ success: boolean; message: string; reservation: ParkingReservation }>(
      `/parking/${residenceId}/reservations/${reservationId}/approve`,
      {
        method: 'PUT',
      }
    ),

  rejectParkingReservation: (
    residenceId: string,
    reservationId: string,
    rejectionReason?: string
  ) =>
    request<{ success: boolean; message: string; reservation: ParkingReservation }>(
      `/parking/${residenceId}/reservations/${reservationId}/reject`,
      {
        method: 'PUT',
        body: JSON.stringify({ rejectionReason }),
      }
    ),

  getResidentReservations: (residenceId: string) =>
    request<ParkingReservation[]>(`/parking/${residenceId}/reservations`),
};
