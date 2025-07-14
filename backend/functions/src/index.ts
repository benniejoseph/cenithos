import { initializeApp } from "firebase-admin/app";

// Initialize without explicit credentials.
// When running in the emulator, it will connect automatically.
// When deployed, it will use the project's default service account.
initializeApp();

import * as functions from "firebase-functions";
import express from "express";
import cors from "cors";
import mainRouter from "./routes";
import { isAuthenticated } from "./middleware/auth";

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// The /api path is handled by the function trigger.
// The router should handle all paths from the root.
app.use("/", isAuthenticated, mainRouter);

export const api = functions.https.onRequest(app); 