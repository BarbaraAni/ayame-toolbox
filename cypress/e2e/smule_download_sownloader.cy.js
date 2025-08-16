// cypress/e2e/sownloader_download.cy.js
import 'cypress-wait-until';

Cypress.on('uncaught:exception', () => {
    return false;
});

describe('Smule to MP3 via Sownloader', () => {
    it('downloads MP3 from Sownloader', () => {
        const now = new Date();
        const timestamp = now.toISOString().replace('T', ' ').split('.')[0];
        cy.task('logToTerminal', `=== Starting Smule download at ${timestamp} ===`);

        cy.readFile('cypress/data/metadata.txt').then((content) => {
        const urls = content
            .split(/\r?\n/)                           // split into lines (handles Windows & Unix newlines)
            .map(line => line.split('\t')[0].trim())  // take text before first tab
            .filter(Boolean);                         // drop empty lines

            urls.push("https://www.smule.com/recording/fake-coz-last-aint-workin");

            cy.writeFile('cypress/data/skipped_urls.txt', '');

            let count = 0;
            for (const url of urls) {
                count++;
                const timestamp = now.toISOString().replace('T', ' ').split('.')[0];
                cy.task('logToTerminal', `=== ${timestamp} ===`);
                cy.task('logToTerminal', `=== (${count}/${urls.length}) ===`);
                cy.task('logToTerminal', `[Starting] download for: ${url}`);
                cy.visit('https://sownloader.com');

                cy.get('input[name="url"]', { timeout: 10000 })
                    .should('be.visible')
                    .clear()
                    .type(url);

                cy.get('body').then($body => {
                    if ($body.text().includes('Error! Could not find performance data. Please try again later.')) {
                        cy.log('XX Error: No performance data. Skipping...');
                        cy.writeFile('cypress/data/skipped_urls.txt', `${url}\n`, { flag: 'a+' }); // anhängen
                        return;
                    }

                    cy.get('body').then($body => {
                      const btn = $body.find('button[type="submit"]#button-addon2');

                      if (btn.length && btn.text().trim() === 'Download') {
                        cy.wrap(btn).click();
                        cy.log('✅ Clicked the Download button');
                      } else {
                        cy.log('ℹ️ Download button not found, continuing...');
                      }
                    });

                    cy.contains('button', 'Download as MP3', { timeout: 20000 })
                        .should('be.visible')
                        .then($btn => {
                            const onclick = $btn.attr('onclick');
                            const match = /convert\([^,]+,[^,]+,\s*'([^']+)'\)/.exec(onclick);
                            const title = match ? match[1].trim() : 'Unknown';
                            const safeTitle = title.replace(/[:*?"<>|\\\/]/g, '_');
                            const filename = `${safeTitle}.mp3`;
                            cy.task('logToTerminal', `[TITLE] ${title} - SafeTitle: ${safeTitle}`);

                            cy.wrap($btn).click();

                            cy.contains('This might take a few minutes', { timeout: 60000 })
                                .should('not.exist');

                            const failedDownloads = [];

                            cy.waitUntil(() => {
                                return cy.task('checkFileExists', {
                                    folder: 'cypress/downloads',
                                    filename
                                });
                            }, {
                                timeout: 20000,
                                interval: 500,
                                errorMsg: 'File did not download in time',
                                verbose: false,
                                failSilently: true
                            }).then((success) => {
                                if (!success) {
                                    failedDownloads.push(url);
                                    cy.log(`XX Download failed for: ${filename}`);
                                    cy.writeFile('cypress/data/skipped_urls.txt', `${url}\n`, { flag: 'a+' });
                                } else {
                                    cy.log('Download succeeded');
                                }
                            });

                            cy.task('moveDownloadedFile', {
                                baseFolder: 'cypress/downloads',
                                filename
                            }).then((movedPath) => {
                                if (movedPath) {
                                    cy.log(`Saved in: ${movedPath}`);
                                    cy.task('logToTerminal', `[SUCCESS] ${url}`);
                                } else {
                                    cy.log('Download file not found.');
                                    cy.task('logToTerminal', `[XX MOVE FAIL]: ${url}`);
                                }
                            });
                        });
                });
            }
            cy.wait(7000); // or wait for file detection if implemented
        });
    });
});