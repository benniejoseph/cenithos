import { getFirestore } from "firebase-admin/firestore";

export const settingsCollection = () => getFirestore().collection("user_settings");
export const transactionsCollection = () => getFirestore().collection("transactions"); 