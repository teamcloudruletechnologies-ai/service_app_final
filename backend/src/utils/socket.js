const { Server } = require("socket.io");
const logger = require("./logger");

let io;

function init(server, corsOrigin) {
  io = new Server(server, {
    cors: {
      origin: corsOrigin || "*",
      methods: ["GET", "POST"],
    },
  });

  io.on("connection", (socket) => {
    logger.info(`Socket connected: ${socket.id}`);

    // Join room based on user role or booking ID
    socket.on("join_booking", (bookingId) => {
      logger.info(`Socket ${socket.id} joining room booking_${bookingId}`);
      socket.join(`booking_${bookingId}`);
    });

    socket.on("leave_booking", (bookingId) => {
      logger.info(`Socket ${socket.id} leaving room booking_${bookingId}`);
      socket.leave(`booking_${bookingId}`);
    });

    // Join room for specific worker (live location tracking)
    socket.on("track_worker", (workerId) => {
      logger.info(`Socket ${socket.id} tracking worker_${workerId}`);
      socket.join(`worker_${workerId}`);
    });

    socket.on("untrack_worker", (workerId) => {
      logger.info(`Socket ${socket.id} untracking worker_${workerId}`);
      socket.leave(`worker_${workerId}`);
    });

    // Workers reporting location
    socket.on("report_location", async (data) => {
      // data format: { workerId, lat, lng }
      const { workerId, lat, lng } = data;
      if (workerId && lat && lng) {
        logger.debug(`Location reported by worker ${workerId}: lat=${lat}, lng=${lng}`);
        // Broadcast location update to anyone tracking this worker
        io.to(`worker_${workerId}`).emit("worker_location_update", { workerId, lat, lng });

        // Optionally save to database
        const db = require("../config/db");
        try {
          await db.query(
            `UPDATE workers
             SET current_lat = $2, current_lng = $3, last_location_update = NOW()
             WHERE id = $1`,
            [workerId, lat, lng]
          );
        } catch (err) {
          logger.error(`Failed to save worker location: ${err.message}`);
        }
      }
    });

    socket.on("disconnect", () => {
      logger.info(`Socket disconnected: ${socket.id}`);
    });
  });

  return io;
}

function getIo() {
  return io;
}

function emitBookingUpdate(bookingId, data) {
  if (io) {
    logger.info(`Emitting booking update to room booking_${bookingId}`);
    io.to(`booking_${bookingId}`).emit("booking_update", data);
  }
}

module.exports = {
  init,
  getIo,
  emitBookingUpdate,
};
