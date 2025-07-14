import express from 'express';
import budgetsRouter from './budgets.routes';
import goalsRouter from './goals.routes';
import transactionsRouter from './transactions.routes';
import debtsRouter from './debts.routes';
import investmentsRouter from './investments.routes';
import categoriesRouter from './categories.routes';

const mainRouter = express.Router();

mainRouter.use('/transactions', transactionsRouter);
mainRouter.use('/budgets', budgetsRouter);
mainRouter.use('/goals', goalsRouter);
mainRouter.use('/debts', debtsRouter);
mainRouter.use('/investments', investmentsRouter);
mainRouter.use('/categories', categoriesRouter);

export default mainRouter; 