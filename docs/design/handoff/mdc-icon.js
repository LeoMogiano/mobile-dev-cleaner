// <mdc-icon name="hammer" size="16" w="1.7"> — SF Symbols–style line icons (currentColor).
(() => {
  const F = 'fill="currentColor" stroke="none"';
  const P = {
    overview: '<rect x="3" y="3" width="7.5" height="9" rx="1.5"/><rect x="13.5" y="3" width="7.5" height="5.5" rx="1.5"/><rect x="13.5" y="11.5" width="7.5" height="9.5" rx="1.5"/><rect x="3" y="15" width="7.5" height="6" rx="1.5"/>',
    hammer: '<path d="M15 5l4 4-3 3-4-4z"/><path d="M12 8L4 16v4h4l8-8"/>',
    tray: '<path d="M3 13h6l2 2h2l2-2h6"/><path d="M3 13v6a2 2 0 002 2h14a2 2 0 002-2v-6l-4-8a2 2 0 00-2-1H9a2 2 0 00-2 1z"/>',
    checklist: '<path d="M4 6l1.5 1.5L8 5M4 12l1.5 1.5L8 11M4 18l1.5 1.5L8 17M11 6h9M11 12h9M11 18h9"/>',
    iphone: '<rect x="6.5" y="2.5" width="11" height="19" rx="2.5"/><path d="M10.5 5h3"/>',
    ipad: '<rect x="4" y="3" width="16" height="18" rx="2.5"/><path d="M11 18.2h2"/>',
    watch: '<rect x="6.5" y="6" width="11" height="12" rx="3"/><path d="M9 6l.6-3h4.8L15 6M9 18l.6 3h4.8l.6-3"/>',
    phone: '<rect x="6.5" y="2.5" width="11" height="19" rx="2"/><path d="M6.5 18h11M11 19.8h2"/>',
    devlink: '<rect x="7" y="2.5" width="10" height="15" rx="2"/><path d="M12 17.5V22M9.5 22h5"/>',
    cube: '<path d="M12 2L3 7v10l9 5 9-5V7z"/><path d="M3 7l9 5 9-5M12 12v10"/>',
    archive: '<rect x="3" y="4" width="18" height="4" rx="1"/><path d="M5 8v11a2 2 0 002 2h10a2 2 0 002-2V8M10 12h4"/>',
    eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
    box: '<path d="M3 7.5L12 3l9 4.5v9L12 21l-9-4.5z"/><path d="M3 7.5L12 12l9-4.5M12 12v9M7.5 5.2l9 4.6"/>',
    stack: '<path d="M12 3l9 4.5-9 4.5-9-4.5z"/><path d="M3 12l9 4.5 9-4.5M3 16.5L12 21l9-4.5"/>',
    layers: '<rect x="4" y="8" width="12" height="12" rx="2"/><path d="M8 8V6a2 2 0 012-2h8a2 2 0 012 2v8a2 2 0 01-2 2h-2"/>',
    doc: '<path d="M6 2.5h8l4 4V21a.5.5 0 01-.5.5h-11A.5.5 0 016 21z"/><path d="M14 2.5v4h4M9 12h6M9 16h6"/>',
    wrench: '<path d="M14.7 6.3a4 4 0 00-5.4 5.1L3.5 17.2a1.8 1.8 0 002.5 2.5l5.8-5.8a4 4 0 005.1-5.4l-2.6 2.6-2.2-.4-.4-2.2z"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    android: '<path d="M7 14v-4a5 5 0 0110 0v4z"/><path d="M7 14h10v3a2 2 0 01-2 2H9a2 2 0 01-2-2z"/><path d="M5 11v4M19 11v4M9 7l-1-2M15 7l1-2"/>',
    regen: '<path d="M20 11a8 8 0 00-14.3-4.3L4 8.5"/><path d="M4 4v4.5h4.5"/><path d="M4 13a8 8 0 0014.3 4.3l1.7-1.8"/><path d="M20 20v-4.5h-4.5"/>',
    cost: '<path d="M3.5 12a8.5 8.5 0 102.5-6"/><path d="M3 4v4h4"/><path d="M12 8v4.5l3 1.8"/>',
    history: '<path d="M3.5 12a8.5 8.5 0 108.5-8.5 8.6 8.6 0 00-6.3 2.8L3.5 8.5"/><path d="M3.5 4v4.5H8"/><path d="M12 8v4l3 2"/>',
    lock: '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7.5a4 4 0 018 0V11"/>',
    warn: '<path d="M12 3.5L2.5 20h19z"/><path d="M12 10v4.5M12 17.3v.2"/>',
    gear: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 00.3 1.8l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.8-.3 1.7 1.7 0 00-1 1.5V21a2 2 0 01-4 0v-.1a1.7 1.7 0 00-1-1.5 1.7 1.7 0 00-1.8.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.7 1.7 0 00.3-1.8 1.7 1.7 0 00-1.5-1H3a2 2 0 010-4h.1a1.7 1.7 0 001.5-1 1.7 1.7 0 00-.3-1.8l-.1-.1a2 2 0 112.8-2.8l.1.1a1.7 1.7 0 001.8.3H9a1.7 1.7 0 001-1.5V3a2 2 0 014 0v.1a1.7 1.7 0 001 1.5 1.7 1.7 0 001.8-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.7 1.7 0 00-.3 1.8V9a1.7 1.7 0 001.5 1H21a2 2 0 010 4h-.1a1.7 1.7 0 00-1.5 1z"/>',
    person: '<circle cx="12" cy="12" r="9.5"/><circle cx="12" cy="10" r="3.2"/><path d="M5.8 18.7c1.3-2.3 3.5-3.4 6.2-3.4s4.9 1.1 6.2 3.4"/>',
    search: '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.5-4.5"/>',
    chevr: '<path d="M9 6l6 6-6 6"/>',
    chevd: '<path d="M6 9l6 6 6-6"/>',
    check: '<path d="M20 6L9 17l-5-5"/>',
    x: '<path d="M18 6L6 18M6 6l12 12"/>',
    finder: '<circle cx="12" cy="12" r="9"/><path d="M9.5 14.5l5-5M10 9.5h4.5V14"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    minus: '<path d="M5 12h14"/>',
    info: '<circle cx="12" cy="12" r="9"/><path d="M12 8v.01M11 12h1v5h1"/>',
    coffee: '<path d="M4 9h13v6a4 4 0 01-4 4H8a4 4 0 01-4-4z"/><path d="M17 11h1.5a2.5 2.5 0 010 5H17"/><path d="M7 5s1-1 0-2M11 5s1-1 0-2M15 5s1-1 0-2"/>',
    disk: '<rect x="2.5" y="13" width="19" height="7" rx="2"/><path d="M4 13l2.5-8h11L20 13"/><path d="M16.5 16.5h1"/>',
    shield: '<path d="M12 3l7.5 3v5.5c0 4.5-3.2 8.2-7.5 9.5-4.3-1.3-7.5-5-7.5-9.5V6z"/><path d="M9 12l2 2 4-4"/>',
    bell: '<path d="M6 16v-5a6 6 0 0112 0v5l1.5 2h-15z"/><path d="M10 20.5a2 2 0 004 0"/>',
    sliders: '<path d="M4 7h10M18 7h2M4 17h4M12 17h8"/><circle cx="16" cy="7" r="2"/><circle cx="10" cy="17" r="2"/>',
    trash: '<path d="M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2M6 6l1 14a2 2 0 002 2h6a2 2 0 002-2l1-14"/>',
    refresh: '<path d="M3 12a9 9 0 0115.5-6.3L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 01-15.5 6.3L3 16"/><path d="M3 21v-5h5"/>',
    copy: '<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V6a2 2 0 00-2-2H6a2 2 0 00-2 2v8a2 2 0 002 2h2"/>',
    export: '<path d="M12 15V3M8 7l4-4 4 4"/><path d="M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7"/>',
    import: '<path d="M12 3v12M8 11l4 4 4-4"/><path d="M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7"/>',
    scan: '<path d="M4 8V5a1 1 0 011-1h3M16 4h3a1 1 0 011 1v3M20 16v3a1 1 0 01-1 1h-3M8 20H5a1 1 0 01-1-1v-3"/><circle cx="12" cy="12" r="3.5"/>',
    monitor: '<rect x="2.5" y="4" width="19" height="13" rx="2"/><path d="M9 21h6M12 17v4"/>',
    globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.5 2.5 3.8 5.5 3.8 9s-1.3 6.5-3.8 9c-2.5-2.5-3.8-5.5-3.8-9S9.5 5.5 12 3z"/>',
    terminal: '<rect x="2.5" y="4" width="19" height="16" rx="2"/><path d="M7 9l3 3-3 3M12.5 15H17"/>',
    key: '<circle cx="8" cy="15" r="4.5"/><path d="M11.2 11.8L20 3M16.5 6.5l2.5 2.5M14 9l2 2"/>',
    cert: '<rect x="3" y="4" width="18" height="13" rx="2"/><path d="M7 9h10M7 12.5h5"/><circle cx="16.5" cy="17.5" r="2.5"/>',
    filter: '<path d="M4 5h16l-6 8v5l-4 2v-7z"/>',
    github: '<path ' + F + ' d="M12 .5C5.65.5.5 5.65.5 12c0 5.08 3.29 9.39 7.86 10.91.57.1.78-.25.78-.55v-2.02c-3.2.7-3.87-1.37-3.87-1.37-.52-1.33-1.28-1.69-1.28-1.69-1.04-.71.08-.7.08-.7 1.16.08 1.77 1.19 1.77 1.19 1.03 1.76 2.7 1.25 3.36.96.1-.74.4-1.26.73-1.55-2.55-.29-5.23-1.28-5.23-5.69 0-1.26.45-2.29 1.19-3.1-.12-.29-.51-1.47.11-3.06 0 0 .97-.31 3.18 1.18.92-.26 1.91-.39 2.89-.39s1.97.13 2.89.39c2.21-1.49 3.18-1.18 3.18-1.18.62 1.59.23 2.77.11 3.06.74.81 1.19 1.84 1.19 3.1 0 4.42-2.69 5.4-5.25 5.68.41.35.78 1.05.78 2.12v3.14c0 .3.21.66.79.55C20.22 21.38 23.5 17.07 23.5 12c0-6.35-5.15-11.5-11.5-11.5z"/>',
    linkedin: '<path ' + F + ' d="M20.45 20.45h-3.55v-5.57c0-1.33-.02-3.04-1.85-3.04-1.85 0-2.14 1.45-2.14 2.94v5.67H9.35V9h3.41v1.56h.05c.48-.9 1.64-1.85 3.37-1.85 3.6 0 4.27 2.37 4.27 5.46v6.28zM5.34 7.43a2.06 2.06 0 11-.01-4.12 2.06 2.06 0 01.01 4.12zM7.12 20.45H3.56V9h3.56v11.45zM22.22 0H1.77C.79 0 0 .77 0 1.72v20.56C0 23.23.79 24 1.77 24h20.45c.98 0 1.78-.77 1.78-1.72V1.72C24 .77 23.2 0 22.22 0z"/>',
    star: '<path d="M12 3.2l2.7 5.6 6.1.8-4.5 4.2 1.1 6.1L12 17l-5.4 2.9 1.1-6.1L3.2 9.6l6.1-.8z"/>',
    sparkle: '<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/><path d="M19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8z"/>',
    plug: '<path d="M9 3v5M15 3v5M6.5 8h11v3.5a5.5 5.5 0 01-11 0z"/><path d="M12 17v4"/>',
    dot: '<circle cx="12" cy="12" r="4"/>',
  };
  class MdcIcon extends HTMLElement {
    static get observedAttributes() { return ['name', 'size', 'w']; }
    connectedCallback() { this.render(); }
    attributeChangedCallback() { this.render(); }
    render() {
      const s = this.getAttribute('size') || 16, w = this.getAttribute('w') || 1.35;
      const n = this.getAttribute('name');
      this.style.display = 'inline-flex'; this.style.flexShrink = '0'; this.style.lineHeight = '0';
      if (!this._root) this._root = this.attachShadow({ mode: 'open' });
      this._root.innerHTML = `<svg style="display:block" width="${s}" height="${s}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${P[n] || P.dot}</svg>`;
    }
  }
  if (!customElements.get('mdc-icon')) customElements.define('mdc-icon', MdcIcon);
})();
