import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

// Your web app's Firebase configuration (from your Firebase Console)
const firebaseConfig = {
  apiKey: "AIzaSyAQj6Pd218nHZPirbL5yYta4smAxIy7Qjk",
  authDomain: "orelax-de683.firebaseapp.com",
  databaseURL: "https://orelax-de683-default-rtdb.firebaseio.com",
  projectId: "orelax-de683",
  storageBucket: "orelax-de683.firebasestorage.app",
  messagingSenderId: "1026176990834",
  appId: "1:1026176990834:web:fbe116b64f46531a8c4ceb"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const googleProvider = new GoogleAuthProvider();