import { Router, Response } from 'express';
import { createInvestment, getInvestments, getInvestmentById, updateInvestment, deleteInvestment } from '../services/investments';
import { AuthenticatedRequest } from '../middleware/auth';

const router = Router();

// Create Investment
router.post('/', async (req: AuthenticatedRequest, res: Response) => {
    try {
        const userId = req.user?.uid;
        if (!userId) {
            return res.status(403).send({ error: "Unauthorized" });
        }
        const newInvestment = await createInvestment(userId, req.body);
        return res.status(201).json(newInvestment);
    } catch (error) {
        return res.status(500).json({ error: 'Failed to create investment' });
    }
});

// Get all Investments for a user
router.get('/', async (req: AuthenticatedRequest, res: Response) => {
    try {
        const userId = req.user?.uid;
        if (!userId) {
            return res.status(403).send({ error: "Unauthorized" });
        }
        const investments = await getInvestments(userId);
        return res.status(200).json(investments);
    } catch (error) {
        return res.status(500).json({ error: 'Failed to fetch investments' });
    }
});

// Get a single Investment by ID
router.get('/:id', async (req: AuthenticatedRequest, res: Response) => {
    try {
        const userId = req.user?.uid;
        if (!userId) {
            return res.status(403).send({ error: "Unauthorized" });
        }
        const investmentId = req.params.id;
        const investment = await getInvestmentById(investmentId, userId);
        if (investment) {
            return res.status(200).json(investment);
        } else {
            return res.status(404).json({ message: 'Investment not found or unauthorized' });
        }
    } catch (error) {
        return res.status(500).json({ error: 'Failed to fetch investment' });
    }
});

// Update an Investment
router.put('/:id', async (req: AuthenticatedRequest, res: Response) => {
    try {
        const userId = req.user?.uid;
        if (!userId) {
            return res.status(403).send({ error: "Unauthorized" });
        }
        const investmentId = req.params.id;
        const updatedInvestment = await updateInvestment(investmentId, userId, req.body);
        if (updatedInvestment) {
            return res.status(200).json(updatedInvestment);
        } else {
            return res.status(404).json({ message: 'Investment not found or unauthorized' });
        }
    } catch (error) {
        return res.status(500).json({ error: 'Failed to update investment' });
    }
});

// Delete an Investment
router.delete('/:id', async (req: AuthenticatedRequest, res: Response) => {
    try {
        const userId = req.user?.uid;
        if (!userId) {
            return res.status(403).send({ error: "Unauthorized" });
        }
        const investmentId = req.params.id;
        const success = await deleteInvestment(investmentId, userId);
        if (success) {
            return res.status(204).send();
        } else {
            return res.status(404).json({ message: 'Investment not found or unauthorized' });
        }
    } catch (error) {
        return res.status(500).json({ error: 'Failed to delete investment' });
    }
});

export default router; 