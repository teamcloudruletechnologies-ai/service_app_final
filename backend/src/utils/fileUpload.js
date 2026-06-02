const fs = require("fs");
const path = require("path");
const { v4: uuidv4 } = require("uuid");

async function saveUpload(file, folder = "services") {
  if (!file) return null;
  const uploadsDir = path.join(__dirname, `../../public/uploads/${folder}`);
  
  // Ensure the directory exists
  await fs.promises.mkdir(uploadsDir, { recursive: true });

  // Generate unique filename with original extension
  const ext = path.extname(file.originalname);
  const filename = `${uuidv4()}${ext}`;
  const filePath = path.join(uploadsDir, filename);

  // Write the file buffer to disk
  await fs.promises.writeFile(filePath, file.buffer);

  // Return the relative web URL prefix
  return `/uploads/${folder}/${filename}`;
}

module.exports = { saveUpload };
