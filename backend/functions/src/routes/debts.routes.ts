import { Router, Response } from 'express';
import { createDebt, getDebts, getDebtById, updateDebt, deleteDebt } from '../services/debts';
import { AuthenticatedRequest } from '../middleware/auth';

const router = Router();

// Create Debt
router.post('/', async (req: AuthenticatedRequest, res: Response) => {
    try {
        const userId = req.user?.uid;
        if (!userId) {
            return res.status(403).send({ error: "Unauthorized" });
        }
        const newDebt = await createDebt(userId, req.body);
        return res.status(201).json(newDebt);
    } catch (error) {
        return res.status(500).json({ error: 'Failed to create debt' });
    }
});

// Get all Debts for a user
router.get('/', async (req: AuthenticatedRequest, res: Response) => {
    try {
        const userId = req.user?.uid;
        if (!userId) {
            return res.status(403).send({ error: "Unauthorized" });
        }
        const debts = await getDebts(userId);
        return res.status(200).json(debts);
    } catch (error) {
        return res.status(500).json({ error: 'Failed to fetch debts' });
    }
});

// Get a single Debt by ID
router.get('/:id', async (req: AuthenticatedRequest, res: Response) => {
    try {
        const userId = req.user?.uid;
        if (!userId) {
            return res.status(403).send({ error: "Unauthorized" });
        }
        const debtId = req.params.id;
        const debt = await getDebtById(debtId, userId);
        if (debt) {
            return res.status(200).json(debt);
        } else {
            return res.status(404).json({ message: 'Debt not found or unauthorized' });
        }
    } catch (error) {
        return res.status(500).json({ error: 'Failed to fetch debt' });
    }
});

// Update a Debt
router.put('/:id', async (req: AuthenticatedRequest, res: Response) => {
    try {
        const userId = req.user?.uid;
        if (!userId) {
            return res.status(403).send({ error: "Unauthorized" });
        }
        const debtId = req.params.id;
        const updatedDebt = await updateDebt(debtId, userId, req.body);
        if (updatedDebt) {
            return res.status(200).json(updatedDebt);
        } else {
            return res.status(404).json({ message: 'Debt not found or unauthorized' });
        }
    } catch (error) {
        return res.status(500).json({ error: 'Failed to update debt' });
    }
});

// Delete a Debt
router.delete('/:id', async (req: AuthenticatedRequest, res: Response) => {
    try {
        const userId = req.user?.uid;
        if (!userId) {
            return res.status(403).send({ error: "Unauthorized" });
        }
        const debtId = req.params.id;
        const success = await deleteDebt(debtId, userId);
        if (success) {
            return res.status(204).send();
        } else {
            return res.status(404).json({ message: 'Debt not found or unauthorized' });
        }
    } catch (error) {
        return res.status(500).json({ error: 'Failed to delete debt' });
    }
});

export default router; 