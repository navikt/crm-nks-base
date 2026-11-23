(function () {
    async function loadPreview() {
        const preview = document.getElementById('nks-print-preview');
        if (!preview) {
            return;
        }

        const status = document.getElementById('nks-print-status');
        const frame = document.getElementById('nks-print-frame');
        try {
            const response = await fetch(preview.dataset.pdfUrl, {
                credentials: 'same-origin',
                cache: 'no-store',
                headers: { Accept: 'application/pdf' }
            });
            if (!response.ok) {
                throw new Error(`PDF request failed (HTTP ${response.status}).`);
            }
            if (!response.headers.get('Content-Type')?.toLowerCase().includes('application/pdf')) {
                throw new Error('The print page did not return a PDF.');
            }

            // Preview the authorized response locally, without framing the protected Visualforce URL.
            const pdfUrl = URL.createObjectURL(await response.blob());
            window.addEventListener('pagehide', () => URL.revokeObjectURL(pdfUrl), { once: true });
            frame.src = pdfUrl;
            frame.hidden = false;
            status.hidden = true;
        } catch (error) {
            console.error('Unable to load print preview', error);
            status.textContent = 'Kunne ikke laste PDF-en. Last siden igjen eller kontakt support.';
            status.setAttribute('role', 'alert');
        } finally {
            preview.setAttribute('aria-busy', 'false');
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', loadPreview, { once: true });
    } else {
        loadPreview();
    }
})();
