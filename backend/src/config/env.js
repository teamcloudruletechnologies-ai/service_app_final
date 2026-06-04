const dotenv = require("dotenv");

dotenv.config();

const env = {
  nodeEnv: process.env.NODE_ENV || "development",
  port: Number(process.env.PORT || 5000),
  corsOrigin: process.env.CORS_ORIGIN || "*",
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret: process.env.JWT_SECRET || "change-this-secret",
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || "7d",
  jwtAccessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || "15m",
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || "change-this-refresh-secret",
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || "7d",
  bcryptSaltRounds: Number(process.env.BCRYPT_SALT_ROUNDS || 12),
  googleMapsApiKey: process.env.GOOGLE_MAPS_API_KEY,
  supabaseUrl: process.env.SUPABASE_URL,
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY,
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
};

// Validate critical env vars
if (!env.databaseUrl) {
  throw new Error("DATABASE_URL is not set in .env");
}

module.exports = env;