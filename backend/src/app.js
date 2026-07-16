const express = require("express");
const cors = require("cors");
const path = require("path");
const env = require("./config/env");
const routes = require("./routes");
const { notFound, errorHandler } = require("./middlewares/error.middleware");

const app = express();

app.use(cors({ origin: env.corsOrigin }));
app.use(express.json({ limit: "2mb" }));
app.use(express.urlencoded({ extended: true }));

app.use("/uploads", express.static(path.join(__dirname, "../public/uploads")));

// ── Health check & root ──────────────────────────────────────────────────────
app.get("/", (req, res) => {
  res.json({
    success: true,
    name: "Urban Service App — API",
    version: "1.0.0",
    status: "running",
    timestamp: new Date().toISOString(),
    docs: "/api",
  });
});

app.get("/health", (req, res) => {
  res.json({ success: true, status: "healthy", uptime: process.uptime() });
});

app.use("/api", routes);
app.use(notFound);
app.use(errorHandler);

module.exports = app;
