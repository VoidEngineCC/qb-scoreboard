let currentTheme = 'red';
let currentScale = 100;
let themes = {};

// Error handling wrapper for fetch
async function sendNuiMessage(data) {
    try {
        const resp = await fetch(`https://qb-scoreboard/${data.action}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify(data.data || {})
        });
        return await resp.json();
    } catch (e) {
        console.log('NUI Error:', e);
        return null;
    }
}

// NUI Callbacks
window.addEventListener('message', function(event) {
    const data = event.data;
    const action = data.action;
    
    try {
        switch(action) {
            case 'hideUI':
                $('#scoreboard, #settingsMenu').hide();
                $('body').css('cursor', 'default');
                break;
                
            case 'openScoreboard':
                if (data.activities && data.counts) {
                    updateActivityList(data.activities, data.counts);
                    $('#scoreboard').fadeIn(300);
                    $('body').css('cursor', 'none');
                } else {
                    console.log('Missing data for scoreboard');
                }
                break;
                
            case 'closeScoreboard':
                $('#scoreboard, #settingsMenu').fadeOut(300, function() {
                    $('body').css('cursor', 'default');
                });
                break;
                
            case 'updateData':
                if (data.activities && data.counts) {
                    updateActivityList(data.activities, data.counts);
                }
                break;
                
            case 'initThemes':
                if (data.themes) {
                    themes = data.themes;
                }
                break;
                
            case 'loadSettings':
                if (data.theme) currentTheme = data.theme;
                if (data.scale) currentScale = data.scale;
                loadSettings();
                break;
                
            case 'applyTheme':
                if (data.theme) {
                    applyThemeToCSS(data.theme);
                }
                break;
                
            case 'applyScale':
                if (data.scale) {
                    applyScaleToUI(data.scale);
                }
                break;
                
            case 'openSettings':
                $('#settingsMenu').fadeIn(300);
                setActiveTheme(currentTheme);
                break;
                
            case 'closeSettings':
                $('#settingsMenu').fadeOut(300);
                break;
                
            default:
                console.log('Unknown action:', action);
        }
    } catch (e) {
        console.log('Error handling message:', e);
        sendNuiMessage({ action: 'error', data: { error: e.toString() } });
    }
});

// Update activity list
function updateActivityList(activities, counts) {
    const activitiesList = $('#activities-list');
    const activitiesCount = $('#activities-count');
    
    // Update counts for all job types with null checks
    $('#police-count').text(counts.police || 0);
    $('#ambulance-count').text(counts.ambulance || 0);
    $('#mechanic-count').text(counts.mechanic || 0);
    $('#bennys-count').text(counts.bennys || 0);
    $('#biker-count').text(counts.biker || 0);
    $('#pizzathis-count').text(counts.pizzathis || 0);
    $('#cardealer-count').text(counts.cardealer || 0);
    $('#beanmachine-count').text(counts.beanmachine || 0);
    $('#total-count').text(counts.total || 0);
    
    // Clear current list
    activitiesList.empty();
    
    // Check if there are activities
    if (!activities || activities.length === 0) {
        activitiesList.html(`
            <div class="empty-state">
                <i class="fas fa-mosque"></i>
                <p>No activities configured</p>
            </div>
        `);
        activitiesCount.text('0 Activities');
        return;
    }
    
    // Count available activities
    let availableCount = 0;
    activities.forEach(activity => {
        if (activity && activity.available) availableCount++;
    });
    
    activitiesCount.text(availableCount + ' Available');
    
    // Add activities to list
    activities.forEach(activity => {
        if (activity) {
            const activityElement = createActivityElement(activity);
            activitiesList.append(activityElement);
        }
    });
}

// Create activity element
function createActivityElement(activity) {
    const status = activity.timeLeft > 0 ? 'cooldown' : (activity.available ? 'available' : 'unavailable');
    const statusText = activity.timeLeft > 0 ? 'COOLDOWN' : (activity.available ? 'AVAILABLE' : 'UNAVAILABLE');
    
    // Determine police status
    const policeStatus = activity.policeCount >= activity.minPolice ? 'met' : 'unmet';
    const policeClass = policeStatus === 'unmet' ? 'warning' : '';
    
    // Determine item status
    const itemStatus = activity.playerHasItem ? 'met' : 'unmet';
    const itemIcon = getItemIcon(activity.requiredItem);
    const itemLabel = getItemLabel(activity.requiredItem);
    
    // Determine cooldown status
    const cooldownStatus = activity.timeLeft <= 0 ? 'met' : 'unmet';
    
    // Create requirements HTML
    let requirementsHTML = '';
    
    if (!activity.available && activity.unmetRequirements) {
        requirementsHTML = `
            <div class="requirement-details">
                <div class="requirement">
                    <div class="requirement-label">
                        <i class="fas fa-shield-alt"></i>
                        <span>Police Required</span>
                    </div>
                    <div class="requirement-status ${policeStatus}">
                        ${activity.policeCount}/${activity.minPolice}
                    </div>
                </div>
                ${activity.minLevel > 1 ? `
                <div class="requirement">
                    <div class="requirement-label">
                        <i class="fas fa-chart-line"></i>
                        <span>Level Required</span>
                    </div>
                    <div class="requirement-status ${activity.unmetRequirements.level ? 'unmet' : 'met'}">
                        ${activity.minLevel}+
                    </div>
                </div>
                ` : ''}
                ${activity.requiredItem ? `
                <div class="requirement">
                    <div class="requirement-label">
                        <i class="fas fa-toolbox"></i>
                        <span>Item Required</span>
                    </div>
                    <div class="requirement-status ${itemStatus}" title="${itemLabel}">
                        ${itemStatus === 'met' ? '✓' : '✗'}
                    </div>
                </div>
                ` : ''}
                ${activity.timeLeft > 0 ? `
                <div class="requirement">
                    <div class="requirement-label">
                        <i class="fas fa-clock"></i>
                        <span>Cooldown</span>
                    </div>
                    <div class="requirement-status ${cooldownStatus}">
                        ${activity.timeLeft}s
                    </div>
                </div>
                ` : ''}
            </div>
        `;
    }
    
    return `
        <div class="activity-item ${status}">
            <div class="activity-header">
                <div class="activity-title">
                    <i class="${escapeHtml(activity.icon)}"></i>
                    <span>${escapeHtml(activity.label)}</span>
                </div>
                <div class="activity-status ${status}">${statusText}</div>
            </div>
            <div class="activity-description">${escapeHtml(activity.description)}</div>
            <div class="activity-details">
                <div class="activity-police ${policeClass}">
                    <i class="fas fa-shield-alt"></i>
                    <span>${activity.policeCount}/${activity.minPolice} Police</span>
                </div>
                ${activity.minLevel > 1 ? `
                <div class="activity-level">
                    <i class="fas fa-chart-line"></i>
                    <span>Lvl ${activity.minLevel}+</span>
                </div>
                ` : ''}
            </div>
            ${requirementsHTML}
        </div>
    `;
}

// Helper function to get item icon
function getItemIcon(itemName) {
    if (!itemName) return 'fas fa-box';
    
    const itemIcons = {
        'thermite': 'fas fa-fire',
        'lockpick': 'fas fa-key',
        'c4': 'fas fa-bomb',
        'weapon_pistol': 'fas fa-gun',
        'advanced_hacking_device': 'fas fa-laptop-code',
        'trojan_usb': 'fas fa-usb',
        'electronickit': 'fas fa-microchip',
        'crowbar': 'fas fa-tools',
        'weapon_bat': 'fas fa-baseball-bat',
        'advancedlockpick': 'fas fa-key'
    };
    
    return itemIcons[itemName] || 'fas fa-box';
}

// Helper function to get item label
function getItemLabel(itemName) {
    if (!itemName) return 'Unknown Item';
    
    const itemLabels = {
        'thermite': 'Thermite',
        'lockpick': 'Lockpick',
        'c4': 'C4 Explosive',
        'weapon_pistol': 'Pistol',
        'advanced_hacking_device': 'Advanced Hacking Device',
        'trojan_usb': 'Trojan USB',
        'electronickit': 'Electronic Kit',
        'crowbar': 'Crowbar',
        'weapon_bat': 'Baseball Bat',
        'advancedlockpick': 'Advanced Lockpick'
    };
    
    return itemLabels[itemName] || itemName;
}

// Escape HTML special characters
function escapeHtml(text) {
    if (!text) return '';
    
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.toString().replace(/[&<>"']/g, function(m) { return map[m]; });
}

// Populate themes in settings
function populateThemes() {
    const themeSelector = $('#theme-selector');
    if (!themeSelector.length) return;
    
    themeSelector.empty();
    
    Object.keys(themes).forEach(themeName => {
        const theme = themes[themeName];
        const themeElement = `
            <div class="theme-option ${themeName === currentTheme ? 'active' : ''}" 
                 data-theme="${themeName}"
                 style="background: linear-gradient(135deg, ${theme.primary}, ${theme.secondary})">
            </div>
        `;
        themeSelector.append(themeElement);
    });
    
    // Add click event to theme options
    $('.theme-option').off('click').on('click', function() {
        const theme = $(this).data('theme');
        setActiveTheme(theme);
        updateTheme(theme);
    });
}

// Set active theme in settings
function setActiveTheme(themeName) {
    $('.theme-option').removeClass('active');
    $(`.theme-option[data-theme="${themeName}"]`).addClass('active');
}

// Update theme and save
function updateTheme(themeName) {
    currentTheme = themeName;
    sendNuiMessage({
        action: 'updateSettings',
        data: {
            theme: themeName,
            scale: currentScale
        }
    });
}

// Update scale and save
function updateScale(scale) {
    currentScale = scale;
    sendNuiMessage({
        action: 'updateSettings',
        data: {
            theme: currentTheme,
            scale: scale
        }
    });
}

// Apply theme to CSS
function applyThemeToCSS(theme) {
    const root = document.documentElement;
    root.style.setProperty('--primary', theme.primary);
    root.style.setProperty('--secondary', theme.secondary);
    root.style.setProperty('--accent', theme.accent);
    root.style.setProperty('--bg-dark', theme.bg);
}

// Apply scale to UI
function applyScaleToUI(scale) {
    const container = $('.scoreboard-container');
    if (container.length) {
        container.css('transform', `scale(${scale / 100})`);
    }
}

// Load settings
function loadSettings() {
    const slider = $('#size-slider');
    const sizeValue = $('#size-value');
    
    if (slider.length) slider.val(currentScale);
    if (sizeValue.length) sizeValue.text(currentScale + '%');
    applyScaleToUI(currentScale);
    
    // Populate themes if available
    if (Object.keys(themes).length > 0) {
        populateThemes();
    }
}

// Event Listeners
$(document).ready(function() {
    // Hide UI on load
    $('#scoreboard, #settingsMenu').hide();
    
    // Close button
    $('#closeBtn').on('click', function() {
        sendNuiMessage({ action: 'closeScoreboard' });
    });
    
    // Settings button
    $('#settingsBtn').on('click', function() {
        sendNuiMessage({ action: 'openSettings' });
    });
    
    // Close settings button
    $('#closeSettingsBtn').on('click', function() {
        sendNuiMessage({ action: 'closeSettings' });
    });
    
    // Size slider
    $('#size-slider').on('input', function() {
        const value = parseInt($(this).val()) || 100;
        $('#size-value').text(value + '%');
        currentScale = value;
        applyScaleToUI(value);
    });
    
    $('#size-slider').on('change', function() {
        updateScale(currentScale);
    });
    
    // Close on escape
    $(document).on('keydown', function(e) {
        if (e.key === 'Escape') {
            if ($('#settingsMenu').is(':visible')) {
                sendNuiMessage({ action: 'closeSettings' });
            } else if ($('#scoreboard').is(':visible')) {
                sendNuiMessage({ action: 'closeScoreboard' });
            }
        }
    });
    
    // Click outside to close settings
    $(document).on('click', function(e) {
        if ($('#settingsMenu').is(':visible') && !$(e.target).closest('.settings-container').length && !$(e.target).closest('#settingsBtn').length) {
            sendNuiMessage({ action: 'closeSettings' });
        }
    });
    
    // Load initial settings
    sendNuiMessage({ action: 'loadSettings' });
});