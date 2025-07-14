import * as logger from "firebase-functions/logger";
import { Request, Response } from "express";
import { settingsCollection } from "./firebase-config";
import { AuthenticatedRequest } from "../middleware/auth";

const DEFAULT_CATEGORIES = [
  "Food", "Shopping", "Transportation", "Bills", "Entertainment", "Health", "Groceries", "Other"
];

export const getCategories = async (req: Request, res: Response): Promise<void> => {
  const userId = (req as AuthenticatedRequest).user?.uid;

  if (!userId) {
    logger.error("User ID not found on authenticated request.");
    res.status(401).send({ error: "Unauthorized" });
    return;
  }

  try {
    const doc = await settingsCollection().doc(userId).get();
    const data = doc.data();

    if (!doc.exists || !data?.transaction_categories) {
      logger.info(`No custom categories for user ${userId}, returning defaults.`);
      res.status(200).send(DEFAULT_CATEGORIES);
      return;
    }

    const categories = data.transaction_categories;

    if (Array.isArray(categories) && categories.every(c => typeof c === 'string')) {
      logger.info(`Returning ${categories.length} categories for user ${userId}`);
      res.status(200).send(categories);
    } else {
      logger.warn(`Corrupted categories for user ${userId}. Data is not a string array.`, { data });
      res.status(200).send(DEFAULT_CATEGORIES);
    }
  } catch (error) {
    logger.error(`Failed to get categories for user ${userId}:`, error);
    res.status(500).send({ error: "Failed to load categories." });
  }
};

export const createCategory = async (req: Request, res: Response): Promise<void> => {
    const userId = (req as AuthenticatedRequest).user?.uid;
    const { name } = req.body;

    if (!userId) {
        res.status(401).send({ error: "Unauthorized" });
        return;
    }
    if (!name || typeof name !== 'string') {
        res.status(400).send({ error: "Invalid category name." });
        return;
    }

    try {
        const docRef = settingsCollection().doc(userId);
        const doc = await docRef.get();
        const existingCategories = doc.data()?.transaction_categories ?? DEFAULT_CATEGORIES;

        if (existingCategories.includes(name)) {
            res.status(409).send({ error: "Category already exists." });
            return;
        }

        const newCategories = [...existingCategories, name];
        await docRef.set({ transaction_categories: newCategories }, { merge: true });

        logger.info(`Category '${name}' added for user ${userId}`);
        res.status(201).send(newCategories);
    } catch (error) {
        logger.error(`Failed to create category for user ${userId}:`, error);
        res.status(500).send({ error: "Failed to create category." });
    }
};

export const deleteCategory = async (req: Request, res: Response): Promise<void> => {
    const userId = (req as AuthenticatedRequest).user?.uid;
    const { name } = req.params;

    if (!userId) {
        res.status(401).send({ error: "Unauthorized" });
        return;
    }
    if (!name) {
        res.status(400).send({ error: "Category name not provided." });
        return;
    }

    try {
        const docRef = settingsCollection().doc(userId);
        const doc = await docRef.get();
        const existingCategories = doc.data()?.transaction_categories;

        if (!existingCategories || !existingCategories.includes(name)) {
            res.status(404).send({ error: "Category not found." });
            return;
        }

        const newCategories = existingCategories.filter((c: string) => c !== name);
        await docRef.set({ transaction_categories: newCategories }, { merge: true });

        logger.info(`Category '${name}' deleted for user ${userId}`);
        res.status(200).send(newCategories);
    } catch (error) {
        logger.error(`Failed to delete category for user ${userId}:`, error);
        res.status(500).send({ error: "Failed to delete category." });
    }
}; 