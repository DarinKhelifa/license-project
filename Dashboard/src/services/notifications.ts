import { request } from './api';

export interface NotificationItem {
  _id?: string;
  title?: string;
  message?: string;
  type?: string;
  isRead?: boolean;
  createdAt?: string;
  metadata?: any;
}

export const notificationsAPI = {
  list: (userId: string) => request<{ success: boolean; notifications: NotificationItem[] }>(`/notifications/${userId}`),
  markRead: (id: string) => request<any>(`/notifications/${id}/read`, { method: 'PATCH' }),
  markAllRead: (userId: string) => request<any>(`/notifications/read-all/${userId}`, { method: 'PATCH' }),
  delete: (id: string) => request<any>(`/notifications/${id}`, { method: 'DELETE' }),
};
