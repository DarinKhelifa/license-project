import React, { createContext, useContext, useEffect, useState } from 'react';
import { authAPI, adminAPI } from '../services/api';

export interface UserData {
  id: string;
  _id?: string;
  uid: string;  // Add this for compatibility
  name: string;
  email: string;
  profileImage?: string;
  specialization?: 'cleaning' | 'electrician' | 'repair' | 'plumber' | 'other' | null;
  phone: string;
  apartment: string;
  role: 'resident' | 'security' | 'admin' | 'maintenance';
  status: 'active' | 'pending' | 'inactive';
  joinDate: string;
  createdBy?: string;
}

interface AuthContextType {
  user: UserData | null;
  userData: UserData | null;  // Add this
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, userData: any) => Promise<void>;  // Update signature
  signInWithGoogle: () => Promise<void>;  // Add this
  logout: () => Promise<void>;
  refreshUser: () => Promise<void>;
  // Admin functions
  getAllUsers: () => Promise<UserData[]>;
  updateUserRole: (uid: string, role: UserData['role']) => Promise<void>;
  updateUserStatus: (uid: string, status: UserData['status']) => Promise<void>;
  deleteUser: (uid: string) => Promise<void>;  // Add this
  createUser: (userData: any) => Promise<any>;  // Add this
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserData | null>(null);
  const [loading, setLoading] = useState(true);

  // Check if user is already logged in
  useEffect(() => {
    const checkAuth = async () => {
      const token = localStorage.getItem('auth_token');
      if (token) {
        try {
          const userData = await authAPI.getMe();
          setUser(normalizeUser(userData));
        } catch (error) {
          localStorage.removeItem('auth_token');
        }
      }
      setLoading(false);
    };
    checkAuth();
  }, []);

  const refreshUser = async () => {
    try {
      const userData = await authAPI.getMe();
      const normalized = normalizeUser(userData);
      setUser(normalized);
    } catch (err) {
      console.error('refreshUser error', err);
    }
  };

  const signIn = async (email: string, password: string) => {
    const userData = await authAPI.login(email, password);
    const normalized = normalizeUser(userData);
    setUser(normalized);
  };

  const signUp = async (email: string, password: string, userDataInput: any) => {
    const newUser = await authAPI.register({
      email,
      password,
      name: userDataInput.name,
      phone: userDataInput.phone,
      apartment: userDataInput.apartment,
      role: userDataInput.role || 'resident',
    });
    const normalized = normalizeUser(newUser);
    setUser(normalized);
  };

  const signInWithGoogle = async () => {
    // TODO: Implement Google Sign In with backend
    throw new Error('Google Sign In coming soon');
  };

  const logout = async () => {
    authAPI.logout();
    setUser(null);
  };

  // Admin functions
  const getAllUsers = async () => {
    return await adminAPI.getAllUsers();
  };

  const updateUserRole = async (uid: string, role: UserData['role']) => {
    await adminAPI.updateUserRole(uid, role);
    // Refresh user list if needed
  };

  const updateUserStatus = async (uid: string, status: UserData['status']) => {
    await adminAPI.updateUserStatus(uid, status);
  };

  const deleteUser = async (uid: string) => {
    await adminAPI.deleteUser(uid);
  };

  // Normalize user object (make profileImage absolute URL)
  const normalizeUser = (u: any) => {
    if (!u) return u;
    const copy = { ...u } as any;
    try {
      if (copy.profileImage && typeof copy.profileImage === 'string' && copy.profileImage.startsWith('/uploads')) {
        const apiBase = ((process.env.REACT_APP_API_URL as string) || 'http://localhost:5000').replace(/\/api$/, '');
        copy.profileImage = `${apiBase}${copy.profileImage}`;
      }
      // ensure specialization is preserved
      if (u.specialization) copy.specialization = u.specialization;
    } catch (e) {
      // noop
    }
    return copy as UserData;
  };

  const createUser = async (userDataInput: any) => {
    // Use admin API to create users without email verification so they can login
    const res = await adminAPI.createUser({
      email: userDataInput.email,
      password: userDataInput.password || undefined,
      name: userDataInput.name,
      phone: userDataInput.phone,
      apartment: userDataInput.apartment,
      role: userDataInput.role,
      specialization: userDataInput.specialization || null,
      status: userDataInput.status || 'active',
    });
    return res;
  };

  return (
    <AuthContext.Provider value={{
      user,
      userData: user,  // Alias user as userData for compatibility
      loading,
      signIn,
      signUp,
      signInWithGoogle,
      logout,
      refreshUser,
      getAllUsers,
      updateUserRole,
      updateUserStatus,
      deleteUser,
      createUser,
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};