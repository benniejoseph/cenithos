import { Router } from "express";
import { getCategories, createCategory, deleteCategory } from "../services/categories";

const router = Router();

router.get("/", getCategories);
router.post("/", createCategory);
router.delete("/:name", deleteCategory);

export default router; 