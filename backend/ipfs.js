// ipfs.js
const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');
const { PINATA_API_KEY, PINATA_SECRET_API_KEY, PINATA_JWT } = require('./secrets');

exports.uploadToPinata = async (filePath) => {
  const data = new FormData();
  data.append('file', fs.createReadStream(filePath));

  const res = await axios.post(
    'https://api.pinata.cloud/pinning/pinFileToIPFS',
    data,
    {
      maxBodyLength: Infinity,
      headers: {
        ...data.getHeaders(),
        pinata_api_key: PINATA_API_KEY,
        pinata_secret_api_key: PINATA_SECRET_API_KEY,
      },
    }
  );

  return res.data; // returns { IpfsHash, PinSize, Timestamp }
};

exports.deleteFromPinata = async (cid) => {
  const url = `https://api.pinata.cloud/pinning/unpin/${cid}`;
  await axios.delete(url, {
    headers: {
      Authorization: `Bearer ${PINATA_JWT}`,
    },
  });
};
