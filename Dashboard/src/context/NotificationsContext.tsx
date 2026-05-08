import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { io } from 'socket.io-client';
import { useAuth } from './AuthContext';

type NotificationItem = {
  _id?: string;
  title?: string;
  message: string;
  type?: string;
  createdAt?: string;
  read?: boolean;
};

type NotificationsContextValue = {
  notifications: NotificationItem[];
  unreadCount: number;
  pushNotification: (n: NotificationItem) => void;
  markAllRead: () => void;
};

const NotificationsContext = createContext<NotificationsContextValue | null>(null);

export const NotificationsProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user } = useAuth();
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  // Fetch existing notifications from backend on mount/user change
  const fetchExistingNotifications = async (userId: string) => {
    try {
      setIsLoading(true);
      const response = await fetch(`/api/notifications/${userId}`);
      if (response.ok) {
        const data = await response.json();
        if (data.notifications && Array.isArray(data.notifications)) {
          const normalized = data.notifications.map((n: any) => ({
            _id: n._id,
            title: n.title,
            message: n.message ?? n.body ?? '',
            type: n.type,
            createdAt: n.createdAt,
            read: n.isRead
          }));
          setNotifications(normalized);
          console.log(`✅ Loaded ${normalized.length} existing notifications`);
        }
      }
    } catch (error) {
      console.error('Failed to fetch notifications:', error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    // Connect to backend socket
    const SOCKET_URL = ((globalThis as typeof globalThis & {
      process?: { env?: Record<string, string | undefined> };
    }).process?.env?.REACT_APP_API_URL) || 'http://localhost:5000';
    const s = io(SOCKET_URL, { transports: ['websocket', 'polling'] });

    s.on('connect', () => {
      // join notification room if user available
      if (user && user.id) {
        s.emit('join-notification-room', user.id);
        s.emit('user-connected', { userId: user.id, role: user.role });
        // Fetch existing notifications from database
        fetchExistingNotifications(user.id);
      }
    });

    s.on('notification-received', (notification: NotificationItem) => {
      // Normalize backend 'body' -> frontend 'message'
      const normalized = { ...notification, message: notification.message ?? (notification as any).body ?? '' };
      setNotifications((prev) => [{ ...normalized, read: false }, ...prev]);
    });

    // Listen for role-based alerts emitted by the server
    s.on('new-alert', (payload: any) => {
      setNotifications((prev) => [
        {
          _id: payload.id,
          title: payload.title,
          message: payload.message ?? payload.body ?? '',
          type: 'alert',
          createdAt: payload.createdAt
        },
        ...prev
      ]);
    });

    s.on('alert-status-updated', (payload: any) => {
      setNotifications((prev) => [
        {
          _id: payload.reportId + '-' + String(payload.updatedAt),
          title: `Report ${payload.status}`,
          message: `${payload.updatedBy} updated report ${payload.reportId}`,
          type: 'alert',
          createdAt: payload.updatedAt
        },
        ...prev
      ]);
    });

    s.on('energy-alert', (payload: any) => {
      setNotifications((prev) => [
        {
          _id: `energy-${payload.deviceName}-${payload.timestamp}`,
          title: `Energy alert: ${payload.deviceName}`,
          message: `${payload.deviceName} at ${payload.location} reported ${payload.value}`,
          type: 'energy_alert',
          createdAt: payload.timestamp
        },
        ...prev
      ]);
    });

    s.on('new-message', (payload: any) => {
      setNotifications((prev) => [
        {
          _id: payload._id || `msg-${Date.now()}`,
          title: 'New Message',
          message: payload.text || payload.lastMessage || payload.body || 'You have a new message',
          type: 'message_received',
          createdAt: new Date().toISOString()
        },
        ...prev
      ]);
    });

    return () => {
      s.disconnect();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user?.id]);

  const pushNotification = (n: NotificationItem) => {
    setNotifications((prev) => [{ ...n, read: false }, ...prev]);
  };

  const markAllRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
  };

  const unreadCount = useMemo(() => notifications.filter((n) => !n.read).length, [notifications]);

  return (
    <NotificationsContext.Provider value={{ notifications, unreadCount, pushNotification, markAllRead }}>
      {children}
    </NotificationsContext.Provider>
  );
};

export const useNotifications = () => {
  const ctx = useContext(NotificationsContext);
  if (!ctx) throw new Error('useNotifications must be used within NotificationsProvider');
  return ctx;
};

export default NotificationsContext;
