const app = require("./app");
const env = require("./config/env");
const { initDb, pool } = require("./config/db");
const logger = require("./utils/logger");

async function start() {
  try {
    await initDb();
    app.listen(env.port, () => {
      logger.info(`Server running on port ${env.port}`);
    });
  } catch (err) {
    logger.error("Failed to start server", { message: err.message, stack: err.stack });
    await pool.end();
    process.exit(1);
  }
}

start();
