// cypress/e2e/sownloader_download.cy.js

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
                        cy.log('❌ Error: No performance data. Skipping...');
                        cy.writeFile('cypress/data/skipped_urls.txt', `${url}\n`, { flag: 'a+' }); // anhängen
                        return;
                    }

                    cy.contains('button', 'Download as MP3', { timeout: 20000 })
                      .should('be.visible')
                      .then($btn => {
                        const onclick = $btn.attr('onclick');
                        const match = /convert\([^,]+,[^,]+,\s*'([^']+)'\)/.exec(onclick);
                        const title = match ? match[1].trim() : 'Unknown';
                        cy.task('logToTerminal', `Title for: ${url} - ${title}`);
                        const filename = `${title}.mp3`;

                        cy.wrap($btn).click();

                        cy.contains('This might take a few minutes', { timeout: 60000 })
                          .should('not.exist');

                        cy.task('logToTerminal', `Download clicked for: ${url} - waiting`);
                        cy.wait(1500);

                        cy.task('moveDownloadedFile', {
                          baseFolder: 'cypress/downloads',
                          filename
                        }).then((movedPath) => {
                          if (movedPath) {
                            cy.log(`Saved in: ${movedPath}`);
                            cy.task('logToTerminal', `Saved ${url} ${filename}`);
                          } else {
                            cy.log('Download file not found.');
                            cy.task('logToTerminal', `Download file not found: ${url} ${filename}`);
                          }
                        });
                      });
                });
            }
        });
    });
});