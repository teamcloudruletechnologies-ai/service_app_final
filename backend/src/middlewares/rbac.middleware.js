const { error } = require("../utils/response");

function allowRoles(...roles) {
  return (req, res, next) => {
    if (!req.auth || !roles.includes(req.auth.role)) {
      return error(res, "You do not have permission to access this resource", 403);
    }

    return next();
  };
}

module.exports = allowRoles;
