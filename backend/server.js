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
const SHARED_FILES_DB_PATH = path.join(__dirname, 'shared_files_db.json');

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

function readSharedFilesDb() {
  if (!fs.existsSync(SHARED_FILES_DB_PATH)) return [];
  const data = fs.readFileSync(SHARED_FILES_DB_PATH, 'utf-8');
  try {
    return JSON.parse(data);
  } catch {
    return [];
  }
}

function writeSharedFilesDb(sharedFiles) {
  fs.writeFileSync(SHARED_FILES_DB_PATH, JSON.stringify(sharedFiles, null, 2));
}

// Helper function to check if user is admin
function isAdminUser(userEmail) {
  // Define admin emails here - you can modify this list as needed
  const adminEmails = ['admin@fylez.com', 'nikhil@fylez.com'];
  return adminEmails.includes(userEmail);
}

app.post('/upload', upload.single('file'), async (req, res) => {
  try {
    const file = req.file;
    const { userEmail } = req.body;
    
    if (!file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }
    
    if (!userEmail) {
      return res.status(400).json({ error: 'User email is required' });
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
  const { userEmail } = req.query;
  const files = readFilesDb();
  
  if (!userEmail) {
    return res.status(400).json({ error: 'User email is required' });
  }
  
  // If admin user, return all files. Otherwise, filter by userEmail
  if (isAdminUser(userEmail)) {
    res.json(files);
  } else {
    const userFiles = files.filter(file => file.userEmail === userEmail);
    res.json(userFiles);
  }
});

app.post('/file-meta', (req, res) => {
  const meta = req.body;
  if (!meta || !meta.id || !meta.name || !meta.size || !meta.uploadDate || !meta.mimeType || !meta.blockchainHash || !meta.userEmail) {
    return res.status(400).json({ error: 'Invalid file metadata - userEmail is required' });
  }
  const files = readFilesDb();
  files.push(meta);
  writeFilesDb(files);
  res.json({ success: true });
});

app.delete('/delete/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { userEmail } = req.query;
    
    if (!userEmail) {
      return res.status(400).json({ error: 'User email is required' });
    }
    
    let files = readFilesDb();
    let fileToDelete;
    
    if (isAdminUser(userEmail)) {
      // Admin can delete any file
      fileToDelete = files.find(f => f.id === id);
    } else {
      // Regular users can only delete their own files
      fileToDelete = files.find(f => f.id === id && f.userEmail === userEmail);
    }
    
    if (!fileToDelete) {
      return res.status(404).json({ error: 'File not found or access denied' });
    }
    
    // Delete from Pinata
    if (fileToDelete.blockchainHash) {
      try {
        await deleteFromPinata(fileToDelete.blockchainHash);
        console.log(`Deleted file ${fileToDelete.name} from Pinata`);
      } catch (error) {
        console.error(`Failed to delete file from Pinata:`, error.message);
      }
    }
    
    // Remove from metadata
    if (isAdminUser(userEmail)) {
      // Admin can delete any file
      files = files.filter(f => f.id !== id);
    } else {
      // Regular users can only delete their own files
      files = files.filter(f => !(f.id === id && f.userEmail === userEmail));
    }
    writeFilesDb(files);
    
    res.json({ success: true });
  } catch (error) {
    console.error('Delete Error:', error.message);
    res.status(500).json({ error: 'Failed to delete file' });
  }
});

// Folder endpoints
app.get('/folders', (req, res) => {
  const { userEmail } = req.query;
  const folders = readFoldersDb();
  
  if (!userEmail) {
    return res.status(400).json({ error: 'User email is required' });
  }
  
  // If admin user, return all folders. Otherwise, filter by userEmail
  if (isAdminUser(userEmail)) {
    res.json(folders);
  } else {
    const userFolders = folders.filter(folder => folder.userEmail === userEmail);
    res.json(userFolders);
  }
});

