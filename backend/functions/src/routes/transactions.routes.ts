import { Router, Response } from "express";
import {
  AuthenticatedRequest,
} from "../middleware/auth";
import * as transactionService from "../services/transactions";
import * as logger from "firebase-functions/logger";

const router = Router();

router.get("/", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      return res.status(403).send({error: "User ID is missing."});
    }
    // Extract query params for filtering
    const { category, type, startDate, endDate } = req.query;
    const filters = {
      category: category as string | undefined,
      type: type as string | undefined,
      startDate: startDate as string | undefined,
      endDate: endDate as string | undefined,
    };

    const transactions = await transactionService.getTransactions(userId, filters);
    return res.status(200).send(transactions);
  } catch (error) {
    logger.error("Error fetching transactions:", error);
    return res.status(500).send({error: "Failed to fetch transactions."});
  }
});

router.post("/", async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.uid;
  if (!userId) {
    return res.status(403).send({ error: "User ID is missing." });
  }
  try {
      const { amount, description, date, type, category } = req.body;
      if (!amount || !description || !date || !type || !category) {
          return res.status(400).send({ error: "Missing required transaction fields" });
      }
      const newTransaction = await transactionService.createTransaction(
          userId,
          amount,
          description,
          date,
          type,
          category
      );
      return res.status(201).json(newTransaction);
  } catch (error) {
      logger.error("Error creating transaction:", error);
      return res.status(500).send({ error: "Failed to create transaction." });
  }
});

router.post("/import", async (req: AuthenticatedRequest, res: Response) => {
     try {
       const userId = req.user?.uid;
       if (!userId) {
         logger.error("User ID is missing in authenticated request.");
         return res.status(403).send({error: "User ID is missing."});
       }

       if (!req.body || !req.body.transactions) {
        logger.error("Request body or transactions array is missing.", { body: req.body });
        return res.status(400).send({ error: "Missing transactions payload." });
       }

       const {transactions} = req.body;
       if (!Array.isArray(transactions)) {
         logger.error("Payload is not an array.", { payload: transactions });
         return res.status(400).send({error: "Invalid transactions payload."});
       }

       logger.info(`Received a request to import ${transactions.length} transactions for user ${userId}.`);

       const report = await transactionService.createImportedTransactions(
         userId,
         transactions,
       );
       return res.status(201).send(report);
     } catch (error) {
       logger.error("Error importing transactions:", error);
       return res.status(500).send({error: "Failed to import transactions."});
     }
   },
);

router.post("/feedback", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      return res.status(403).send({error: "User ID is missing."});
    }

    const {description, oldCategory, newCategory, transactionId} = req.body;
    if (!description || !oldCategory || !newCategory || !transactionId) {
      return res.status(400).send({error: "Missing feedback data."});
    }

    await transactionService.handleCategoryFeedback(
      userId,
      transactionId,
      description,
      oldCategory,
      newCategory,
    );

    return res.status(200).send({message: "Feedback received."});
  } catch (error) {
    logger.error("Error processing feedback:", error);
    return res.status(500).send({error: "Failed to process feedback."});
  }
});

router.put("/:id", async (req: AuthenticatedRequest, res: Response) => {
    try {
        const userId = req.user?.uid;
        if (!userId) {
            return res.status(403).send({ error: "Unauthorized" });
        }
        const { id } = req.params;
        const updates = req.body;
        
        const updatedTransaction = await transactionService.updateTransaction(id, updates);
        return res.json(updatedTransaction);
    } catch (error) {
        logger.error(`Error updating transaction ${req.params.id}:`, error);
        return res.status(500).send("Internal Server Error");
    }
});

router.delete("/:id", async (req: AuthenticatedRequest, res: Response) => {
    try {
        const userId = req.user?.uid;
        if (!userId) {
            return res.status(403).send({ error: "Unauthorized" });
        }
        const { id } = req.params;
        
        await transactionService.deleteTransaction(id);
        return res.status(204).send();
    } catch (error) {
        logger.error(`Error deleting transaction ${req.params.id}:`, error);
        return res.status(500).send("Internal Server Error");
    }
});


export default router;