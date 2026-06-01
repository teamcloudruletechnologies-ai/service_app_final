const { validationResult } = require("express-validator");
const { error } = require("../utils/response");

function validate(req, res, next) {
  const result = validationResult(req);

  if (result.isEmpty()) {
    return next();
  }

  return error(res, "Validation failed", 400, result.array());
}

module.exports = validate;
