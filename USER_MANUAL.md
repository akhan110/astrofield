# AstroField — User Manual & Field Guide
> **Offline Astrophotography Field Companion & Ephemeris Engine**  
> *Target planning, sensor framing, polar alignment, and night scheduling without internet.*

---

## Table of Contents
1. [Overview & Philosophy](#1-overview--philosophy)
2. [Quick-Start Field Workflow](#2-quick-start-field-workflow)
3. [Framing Simulator](#3-framing-simulator)
4. [Polar Alignment Clock](#4-polar-alignment-clock)
5. [Session Scheduler](#5-session-scheduler)
6. [Point-to-Sky AR Compass](#6-point-to-sky-ar-compass)
7. [Night Mode & Field Optics Tools](#7-night-mode--field-optics-tools)
   - [Red Night Adaptation Screen & Flashlight](#red-night-adaptation-screen--flashlight)
   - [NPF Rule Exposure Calculator](#npf-rule-exposure-calculator)
   - [Dew Point Condensation Alert](#dew-point-condensation-alert)
   - [Intervalometer & Bulb Timer](#intervalometer--bulb-timer)
8. [Object Catalog & Sky Chart](#8-object-catalog--sky-chart)
9. [Equipment Profiles & Optics Management](#9-equipment-profiles--optics-management)
10. [Offline Readiness & Weather Sync](#10-offline-readiness--weather-sync)
11. [Settings & Customization](#11-settings--customization)
12. [FAQ & Troubleshooting](#12-faq--troubleshooting)

---

## 1. Overview & Philosophy
Astrophotographers travel to the most remote dark-sky locations on Earth — national parks, deserts, and high-altitude plateaus — where cellular connectivity is nonexistent.

**AstroField is designed to operate 100% offline.**
- **Zero Server Dependency:** All ephemeris calculations, twilight windows, celestial coordinates, and starter catalog targets run on your device's CPU.
- **Astronomy Engine Core:** High-precision celestial mechanics ported to Dart via GeoEngine, calculating positions with millisecond accuracy.
- **Dark Adaptation First:** Every UI screen adheres to an OLED `#050A16` midnight dark mode, with a hardware red night mode filter that protects your biological rhodopsin dark adaptation.

---

## 2. Quick-Start Field Workflow

### Step 1: Set Your Observing Site
Navigate to **Location & GPS** (`/location`):
- Tap **Use GPS to auto-fill** to acquire latitude, longitude, and elevation.
- Alternatively, manually enter your coordinates. AstroField caches your site permanently offline.

### Step 2: Set Up Your Optical Rig
Navigate to **Equipment** (`/equipment`):
- Enter your camera's sensor width (mm), sensor height (mm), and pixel pitch (µm).
- Enter your telescope or lens's effective focal length (mm), including any focal reducers or Barlow lenses.
- Save as your active profile.

### Step 3: Check Twilight & Moon Windows
Navigate to **Sun & Twilight** (`/sun-twilight`) and **Moon** (`/moon`):
- Review the **Astronomical Darkness** interval (Sun ≤ −18°).
- Check Moon rise/set times and illumination percentage to plan exposures around moonless hours.

### Step 4: Queue Targets & Begin Imaging
Navigate to **Object Catalog** (`/search`) or **Session Scheduler** (`/session-scheduler`):
- Select targets with high imaging scores (> 80).
- Check sensor framing with the **Framing Simulator**.
- Align your mount using the **Polar Alignment Clock**.

---

## 3. Framing Simulator
*Visual sensor FOV & target scale visualizer* (`/framing-simulator`)

The Framing Simulator renders your telescope/camera's exact field of view rectangle over real deep-sky astrophotography cutouts.

### Key Capabilities:
- **Real Photographic Cutouts:** Targets such as M42 (Orion Nebula), M31 (Andromeda Galaxy), and M45 (Pleiades) render at their true angular scale relative to your sensor.
- **Rotatable Sensor Rectangle:** Move the **Camera Angle Slider** (0° to 360°) to preview how rotating your camera rotator or T-ring will frame the object.
- **Rule of Thirds:** Cyan guidelines inside the sensor box help compose nebular clouds and companion galaxies.
- **Image Scale & Sampling:**
  $$\text{Resolution } (''/\text{px}) = \frac{206.265 \times \text{Pixel Pitch } (\mu\text{m})}{\text{Focal Length } (\text{mm})}$$
  - **Undersampled (> 2.0 "/px):** Pin-sharp stars, ideal for widefield mosaics.
  - **Optimal (0.67 – 2.0 "/px):** Well-balanced resolution matching typical atmospheric seeing.
  - **Oversampled (< 0.67 "/px):** Seeing-limited; consider binning pixels.
- **Mosaic Warnings:** When a target exceeds the sensor dimensions, AstroField recommends the required multi-panel mosaic count.

---

## 4. Polar Alignment Clock
*Polaris & Octans hour angle reticle* (`/polar-alignment`)

Equatorial tracking mounts require alignment with the True Celestial Pole, which is offset from Polaris by ~0.65°.

### Field Alignment Procedure:
1. Level your equatorial tripod.
2. In your mount’s polar scope, ensure the 12 o’clock position is oriented straight up.
3. Open the **Polar Alignment Clock** in AstroField.
4. Turn your mount's mechanical altitude and azimuth adjustment knobs until Polaris sits inside the reticle dial circle indicated by the app.
5. **Southern Hemisphere:** The app automatically switches to the **Sigma Octantis** reticle constellation pattern.

---

## 5. Session Scheduler
*Multi-target night timeline & queue* (`/session-scheduler`)

Maximize clear night hours by sequencing multiple targets:
- **Target Queue:** Set sub-exposure counts (e.g. 40 frames) and exposure durations (e.g. 180s) for each object.
- **Night Timeline:** Visualizes astronomical darkness, Moon illumination intervals, and target transit windows.
- **Meridian Crossing Alerts:** Highlights when targets cross your local celestial meridian, warning you when a German Equatorial Mount (GEM) needs a meridian flip.

---

## 6. Point-to-Sky AR Compass
*Live celestial compass & horizon target locator* (`/point-to-sky`)

Aim your telescope or binoculars accurately using your mobile device sensors:
- **Calibration:** Wave your device in a slow figure-8 pattern to eliminate magnetic interference from metal tripod legs.
- **Directional Guidance:** Select any catalog target to activate live elevation/azimuth arrows showing which way to point.
- **Target Lock:** When your phone is aimed directly at the object, the reticle illuminates green with haptic confirmation.

---

## 7. Night Mode & Field Optics Tools
*Dark adaptation, red screen, and calculations* (`/red-light-tools`)

### Red Night Adaptation Screen & Flashlight
- White light resets eye rhodopsin molecules (requiring up to 30 minutes to recover).
- The red screen filter and flashlight output only dark-adapted long wavelengths (> 620 nm).

### NPF Rule Exposure Calculator
Avoid trailing stars in untracked landscape and Milky Way astrophotography:
$$t_{\text{max}} = \frac{16.9 \times N + 0.1 \times f + 13.7 \times p}{f \times \cos(\delta)}$$
Where $N$ is f-number, $f$ is focal length (mm), $p$ is pixel pitch ($\mu$m), and $\delta$ is declination.

### Dew Point Condensation Alert
- Calculates dew temperature based on ambient temperature and relative humidity.
- Warns you when lens surfaces are within 2.5°C of dew point so you can activate dew heater bands.

### Intervalometer & Bulb Timer
- Custom countdown timer with haptic and audio pings for manual bulb exposures.

---

## 8. Object Catalog & Sky Chart
*207 curated deep-sky and solar system targets* (`/search`)

- **Full Messier Catalog:** All 110 Messier objects (M1 through M110).
- **Bright NGC/IC Targets:** North America Nebula, Veil Nebula, Rosette, Thor's Helmet, Andromeda satellites, etc.
- **Solar System:** Moon, Mercury, Venus, Mars, Jupiter, and Saturn.
- **Horizon Sky Radar:** 360° all-sky chart showing Zenith at center and local horizon at edge.
- **Imaging Score (0–100):** Heuristic combining peak altitude, Moon separation, and darkness hours.

---

## 9. Equipment Profiles & Optics Management
*Custom sensor & telescope rig definitions* (`/equipment`)

Save multiple rigs:
- Widefield DSLR/Mirrorless + 135mm lens
- Dedicated Cooled Astrophotography Camera + 80mm Triplet APO
- Schmidt-Cassegrain / EdgeHD planetary setup
Calculates horizontal FOV, vertical FOV, and arcsec/px scale automatically.

---

## 10. Offline Readiness & Weather Sync
*Offline verification and caching* (`/trip-pack` & `/sync`)

- **Weather Cache:** Before traveling, download hourly forecasts (cloud coverage, seeing, wind, humidity) from Open-Meteo.
- **Airplane Mode Check:** Reopen AstroField in airplane mode before departure to verify all data is safely cached.

---

## 11. Settings & Customization
*Thresholds & preferences* (`/settings`)

- **Minimum Altitude Threshold:** Default 30° (configurable 5° to 80°). Prevents targets low in atmospheric haze from skewing your score.
- **Red Night Mode System Toggle:** Global monochromatic red UI matrix.
- **Units:** Metric millimeters, micrometers, and degrees.

---

## 12. FAQ & Troubleshooting

**Q: Why does the compass direction drift near my telescope?**  
*A: Heavy counterweights and steel tripod legs produce magnetic distortion. Step 2 meters away from metal equipment when calibrating your compass.*

**Q: Do I need an internet connection to plan tonight's session?**  
*A: No. All positions, twilight windows, and catalog calculations run entirely offline on your phone's processor.*

**Q: How do I backup or transfer my equipment profiles?**  
*A: Profiles are stored locally in your device's persistent app database and remain preserved across app updates.*

---
*© 2026 AstroField • Offline Astrophotography Field Engine*