app.post('/folders', (req, res) => {
  const meta = req.body;
  if (!meta || !meta.id || !meta.name || !meta.createdDate || !meta.userEmail) {
    return res.status(400).json({ error: 'Invalid folder metadata - userEmail is required' });
  }
  const folders = readFoldersDb();
  
  // Add the new folder
  folders.push(meta);
  
  // If this folder has a parent, update the parent's subFolderIds
  if (meta.parentFolderId) {
    const parentFolder = folders.find(f => f.id === meta.parentFolderId && f.userEmail === meta.userEmail);
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
  if (!updatedFolder || !updatedFolder.id || !updatedFolder.name || !updatedFolder.userEmail) {
    return res.status(400).json({ error: 'Invalid folder data - userEmail is required' });
  }
  
  let folders = readFoldersDb();
  let index;
  
  if (isAdminUser(updatedFolder.userEmail)) {
    // Admin can update any folder
    index = folders.findIndex(f => f.id === id);
  } else {
    // Regular users can only update their own folders
    index = folders.findIndex(f => f.id === id && f.userEmail === updatedFolder.userEmail);
  }
  
  if (index === -1) {
    return res.status(404).json({ error: 'Folder not found or access denied' });
  }
  
  folders[index] = updatedFolder;
  writeFoldersDb(folders);
  res.json({ success: true });
});

app.delete('/folders/:id', async (req, res) => {
  const { id } = req.params;
  const { userEmail } = req.query;
  
  if (!userEmail) {
    return res.status(400).json({ error: 'User email is required' });
  }
  
  let folders = readFoldersDb();
  let files = readFilesDb();
  
  // Recursive function to delete folder and all its contents
  async function deleteFolderRecursively(folderId, requestingUserEmail) {
    let folder;
    
    if (isAdminUser(requestingUserEmail)) {
      // Admin can delete any folder
      folder = folders.find(f => f.id === folderId);
    } else {
      // Regular users can only delete their own folders
      folder = folders.find(f => f.id === folderId && f.userEmail === requestingUserEmail);
    }
    
    if (!folder) return;
    
    // Delete all files in this folder from Pinata first
    let filesToDelete;
    if (isAdminUser(requestingUserEmail)) {
      // Admin can delete any files in the folder
      filesToDelete = files.filter(f => f.folderId === folderId);
    } else {
      // Regular users can only delete their own files
      filesToDelete = files.filter(f => f.folderId === folderId && f.userEmail === requestingUserEmail);
    }
    
    for (const file of filesToDelete) {
      try {
        await deleteFromPinata(file.blockchainHash);
        console.log(`Deleted file ${file.name} (${file.blockchainHash}) from Pinata`);
      } catch (error) {
        console.error(`Failed to delete file ${file.name} from Pinata:`, error.message);
      }
    }
    
    // Remove files from metadata
    if (isAdminUser(requestingUserEmail)) {
      files = files.filter(f => f.folderId !== folderId);
    } else {
      files = files.filter(f => !(f.folderId === folderId && f.userEmail === requestingUserEmail));
    }
    
    // Recursively delete all subfolders
    if (folder.subFolderIds && folder.subFolderIds.length > 0) {
      for (const subFolderId of folder.subFolderIds) {
        await deleteFolderRecursively(subFolderId, requestingUserEmail);
      }
    }
    
    // Remove the folder itself
    if (isAdminUser(requestingUserEmail)) {
      folders = folders.filter(f => f.id !== folderId);
    } else {
      folders = folders.filter(f => !(f.id === folderId && f.userEmail === requestingUserEmail));
    }
  }
  
  try {
    // Find the folder to be deleted to get its parent
    let folderToDelete;
    if (isAdminUser(userEmail)) {
      folderToDelete = folders.find(f => f.id === id);
    } else {
      folderToDelete = folders.find(f => f.id === id && f.userEmail === userEmail);
    }
    
    if (!folderToDelete) {
      return res.status(404).json({ error: 'Folder not found or access denied' });
    }
    
    // Remove this folder ID from its parent's subFolderIds
    if (folderToDelete.parentFolderId) {
      let parentFolder;
      if (isAdminUser(userEmail)) {
        parentFolder = folders.find(f => f.id === folderToDelete.parentFolderId);
      } else {
        parentFolder = folders.find(f => f.id === folderToDelete.parentFolderId && f.userEmail === userEmail);
      }
      
      if (parentFolder && parentFolder.subFolderIds) {
        parentFolder.subFolderIds = parentFolder.subFolderIds.filter(subId => subId !== id);
      }
    }
    
    // Delete the folder and all its contents recursively
    await deleteFolderRecursively(id, userEmail);
    
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
  if (!updatedFile || !updatedFile.id || !updatedFile.name || !updatedFile.userEmail) {
    return res.status(400).json({ error: 'Invalid file data - userEmail is required' });
  }
  
  let files = readFilesDb();
  let index;
  
  if (isAdminUser(updatedFile.userEmail)) {
    // Admin can update any file
    index = files.findIndex(f => f.id === id);
  } else {
    // Regular users can only update their own files
    index = files.findIndex(f => f.id === id && f.userEmail === updatedFile.userEmail);
  }
  
  if (index === -1) {
    return res.status(404).json({ error: 'File not found or access denied' });
  }
  
  files[index] = updatedFile;
  writeFilesDb(files);
  res.json({ success: true });
});

// File sharing endpoints
app.post('/share-file', (req, res) => {
  const { fileId, ownerEmail, sharedWithEmail } = req.body;
  
  if (!fileId || !ownerEmail || !sharedWithEmail) {
    return res.status(400).json({ error: 'File ID, owner email, and shared with email are required' });
  }
  
  // Verify the file exists and belongs to the owner
  const files = readFilesDb();
  const file = files.find(f => f.id === fileId && f.userEmail === ownerEmail);
  if (!file) {
    return res.status(404).json({ error: 'File not found or access denied' });
  }
  
  // Check if already shared with this user
  const sharedFiles = readSharedFilesDb();
  const existingShare = sharedFiles.find(sf => 
    sf.fileId === fileId && sf.sharedWithEmail === sharedWithEmail
  );
  
  if (existingShare) {
    return res.status(400).json({ error: 'File already shared with this user' });
  }
  
  // Create sharing record
  const shareRecord = {
    id: Date.now().toString(),
    fileId,
    ownerEmail,
    sharedWithEmail,
    sharedAt: new Date().toISOString(),
  };
  
  sharedFiles.push(shareRecord);
  writeSharedFilesDb(sharedFiles);
  
  res.json({ success: true, message: 'File shared successfully' });
});

app.delete('/revoke-access/:fileId/:sharedWithEmail', (req, res) => {
  const { fileId, sharedWithEmail } = req.params;
  const { ownerEmail } = req.query;
  
  if (!ownerEmail) {
    return res.status(400).json({ error: 'Owner email is required' });
  }
  
  // Verify the file belongs to the owner
  const files = readFilesDb();
  const file = files.find(f => f.id === fileId && f.userEmail === ownerEmail);
  if (!file) {
    return res.status(404).json({ error: 'File not found or access denied' });
  }
  
  // Remove sharing record
  let sharedFiles = readSharedFilesDb();
  const originalLength = sharedFiles.length;
  sharedFiles = sharedFiles.filter(sf => 
    !(sf.fileId === fileId && sf.sharedWithEmail === sharedWithEmail && sf.ownerEmail === ownerEmail)
  );
  
  if (sharedFiles.length === originalLength) {
    return res.status(404).json({ error: 'Sharing record not found' });
  }
  
  writeSharedFilesDb(sharedFiles);
  res.json({ success: true, message: 'Access revoked successfully' });
});

app.get('/shared-with-me', (req, res) => {
  const { userEmail } = req.query;
  
  if (!userEmail) {
    return res.status(400).json({ error: 'User email is required' });
  }
  
  const sharedFiles = readSharedFilesDb();
  const files = readFilesDb();
  
  // Get all files shared with this user
  const mySharedFiles = sharedFiles
    .filter(sf => sf.sharedWithEmail === userEmail)
    .map(sf => {
      const file = files.find(f => f.id === sf.fileId);
      if (file) {
        return {
          ...file,
          sharedBy: sf.ownerEmail,
          sharedAt: sf.sharedAt,
          shareId: sf.id,
        };
      }
      return null;
    })
    .filter(Boolean);
  
  res.json(mySharedFiles);
});

app.get('/file-shares/:fileId', (req, res) => {
  const { fileId } = req.params;
  const { ownerEmail } = req.query;
  
  if (!ownerEmail) {
    return res.status(400).json({ error: 'Owner email is required' });
  }
  
  // Verify the file belongs to the owner
  const files = readFilesDb();
  const file = files.find(f => f.id === fileId && f.userEmail === ownerEmail);
  if (!file) {
    return res.status(404).json({ error: 'File not found or access denied' });
  }
  
  const sharedFiles = readSharedFilesDb();
  const fileShares = sharedFiles.filter(sf => sf.fileId === fileId && sf.ownerEmail === ownerEmail);
  
  res.json(fileShares);
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Backend server running on http://localhost:${PORT}`);
});
