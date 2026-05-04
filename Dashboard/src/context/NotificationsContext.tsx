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

  useEffect(() => {
    // Connect to backend socket
    const SOCKET_URL = (process.env.REACT_APP_API_URL as string) || 'http://localhost:5000';
    const s = io(SOCKET_URL, { transports: ['websocket', 'polling'] });

    s.on('connect', () => {
      // join notification room if user available
      if (user && user.id) {
        s.emit('join-notification-room', user.id);
        s.emit('user-connected', { userId: user.id, role: user.role });
      }
    });

    s.on('notification-received', (notification: NotificationItem) => {
      setNotifications((prev) => [{ ...notification, read: false }, ...prev]);
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
