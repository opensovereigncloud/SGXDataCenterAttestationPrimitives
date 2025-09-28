import * as appUtil from '../utils/apputil.js';

export const getLiveness = (req, res) => {
  res.status(200).json({ status: 'UP', timestamp: new Date().toISOString() });
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
