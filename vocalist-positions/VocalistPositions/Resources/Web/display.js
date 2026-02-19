(function() {
    'use strict';

    let lastConfigJSON = null;

    async function fetchConfig() {
        try {
            const response = await fetch('/api/config');
            if (!response.ok) return null;
            const text = await response.text();
            if (!text || text === '{}') return null;
            return JSON.parse(text);
        } catch {
            return null;
        }
    }

    function render(config) {
        const container = document.getElementById('vocalists');
        container.innerHTML = '';

        if (!config.vocalists || config.vocalists.length === 0) {
            container.innerHTML = '<div class="waiting"><p>No vocalists configured</p></div>';
            return;
        }

        config.vocalists.forEach(function(vox) {
            const col = document.createElement('div');
            col.className = 'vocalist-col';

            // Background photo: operator photo overrides angle photo
            var photoFilename = vox.operatorPhotoFilename || vox.anglePhotoFilename;
            if (photoFilename) {
                const img = document.createElement('img');
                img.className = 'angle-photo';
                img.src = '/api/images/' + photoFilename;
                img.alt = 'VOX ' + vox.number;
                col.appendChild(img);

                // Overlay for readability
                const overlay = document.createElement('div');
                overlay.className = 'overlay';
                col.appendChild(overlay);
            } else {
                col.classList.add('no-photo');
            }

            // Content layer (above photo)
            const content = document.createElement('div');
            content.className = 'content';

            // Center group: vocalist number + label, always dead center
            const centerGroup = document.createElement('div');
            centerGroup.className = 'center-group';

            const numDiv = document.createElement('div');
            numDiv.className = 'vox-number';
            numDiv.textContent = vox.number;
            centerGroup.appendChild(numDiv);

            // Label (if any)
            if (vox.label) {
                const labelDiv = document.createElement('div');
                labelDiv.className = 'vox-label';
                labelDiv.textContent = vox.label;
                centerGroup.appendChild(labelDiv);
            }

            content.appendChild(centerGroup);

            // Bottom section: name
            const bottom = document.createElement('div');
            bottom.className = 'bottom-info';

            // Operator name at the bottom
            if (vox.operatorName) {
                const nameDiv = document.createElement('div');
                nameDiv.className = 'operator-name';
                nameDiv.textContent = vox.operatorName;
                bottom.appendChild(nameDiv);
            } else {
                const emptyDiv = document.createElement('div');
                emptyDiv.className = 'operator-empty';
                emptyDiv.textContent = 'Unassigned';
                bottom.appendChild(emptyDiv);
            }

            content.appendChild(bottom);
            col.appendChild(content);
            container.appendChild(col);
        });
    }

    async function poll() {
        const config = await fetchConfig();
        const configJSON = JSON.stringify(config);

        if (config && configJSON !== lastConfigJSON) {
            lastConfigJSON = configJSON;
            render(config);
        }
    }

    // Clock
    function updateClock() {
        const now = new Date();
        var hours = now.getHours();
        var ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12 || 12;
        var minutes = now.getMinutes().toString().padStart(2, '0');
        var seconds = now.getSeconds().toString().padStart(2, '0');
        document.getElementById('clock').textContent = hours + ':' + minutes + ':' + seconds + ' ' + ampm;
    }

    // Poll every 5 seconds
    setInterval(poll, 5000);
    poll();

    // Update clock every second
    setInterval(updateClock, 1000);
    updateClock();
})();
