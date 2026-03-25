import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import {
  User,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut,
  onAuthStateChanged,
} from 'firebase/auth';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

import { auth, db, googleProvider } from '../firebase/config';

export interface UserData {
  uid: string;
  name: string;
  email: string;
  phone: string;
  apartment: string;
  role: 'resident' | 'security' | 'admin' | 'maintenance';
  status: 'active' | 'pending' | 'inactive';
  joinDate: string;
  createdBy?: string;
}

interface AuthContextType {
  user: User | null;
  userData: UserData | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (
    email: string,
    password: string,
    userData: Omit<UserData, 'uid' | 'joinDate'>
  ) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  logout: () => Promise<void>;
  getAllUsers: () => Promise<UserData[]>;
  updateUserRole: (uid: string, role: UserData['role']) => Promise<void>;
  updateUserStatus: (uid: string, status: UserData['status']) => Promise<void>;
  deleteUser: (uid: string) => Promise<void>;
  createUser: (userData: Omit<UserData, 'uid' | 'joinDate'>) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [userData, setUserData] = useState<UserData | null>(null);
  const [loading, setLoading] = useState(true);

  const loadUserData = async (uid: string) => {
    try {
      console.log('📖 Loading user data for uid:', uid);
      const userDoc = await getDoc(doc(db, 'users', uid));
      console.log('📄 User doc exists:', userDoc.exists());
      if (userDoc.exists()) {
        const data = userDoc.data() as UserData;
        console.log('👤 User role:', data.role);
        setUserData(data);
      } else {
        console.log('⚠️ No user document found for uid:', uid);
        setUserData(null);
      }
    } catch (e) {
      console.error('❌ Error loading user data:', e);
      setUserData(null);
    }
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (authUser) => {
      setUser(authUser);
      if (authUser) {
        await loadUserData(authUser.uid);
      } else {
        setUserData(null);
      }
      setLoading(false);
    });
    return unsubscribe;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const value = useMemo<AuthContextType>(
    () => ({
      user,
      userData,
      loading,

      signIn: async (email, password) => {
        await signInWithEmailAndPassword(auth, email, password);
      },

      signUp: async (email, password, userDataInput) => {
        const cred = await createUserWithEmailAndPassword(auth, email, password);
        const uid = cred.user.uid;

        const profile: UserData = {
          uid,
          joinDate: new Date().toISOString(),
          ...userDataInput,
          email,
        };

        await setDoc(doc(db, 'users', uid), profile);
      },

      signInWithGoogle: async () => {
        const res = await signInWithPopup(auth, googleProvider);
        const uid = res.user.uid;

        const existing = await getDoc(doc(db, 'users', uid));
        if (existing.exists()) return;

        const profile: UserData = {
          uid,
          joinDate: new Date().toISOString(),
          name: res.user.displayName ?? '',
          email: res.user.email ?? '',
          phone: '',
          apartment: '',
          role: 'resident',
          status: 'active',
        };

        await setDoc(doc(db, 'users', uid), profile);
      },

      logout: async () => {
        await signOut(auth);
      },

      getAllUsers: async () => {
        const snap = await getDocs(collection(db, 'users'));
        return snap.docs.map((d) => d.data() as UserData);
      },

      updateUserRole: async (uid, role) => {
        await updateDoc(doc(db, 'users', uid), { role });
      },

      updateUserStatus: async (uid, status) => {
        await updateDoc(doc(db, 'users', uid), { status });
      },

      deleteUser: async (uid) => {
        await deleteDoc(doc(db, 'users', uid));
      },

      createUser: async (userDataInput) => {
        // Admin creates only the Firestore profile document.
        // We generate an auto-id so ManageAccounts can refresh the list.
        const newRef = doc(collection(db, 'users'));
        const profile: UserData = {
          uid: newRef.id,
          joinDate: new Date().toISOString(),
          ...userDataInput,
        };
        await setDoc(newRef, profile);
      },
    }),
    [loading, user, userData]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};
