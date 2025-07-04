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
const FOLDERS_DB_PATH = path.join(__dirname, 'folders_db.json');

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

function readFoldersDb() {
  if (!fs.existsSync(FOLDERS_DB_PATH)) return [];
  const data = fs.readFileSync(FOLDERS_DB_PATH, 'utf-8');
  try {
    return JSON.parse(data);
  } catch {
    return [];
  }
}

function writeFoldersDb(folders) {
  fs.writeFileSync(FOLDERS_DB_PATH, JSON.stringify(folders, null, 2));
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

// File endpoints
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

// Folder endpoints
app.get('/folders', (req, res) => {
  const folders = readFoldersDb();
  res.json(folders);
});

app.post('/folders', (req, res) => {
  const meta = req.body;
  if (!meta || !meta.id || !meta.name || !meta.createdDate) {
    return res.status(400).json({ error: 'Invalid folder metadata' });
  }
  const folders = readFoldersDb();
  
  // Add the new folder
  folders.push(meta);
  
  // If this folder has a parent, update the parent's subFolderIds
  if (meta.parentFolderId) {
    const parentFolder = folders.find(f => f.id === meta.parentFolderId);
    if (parentFolder) {
      if (!parentFolder.subFolderIds) {
        parentFolder.subFolderIds = [];
      }
      if (!parentFolder.subFolderIds.includes(meta.id)) {
        parentFolder.subFolderIds.push(meta.id);
      }
    }
  }
  
  writeFoldersDb(folders);
  res.json({ success: true });
});

app.put('/folders/:id', (req, res) => {
  const { id } = req.params;
  const updatedFolder = req.body;
  if (!updatedFolder || !updatedFolder.id || !updatedFolder.name) {
    return res.status(400).json({ error: 'Invalid folder data' });
  }
  
  let folders = readFoldersDb();
  const index = folders.findIndex(f => f.id === id);
  if (index === -1) {
    return res.status(404).json({ error: 'Folder not found' });
  }
  
  folders[index] = updatedFolder;
  writeFoldersDb(folders);
  res.json({ success: true });
});

app.delete('/folders/:id', async (req, res) => {
  const { id } = req.params;
  let folders = readFoldersDb();
  let files = readFilesDb();
  
  // Recursive function to delete folder and all its contents
  async function deleteFolderRecursively(folderId) {
    const folder = folders.find(f => f.id === folderId);
    if (!folder) return;
    
    // Delete all files in this folder from Pinata first
    const filesToDelete = files.filter(f => f.folderId === folderId);
    for (const file of filesToDelete) {
      try {
        await deleteFromPinata(file.blockchainHash);
        console.log(`Deleted file ${file.name} (${file.blockchainHash}) from Pinata`);
      } catch (error) {
        console.error(`Failed to delete file ${file.name} from Pinata:`, error.message);
      }
    }
    
    // Remove files from metadata
    files = files.filter(f => f.folderId !== folderId);
    
    // Recursively delete all subfolders
    if (folder.subFolderIds && folder.subFolderIds.length > 0) {
      for (const subFolderId of folder.subFolderIds) {
        await deleteFolderRecursively(subFolderId);
      }
    }
    
    // Remove the folder itself
    folders = folders.filter(f => f.id !== folderId);
  }
  
  try {
    // Find the folder to be deleted to get its parent
    const folderToDelete = folders.find(f => f.id === id);
    if (!folderToDelete) {
      return res.status(404).json({ error: 'Folder not found' });
    }
    
    // Remove this folder ID from its parent's subFolderIds
    if (folderToDelete.parentFolderId) {
      const parentFolder = folders.find(f => f.id === folderToDelete.parentFolderId);
      if (parentFolder && parentFolder.subFolderIds) {
        parentFolder.subFolderIds = parentFolder.subFolderIds.filter(subId => subId !== id);
      }
    }
    
    // Delete the folder and all its contents recursively
    await deleteFolderRecursively(id);
    
    // Save the updated data
    writeFoldersDb(folders);
    writeFilesDb(files);
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting folder:', error.message);
    res.status(500).json({ error: 'Failed to delete folder completely' });
  }
});

app.put('/file-meta/:id', (req, res) => {
  const { id } = req.params;
  const updatedFile = req.body;
  if (!updatedFile || !updatedFile.id || !updatedFile.name) {
    return res.status(400).json({ error: 'Invalid file data' });
  }
  
  let files = readFilesDb();
  const index = files.findIndex(f => f.id === id);
  if (index === -1) {
    return res.status(404).json({ error: 'File not found' });
  }
  
  files[index] = updatedFile;
  writeFilesDb(files);
  res.json({ success: true });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Backend server running on http://localhost:${PORT}`);
});
