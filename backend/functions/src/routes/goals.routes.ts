import {Router, Response} from "express";
import * as goalService from "../services/goals";
import * as logger from "firebase-functions/logger";
import {
  AuthenticatedRequest,
} from "../middleware/auth";

const router = Router();

router.post("/", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      return res.status(403).send({error: "User ID is missing."});
    }
    const newGoal = await goalService.createGoal(userId, req.body);
    return res.status(201).send(newGoal);
  } catch (error) {
    logger.error("Error creating goal:", error);
    return res.status(500).send({error: "Failed to create goal."});
  }
});

router.get("/", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      return res.status(403).send({error: "User ID is missing."});
    }
    const goals = await goalService.getGoals(userId);
    return res.send(goals);
  } catch (error) {
    logger.error("Error fetching goals:", error);
    return res.status(500).send({error: "Failed to fetch goals."});
  }
});

router.get("/:id", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      return res.status(403).send({error: "User ID is missing."});
    }
    const goal = await goalService.getGoalById(req.params.id, userId);
    if (goal) {
      return res.send(goal);
    } else {
      return res.status(404).send({error: "Goal not found."});
    }
  } catch (error) {
    logger.error("Error fetching goal:", error);
    return res.status(500).send({error: "Failed to fetch goal."});
  }
});

router.put("/:id", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      return res.status(403).send({error: "User ID is missing."});
    }
    const updatedGoal = await goalService.updateGoal(
      req.params.id,
      userId,
      req.body,
    );
    if (updatedGoal) {
      return res.send(updatedGoal);
    } else {
      return res.status(404).send({error: "Goal not found."});
    }
  } catch (error) {
    logger.error("Error updating goal:", error);
    return res.status(500).send({error: "Failed to update goal."});
  }
});

router.delete("/:id", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      return res.status(403).send({error: "User ID is missing."});
    }
    const wasDeleted = await goalService.deleteGoal(req.params.id, userId);
    if (wasDeleted) {
      return res.status(204).send();
    } else {
      return res.status(404).send({error: "Goal not found or user not authorized."});
    }
  } catch (error) {
    logger.error("Error deleting goal:", error);
    return res.status(500).send({error: "Failed to delete goal."});
  }
});

export default router; 