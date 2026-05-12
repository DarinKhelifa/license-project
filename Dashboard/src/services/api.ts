// src/services/api.ts
export const API_URL = 'http://localhost:5001/api';

// Store token in localStorage
const getToken = () => localStorage.getItem('auth_token');
const setToken = (token: string) => localStorage.setItem('auth_token', token);
const removeToken = () => localStorage.removeItem('auth_token');

// API helper function
export async function request<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getToken();
  
  const response = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token && { 'Authorization': `Bearer ${token}` }),
      ...options.headers,
    },
  });

  let data: any = null;
  try {
    data = await response.json();
  } catch (err) {
    // Response had no JSON body
    data = null;
  }

  if (!response.ok) {
    // Log detailed info to help debug empty pages / missing data
    // eslint-disable-next-line no-console
    console.error(`API request failed: ${response.status} ${response.statusText} -> ${API_URL}${endpoint}`, data);
    throw new Error((data && data.message) ? data.message : `Request failed with status ${response.status}`);
  }

  return data as T;
}

// Auth API
export const authAPI = {
  login: (email: string, password: string) =>
    request<{ token: string; user: any }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }).then(res => {
      setToken(res.token);
      return res.user;
    }),

  register: (userData: any) =>
    request<{ token: string; user: any }>('/auth/register', {
      method: 'POST',
      body: JSON.stringify(userData),
    }).then(res => {
      setToken(res.token);
      return res.user;
    }),

  getMe: () =>
    request<any>('/auth/me'),

  updateProfile: (data: { name?: string; phone?: string; apartment?: string; residence?: string; building?: string }) =>
    request<any>('/auth/profile', {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  changePassword: (currentPassword: string, newPassword: string) =>
    request('/auth/change-password', {
      method: 'PUT',
      body: JSON.stringify({ currentPassword, newPassword }),
    }),

  logout: () => {
    removeToken();
  },
};

// Admin API
export const adminAPI = {
  getAllUsers: () =>
    request<any[]>('/auth/users'),

  updateUserRole: (userId: string, role: string) =>
    request(`/auth/users/${userId}/role`, {
      method: 'PUT',
      body: JSON.stringify({ role }),
    }),

  updateUserStatus: (userId: string, status: string) =>
    request(`/auth/users/${userId}/status`, {
      method: 'PUT',
      body: JSON.stringify({ status }),
    }),
  updateUser: (userId: string, userData: any) =>
    request(`/auth/users/${userId}`, {
      method: 'PUT',
      body: JSON.stringify(userData),
    }),
  deleteUser: (userId: string) =>
    request(`/auth/users/${userId}`, {
      method: 'DELETE',
    }),
  createUser: (userData: any) =>
    request<{ tempPassword?: string; user?: any }>('/auth/users', {
      method: 'POST',
      body: JSON.stringify(userData),
    }),
};