const http = require("http");
const app = require("./app");
const env = require("./config/env");
const { initDb, pool } = require("./config/db");
const logger = require("./utils/logger");
const socketUtil = require("./utils/socket");

async function start() {
  try {
    await initDb();
    const server = http.createServer(app);
    
    // Initialize Socket.IO
    socketUtil.init(server, env.corsOrigin);
    
    server.listen(env.port, () => {
      logger.info(`Server running on port ${env.port}`);
    });
  } catch (err) {
    logger.error("Failed to start server", { message: err.message, stack: err.stack });
    await pool.end();
    process.exit(1);
  }
}

start();
