import {Router, Response} from "express";
import {
  createBudget,
  getBudgets,
  updateBudget,
  deleteBudget,
  getBudgetById,
} from "../services/budgets";
import * as logger from "firebase-functions/logger";
import {
  AuthenticatedRequest,
} from "../middleware/auth";

const router = Router();

// The isAuthenticated middleware is already applied in the main index.ts,
// so we don't need to apply it again here.

// POST /api/budgets - Create a new budget
router.post("/", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      return res.status(403).send({error: "User ID is missing."});
    }
    const budget = await createBudget(userId, req.body);
    return res.status(201).send(budget);
  } catch (error) {
    logger.error("Error creating budget:", error);
    return res.status(500).send({error: "Failed to create budget."});
  }
});

// GET /api/budgets - Get all budgets for the authenticated user
router.get("/", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      return res.status(403).send({error: "User ID is missing."});
    }
    const budgets = await getBudgets(userId);
    return res.status(200).send(budgets);
  } catch (error) {
    logger.error("Error fetching budgets:", error);
    return res.status(500).send({error: "Failed to fetch budgets."});
  }
});

// GET /api/budgets/:id - Get a single budget by its ID
router.get("/:id", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      return res.status(403).send({error: "User ID is missing."});
    }
    const budget = await getBudgetById(userId, req.params.id);
    if (!budget) {
      return res.status(404).send({error: "Budget not found."});
    }
    return res.status(200).send(budget);
  } catch (error) {
    logger.error("Error fetching budget:", error);
    return res.status(500).send({error: "Failed to fetch budget."});
  }
});

// PUT /api/budgets/:id - Update a budget
router.put("/:id", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      return res.status(403).send({error: "User ID is missing."});
    }
    const updatedBudget = await updateBudget(
      userId,
      req.params.id,
      req.body,
    );
    if (!updatedBudget) {
      return res.status(404).send({error: "Budget not found."});
    }
    return res.status(200).send(updatedBudget);
  } catch (error) {
    logger.error("Error updating budget:", error);
    return res.status(500).send({error: "Failed to update budget."});
  }
});

// DELETE /api/budgets/:id - Delete a budget
router.delete("/:id", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      return res.status(403).send({error: "User ID is missing."});
    }
    const wasDeleted = await deleteBudget(userId, req.params.id);
    if (wasDeleted) {
      return res.status(204).send();
    } else {
      return res.status(404).send({error: "Budget not found or user not authorized."});
    }
  } catch (error) {
    logger.error("Error deleting budget:", error);
    return res.status(500).send({error: "Failed to delete budget."});
  }
});

export default router; 