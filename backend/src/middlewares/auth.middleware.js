const { verifyToken } = require("../utils/token");
const { error } = require("../utils/response");

function auth(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;

  if (!token) {
    return error(res, "Authorization token missing", 401);
  }

  try {
    req.auth = verifyToken(token);
    return next();
  } catch (err) {
    return error(res, "Invalid or expired token", 401);
  }
}

module.exports = auth;
