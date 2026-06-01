const { error } = require("../utils/response");
const logger = require("../utils/logger");

function notFound(req, res) {
  return error(res, `Route not found: ${req.method} ${req.originalUrl}`, 404);
}

function errorHandler(err, req, res, next) {
  logger.error(err.message, { stack: err.stack });
  const statusCode = err.statusCode || 500;
  return error(res, err.message || "Internal server error", statusCode);
}

module.exports = { notFound, errorHandler };
