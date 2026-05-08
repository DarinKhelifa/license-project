import { request } from './api';

export interface ReportDTO {
  _id?: string;
  id: string;
  category: string;
  subCategory: string;
  location: string;
  description: string;
  status: 'pending' | 'in-progress' | 'resolved' | 'rejected';
  createdBy: string;
  createdByName: string;
  createdAt: string;
}

export interface EventDTO {
  _id?: string;
  id: string;
  title: string;
  description: string;
  date: string;
  time: string;
  location: string;
  category: string;
  capacity: number;
  currentRegistrations: number;
  status: 'pending' | 'approved' | 'rejected' | 'cancelled';
  createdBy: string;
  createdByName: string;
  createdAt: string;
}

export interface EmployeeDTO {
  _id: string;
  firstName: string;
  lastName: string;
  workCategory: string;
  status?: string;
  createdAt?: string;
}

export interface EmployeeListResponse {
  success: boolean;
  count?: number;
  employees: EmployeeDTO[];
}

export interface EnergyHistoricalResponse {
  chartData: Array<{ hour: number; average: number }>;
  summary: { total: number; average: number; peak: number };
}

export const dashboardAPI = {
  employees: {
    list: () => request<EmployeeListResponse>('/employees'),
  },
  reports: {
    my: () => request<ReportDTO[]>('/reports/my-reports'),
    allForStaff: () => request<ReportDTO[]>('/reports/admin/all'),
  },
  events: {
    approvedUpcoming: () => request<EventDTO[]>('/events'),
    my: () => request<EventDTO[]>('/events/my-events'),
    pendingAdmin: () => request<EventDTO[]>('/events/admin/pending'),
    allAdmin: () => request<EventDTO[]>('/events/admin/all'),
  },
  energy: {
    historical: (params?: { deviceId?: string; days?: number }) => {
      const qs = new URLSearchParams();
      if (params?.deviceId) qs.set('deviceId', params.deviceId);
      if (params?.days) qs.set('days', String(params.days));
      const suffix = qs.toString() ? `?${qs.toString()}` : '';
      return request<EnergyHistoricalResponse>(`/energy/historical${suffix}`);
    },
    current: () => request<any[]>('/energy/current'),
  },
};
