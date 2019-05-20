window.exo.bind('update.exonotch.modern', (modern) => {
    let burnInProtectionCss = document.getElementById('oledBurnInProtectionCss');
    if (window.exo.get('exonotch.disableBurnInProtection')) {
        burnInProtectionCss.disabled = false;
    } else {
        burnInProtectionCss.disabled = !modern;
    }
});

window.exo.bind('update.exonotch.disableBurnInProtection', (disable) => {
    let burnInProtectionCss = document.getElementById('oledBurnInProtectionCss');
    if (disable) {
        burnInProtectionCss.disabled = true;
    } else {
        burnInProtectionCss.disabled = !window.exo.get('exonotch.modern');
    }
});