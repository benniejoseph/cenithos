import { Request, Response, NextFunction } from "express";
import { auth } from "firebase-admin";

// Extend the Express Request type to include our custom 'user' property
export interface AuthenticatedRequest extends Request {
  user?: auth.DecodedIdToken;
}

export const isAuthenticated = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  const { authorization } = req.headers;

  if (!authorization || !authorization.startsWith("Bearer ")) {
    res.status(401).send({ error: "Unauthorized: Missing or invalid token." });
    return;
  }

  const split = authorization.split("Bearer ");
  if (split.length !== 2) {
    res.status(401).send({ error: "Unauthorized: Malformed token." });
    return;
  }

  const token = split[1];

  try {
    const decodedToken: auth.DecodedIdToken = await auth().verifyIdToken(token);
    console.log("[AuthMiddleware] INFO: Token verified successfully for UID:", decodedToken.uid);
    req.user = decodedToken;
    next();
  } catch (err) {
    console.error("[AuthMiddleware] CRITICAL: Error while verifying token:", err);
    res.status(401).send({ error: "Unauthorized: Token verification failed." });
  }
}; 