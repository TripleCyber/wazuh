<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080" preserveAspectRatio="xMidYMid slice">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#101010"/>
      <stop offset="1" stop-color="${TSOC_DARK}"/>
    </linearGradient>
    <pattern id="grid" width="64" height="64" patternUnits="userSpaceOnUse">
      <path d="M64 0H0V64" fill="none" stroke="#FFFFFF" stroke-opacity=".045" stroke-width="1"/>
    </pattern>
    <radialGradient id="glowGreen" cx=".82" cy=".12" r=".55">
      <stop offset="0" stop-color="${TSOC_GREEN}" stop-opacity=".20"/>
      <stop offset="1" stop-color="${TSOC_GREEN}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="glowRed" cx=".08" cy=".95" r=".45">
      <stop offset="0" stop-color="${TSOC_RED}" stop-opacity=".14"/>
      <stop offset="1" stop-color="${TSOC_RED}" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <rect width="1920" height="1080" fill="url(#grid)"/>
  <rect width="1920" height="1080" fill="url(#glowGreen)"/>
  <rect width="1920" height="1080" fill="url(#glowRed)"/>
</svg>
