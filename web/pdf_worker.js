// 🪪 Jugendpass / Konfipass PDF Generator
// — Mit farbigen Akzenten in Türkis (rgb(37,150,190)) —

self.onmessage = async (e) => {
  const {
    firstName,
    lastName,
    username,
    password,
    uuid,
    frontImage,
    backImage,
    qrImage
  } = e.data;

  importScripts('https://cdn.jsdelivr.net/npm/pdf-lib/dist/pdf-lib.min.js');
  const { PDFDocument, rgb, StandardFonts } = PDFLib;

  try {
    const pdfDoc = await PDFDocument.create();

    // --------------------------------------------------
    // 🔹 VORDERSEITE
    // --------------------------------------------------
    const frontPage = pdfDoc.addPage([842, 595]); // A4 quer
    const frontImageBytes = new Uint8Array(frontImage);
    const frontPng = await pdfDoc.embedPng(frontImageBytes);
    frontPage.drawImage(frontPng, { x: 0, y: 0, width: 842, height: 595 });

    const helvetica = await pdfDoc.embedFont(StandardFonts.Helvetica);
    const helveticaBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

    // 🏷️ Name
    frontPage.drawText(`${firstName} ${lastName}`, {
    x: 160,
    y: 498,
    size: 26,
    font: helveticaBold,
    color: rgb(0, 0, 0),
    });

    // 🔳 QR-Code
    if (qrImage) {
    const qrBytes = new Uint8Array(qrImage);
    const qrPng = await pdfDoc.embedPng(qrBytes);
    frontPage.drawImage(qrPng, {
      x: 85,
      y: 175,
      width: 250,
      height: 250,
    });
    }


    // --------------------------------------------------
    // 🔹 RÜCKSEITE
    // --------------------------------------------------
    const backPage = pdfDoc.addPage([842, 595]);
    const backImageBytes = new Uint8Array(backImage);
    const backPng = await pdfDoc.embedPng(backImageBytes);
    backPage.drawImage(backPng, { x: 0, y: 0, width: 842, height: 595 });

    // 🧠 Hinweis
    backPage.drawText('Bitte diesen Pass sicher aufbewahren. Bei Verlust melden!', {
    x: 50,
    y: 80,
    size: 12,
    font: helvetica,
    color: rgb(0.4, 0.4, 0.4),
    });

     // 💬 Benutzername & Passwort
    backPage.drawText(`${firstName} ${lastName}`, {
    x: 140,
    y: 505,
    size: 16,
    font: helvetica,
    color: rgb(0.2, 0.2, 0.2),
    });


    // 💬 Benutzername & Passwort
    backPage.drawText(`${username || "—"}`, {
     x: 205,
     y: 470,
     size: 16,
     font: helvetica,
     color: rgb(0.2, 0.2, 0.2),
    });

    backPage.drawText(`${password}`, {
     x: 205,
     y: 438,
     size: 16,
     font: helvetica,
     color: rgb(0.2, 0.2, 0.2),
    });

    const pdfBytes = await pdfDoc.save();
    self.postMessage(pdfBytes);
  } catch (err) {
    console.error("Fehler im PDF Worker:", err);
    self.postMessage({ error: err.message });
  }
};
