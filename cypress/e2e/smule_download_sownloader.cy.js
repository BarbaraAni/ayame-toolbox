// cypress/e2e/sownloader_download.cy.js
import 'cypress-wait-until';

Cypress.on('uncaught:exception', () => {
    return false;
});

describe('Smule to MP3 via Sownloader', () => {
    it('downloads MP3 from Sownloader', () => {
        cy.readFile('cypress/data/smule_urls.txt').then((content) => {
            const urls = content.split('\n').filter(Boolean);

            cy.writeFile('cypress/data/skipped_urls.txt', '');

            for (const url of urls) {
                cy.log('Processing: ' + url); // NOT shown in terminal
                cy.task('logToTerminal', `Starting download for: ${url}`);
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

                    cy.contains('button', 'Download as MP3', { timeout: 20000 })
                        .should('be.visible')
                        .then($btn => {
                            const onclick = $btn.attr('onclick');
                            const match = /convert\([^,]+,[^,]+,\s*'([^']+)'\)/.exec(onclick);
                            const title = match ? match[1].trim() : 'Unknown';
                            const safeTitle = title.replace(/[:*?"<>|\\\/]/g, '_');
                            const filename = `${safeTitle}.mp3`;
                            cy.task('logToTerminal', `Title ${title} - SafeTitle: ${safeTitle}`);

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
                                    cy.task('logToTerminal', `SUCCESS ${url}`);
                                } else {
                                    cy.log('Download file not found.');
                                    cy.task('logToTerminal', `XX MOVE FAIL: ${url}`);
                                }
                            });
                        });
                });
            }
            cy.wait(7000); // or wait for file detection if implemented
        });
    });
});