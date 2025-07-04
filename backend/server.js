// server.js
const express = require('express');
const multer = require('multer');
const cors = require('cors');
const { uploadToPinata, deleteFromPinata } = require('./ipfs');
const fs = require('fs');
const path = require('path');

const app = express();
const upload = multer({ dest: 'uploads/' });
const FILES_DB_PATH = path.join(__dirname, 'files_db.json');

app.use(cors());
app.use(express.json());

function readFilesDb() {
  if (!fs.existsSync(FILES_DB_PATH)) return [];
  const data = fs.readFileSync(FILES_DB_PATH, 'utf-8');
  try {
    return JSON.parse(data);
  } catch {
    return [];
  }
}

function writeFilesDb(files) {
  fs.writeFileSync(FILES_DB_PATH, JSON.stringify(files, null, 2));
}

app.post('/upload', upload.single('file'), async (req, res) => {
  try {
    const file = req.file;
    if (!file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const result = await uploadToPinata(file.path);
    res.json({ cid: result.IpfsHash });
  } catch (err) {
    console.error('Upload Error:', err.message);
    res.status(500).json({ error: 'Failed to upload to Pinata' });
  }
});

app.post('/delete', async (req, res) => {
  try {
    const { cid } = req.body;
    if (!cid) {
      return res.status(400).json({ error: 'CID is required' });
    }
    await deleteFromPinata(cid);
    res.json({ success: true });
  } catch (err) {
    console.error('Delete Error:', err.message);
    res.status(500).json({ error: 'Failed to delete from Pinata' });
  }
});

app.get('/files', (req, res) => {
  const files = readFilesDb();
  res.json(files);
});

app.post('/file-meta', (req, res) => {
  const meta = req.body;
  if (!meta || !meta.id || !meta.name || !meta.size || !meta.uploadDate || !meta.mimeType || !meta.blockchainHash) {
    return res.status(400).json({ error: 'Invalid file metadata' });
  }
  const files = readFilesDb();
  files.push(meta);
  writeFilesDb(files);
  res.json({ success: true });
});

app.post('/delete-meta', (req, res) => {
  const { id } = req.body;
  if (!id) return res.status(400).json({ error: 'File id required' });
  let files = readFilesDb();
  files = files.filter(f => f.id !== id);
  writeFilesDb(files);
  res.json({ success: true });
});

const PORT = 5000;
app.listen(PORT, () => {
  console.log(`🚀 Backend server running on http://localhost:${PORT}`);
});
