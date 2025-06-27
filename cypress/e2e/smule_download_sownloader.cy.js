// cypress/e2e/sownloader_download.cy.js

describe('Smule to MP3 via Sownloader', () => {
  const smuleUrl = 'https://www.smule.com/recording/barbra-streisand-cats-memory-epic-cover/698735767_5030064796';

  it('downloads MP3 from Sownloader', () => {
    cy.visit('https://sownloader.com');

    // Input Smule URL
    cy.get('input[name="url"]', { timeout: 10000 })
      .should('be.visible')
      .type(smuleUrl);

    cy.get('button[type="submit"]')
      .should('be.visible')
      .click();

    // Wait for download section to appear
    cy.get('a.btn-download[href*="downloader.php"]', { timeout: 20000 })
      .should('have.attr', 'href')
      .then(href => {
        const downloadUrl = href;
        cy.log('Download link:', downloadUrl);

        // Programmatic file download using browser-fetch workaround
        cy.request({
          url: downloadUrl,
          encoding: 'binary'
        }).then((response) => {
          const filename = downloadUrl.split('name=')[1].split('&')[0] + '.mp3';
          const path = `cypress/downloads/smule/${filename}`;

          cy.writeFile(path, response.body, 'binary');
        });
      });
  });
});
