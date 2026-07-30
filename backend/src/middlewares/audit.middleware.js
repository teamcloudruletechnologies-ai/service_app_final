const logger = require("../utils/logger");

function audit(action) {
  return (req, res, next) => {
    logger.info("audit", {
      action,
      actor: req.auth || null,
      method: req.method,
      path: req.originalUrl,
    });
    next();
  };
}

module.exports = audit;
