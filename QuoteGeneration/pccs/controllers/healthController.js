import * as appUtil from '../utils/apputil.js';
import logger from '../utils/Logger.js';
import { sequelize } from '../dao/models/index.js';

export const getLiveness = async (_, res) => {
  const start = Date.now();

  try {
    await sequelize.authenticate();

    const latency = Date.now() - start;
    res.status(200).json({
      status: 'UP',
      db: 'CONNECTED',
      latency: `${latency}ms`,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    logger.error(`Liveness check failed: ${err.message}`);

    res.status(503).json({
      status: 'DEGRADED',
      db: 'DISCONNECTED',
      error: err.message,
      timestamp: new Date().toISOString(),
    });
  }
};

export const getReadiness = async (req, res) => {
  const dbOk = await appUtil.database_check();
  if (!dbOk) return res.status(503).json({ status: 'DOWN', timestamp: new Date().toISOString() });
  
  res.status(200).json({ status: 'UP', timestamp: new Date().toISOString() });
};

export const getStartup = async (req, res) => {
  const dbOk = await appUtil.database_check();
  if (!dbOk) return res.status(503).json({ status: 'STARTING', timestamp: new Date().toISOString() });
  
  res.status(200).json({ status: 'STARTED', timestamp: new Date().toISOString() });
};
