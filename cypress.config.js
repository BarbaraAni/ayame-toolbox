const { defineConfig } = require("cypress");
const path = require('path');
const fs = require('fs');
const fse = require('fs-extra');

module.exports = {
  e2e: {
    baseUrl: "https://sownloader.com",
    supportFile: false,
    setupNodeEvents(on, config) {
      on('task', {
        moveDownloadedFile({ baseFolder, filename }) {
          const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
          const subfolder = path.join(baseFolder, timestamp);

          const srcPath = path.join(baseFolder, filename);
          const destPath = path.join(subfolder, filename);

          if (!fs.existsSync(srcPath)) {
            return null;
          }

          fse.ensureDirSync(subfolder);
          fse.moveSync(srcPath, destPath, { overwrite: true });

          return destPath;
        }
      });
    },
    downloadsFolder: 'cypress/downloads'
  }
};
