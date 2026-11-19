import math
from PIL import Image, ImageDraw, ImageFilter

def create_ak12():
    w, h = 600, 300
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # AK-12 Tactical Assault Rifle (facing right)
    # Colors
    c_gun_metal = (35, 38, 42, 255)
    c_gun_dark = (22, 24, 28, 255)
    c_gun_light = (58, 62, 68, 255)
    c_suppressor = (28, 30, 33, 255)
    c_mag = (45, 48, 52, 255)
    c_mag_window = (180, 160, 50, 180) # Brass rounds visible
    c_optic = (25, 27, 30, 255)
    c_glass = (40, 180, 200, 190)
    c_reticle = (255, 40, 40, 240)
    c_laser = (20, 22, 25, 255)
    c_grip = (30, 32, 35, 255)

    base_y = 150

    # Stock (left)
    d.polygon([(60, base_y - 12), (160, base_y - 15), (160, base_y + 15), (70, base_y + 35), (50, base_y + 40), (45, base_y - 5)], fill=c_gun_dark, outline=c_gun_light)
    # Stock buffer tube
    d.rectangle([110, base_y - 8, 190, base_y + 8], fill=c_gun_metal, outline=c_gun_light)
    # Buttpad ribs
    for ry in range(base_y - 5, base_y + 38, 6):
        d.line([(48, ry), (56, ry)], fill=(70, 75, 80, 255), width=2)

    # Receiver (middle)
    d.rectangle([190, base_y - 20, 360, base_y + 20], fill=c_gun_metal, outline=c_gun_light)
    # Ejection port & bolt
    d.rectangle([250, base_y - 15, 300, base_y - 2], fill=c_gun_dark, outline=(15, 16, 18, 255))
    d.rectangle([260, base_y - 11, 285, base_y - 4], fill=(70, 75, 82, 255)) # Silver bolt carrier
    # Selector switch
    d.line([(220, base_y - 5), (242, base_y + 5)], fill=(120, 125, 135, 255), width=3)
    # Fire indicator dots (red / white)
    d.ellipse([215, base_y - 8, 219, base_y - 4], fill=(220, 40, 40, 255))
    d.ellipse([225, base_y + 8, 229, base_y + 12], fill=(220, 220, 220, 255))

    # Pistol Grip
    d.polygon([(210, base_y + 20), (250, base_y + 20), (240, base_y + 75), (200, base_y + 70)], fill=c_grip, outline=c_gun_light)
    # Grip texturing
    for gy in range(base_y + 28, base_y + 68, 6):
        d.line([(208, gy), (236, gy + 3)], fill=(55, 60, 68, 255), width=2)
    # Trigger guard & trigger
    d.arc([235, base_y + 15, 275, base_y + 45], 0, 180, fill=c_gun_light, width=3)
    d.line([(255, base_y + 20), (252, base_y + 32)], fill=(180, 185, 195, 255), width=3)

    # Curved 30-round Magazine
    mag_pts = [(280, base_y + 18), (325, base_y + 18), (345, base_y + 90), (290, base_y + 95)]
    d.polygon(mag_pts, fill=c_mag, outline=c_gun_light)
    # Mag window showing brass ammo
    d.rectangle([305, base_y + 35, 318, base_y + 75], fill=c_mag_window, outline=(80, 75, 40, 255))
    for my in range(base_y + 40, base_y + 72, 6):
        d.line([(307, my), (316, my)], fill=(225, 200, 80, 255), width=3)

    # Handguard & Picatinny Rail
    d.rectangle([360, base_y - 18, 480, base_y + 16], fill=c_gun_dark, outline=c_gun_light)
    # M-LOK slots
    for sx in range(375, 465, 26):
        d.rectangle([sx, base_y - 4, sx + 18, base_y + 4], fill=(12, 14, 16, 255), outline=c_gun_light)
    # Top picatinny rail extending from receiver to front
    d.rectangle([210, base_y - 25, 480, base_y - 19], fill=c_gun_metal, outline=c_gun_light)
    for rx in range(215, 475, 8):
        d.line([(rx, base_y - 25), (rx, base_y - 20)], fill=c_gun_dark, width=2)

    # Angled Foregrip on bottom rail
    d.polygon([(400, base_y + 17), (445, base_y + 17), (435, base_y + 45), (410, base_y + 45)], fill=c_grip, outline=c_gun_light)

    # PEQ-15 Laser / Torch module on front top rail
    d.rectangle([430, base_y - 38, 475, base_y - 24], fill=c_laser, outline=c_gun_light)
    d.ellipse([468, base_y - 35, 476, base_y - 27], fill=(255, 30, 30, 255)) # Red laser aperture

    # Holographic Optic Sight (EOTech style)
    d.polygon([(260, base_y - 25), (330, base_y - 25), (325, base_y - 65), (275, base_y - 65)], fill=c_optic, outline=c_gun_light)
    # Optic hood & glass window
    d.rectangle([285, base_y - 60, 318, base_y - 35], fill=c_glass, outline=(30, 32, 36, 255))
    # Glowing Red Reticle inside
    d.ellipse([298, base_y - 50, 306, base_y - 42], outline=c_reticle, width=2)
    d.ellipse([301, base_y - 47, 303, base_y - 45], fill=c_reticle)

    # Barrel & Tactical Suppressor (front)
    d.rectangle([480, base_y - 6, 510, base_y + 4], fill=(50, 52, 58, 255), outline=c_gun_dark)
    # Heavy Suppressor
    d.rectangle([510, base_y - 14, 585, base_y + 12], fill=c_suppressor, outline=c_gun_light)
    # Suppressor fluting & muzzle crown
    for f in range(520, 575, 12):
        d.line([(f, base_y - 13), (f, base_y + 11)], fill=(18, 20, 22, 255), width=2)
    d.ellipse([580, base_y - 12, 586, base_y + 10], fill=(10, 10, 12, 255))

    return img

def create_rpg7v2():
    w, h = 600, 300
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Modernized RPG-7V2 with Tandem Warhead
    c_metal = (40, 44, 48, 255)
    c_dark = (25, 27, 30, 255)
    c_light = (65, 70, 78, 255)
    c_heatshield = (75, 60, 42, 255) # Modernized polymer/wood heat shield
    c_heatshield_dark = (50, 40, 28, 255)
    c_warhead_body = (60, 72, 52, 255) # Olive drab tandem warhead
    c_warhead_tip = (80, 92, 70, 255)
    c_precursor = (35, 38, 42, 255) # Forward tandem needle probe
    c_warning = (230, 190, 40, 255) # Warning yellow identification band
    c_optic = (30, 35, 38, 255)

    base_y = 150

    # Rear Venturi Funnel / Exhaust Nozzle (left)
    d.polygon([(40, base_y - 24), (100, base_y - 12), (100, base_y + 12), (40, base_y + 24)], fill=c_metal, outline=c_light)
    d.rectangle([100, base_y - 13, 160, base_y + 13], fill=c_dark, outline=c_light)

    # Central Tube with Thermal Heat Shields
    d.rectangle([160, base_y - 18, 320, base_y + 18], fill=c_heatshield, outline=c_light)
    # Shield bands & segments
    for bx in range(175, 315, 22):
        d.line([(bx, base_y - 17), (bx, base_y + 17)], fill=c_heatshield_dark, width=3)
    d.rectangle([160, base_y - 20, 166, base_y + 20], fill=c_metal)
    d.rectangle([314, base_y - 20, 320, base_y + 20], fill=c_metal)

    # Dual Pistol Grips
    # Front grip with trigger
    d.polygon([(270, base_y + 18), (295, base_y + 18), (285, base_y + 68), (262, base_y + 65)], fill=c_dark, outline=c_light)
    d.arc([282, base_y + 18, 308, base_y + 44], 0, 180, fill=c_light, width=2)
    d.line([(292, base_y + 22), (290, base_y + 32)], fill=(200, 205, 215, 255), width=2) # Trigger
    # Rear steadying grip
    d.polygon([(185, base_y + 18), (210, base_y + 18), (202, base_y + 62), (180, base_y + 60)], fill=c_dark, outline=c_light)

    # Optical Scope (PGO-7V with rubber sunshade)
    d.rectangle([230, base_y - 48, 290, base_y - 28], fill=c_optic, outline=c_light)
    d.polygon([(215, base_y - 52), (230, base_y - 48), (230, base_y - 28), (215, base_y - 24)], fill=(18, 20, 22, 255), outline=c_light) # Rubber eyecup
    d.rectangle([245, base_y - 28, 265, base_y - 18], fill=c_metal) # Mount bracket
    # Scope adjustment dials
    d.ellipse([272, base_y - 54, 282, base_y - 46], fill=(70, 75, 80, 255))
    # Front scope lens (cyan reflection)
    d.ellipse([285, base_y - 46, 292, base_y - 30], fill=(50, 180, 220, 200))

    # Forward Steel Launch Tube
    d.rectangle([320, base_y - 14, 400, base_y + 14], fill=c_metal, outline=c_light)
    # Iron sight leaf folded
    d.line([(385, base_y - 14), (385, base_y - 24)], fill=c_light, width=3)

    # PG-7VR Modern Tandem HEAT Warhead (protruding forward)
    # Main rocket motor stem
    d.rectangle([400, base_y - 10, 440, base_y + 10], fill=(50, 55, 60, 255), outline=c_light)
    # Large conical primary warhead
    d.polygon([(440, base_y - 12), (445, base_y - 32), (505, base_y - 28), (525, base_y - 10), (525, base_y + 10), (505, base_y + 28), (445, base_y + 32), (440, base_y + 12)], fill=c_warhead_body, outline=c_light)
    # Yellow tactical band
    d.rectangle([485, base_y - 29, 495, base_y + 29], fill=c_warning)
    # Precursor sub-warhead cone
    d.polygon([(525, base_y - 10), (560, base_y - 6), (560, base_y + 6), (525, base_y + 10)], fill=c_warhead_tip, outline=c_light)
    # Forward impact probe needle
    d.polygon([(560, base_y - 4), (590, base_y - 1), (590, base_y + 1), (560, base_y + 4)], fill=c_precursor)
    d.ellipse([587, base_y - 3, 592, base_y + 3], fill=(220, 60, 60, 255)) # Contact tip fuse

    return img

def create_drone_turret():
    w, h = 512, 300
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Under-fuselage Dual Micro-Gatling + Twin 70mm Missile Pods
    c_metal = (38, 42, 48, 255)
    c_dark = (20, 22, 26, 255)
    c_light = (65, 72, 82, 255)
    c_lens = (30, 200, 220, 230)
    c_pod = (48, 52, 58, 255)
    c_missile_tip = (230, 45, 45, 255)

    cy = 150
    cx = 256

    # Mounting pylon adapter
    d.polygon([(cx - 70, 30), (cx + 70, 30), (cx + 50, 80), (cx - 50, 80)], fill=c_metal, outline=c_light)

    # FLIR Camera Gimbal Sphere
    d.ellipse([cx - 45, cy - 45, cx + 45, cy + 45], fill=c_dark, outline=c_light, width=3)
    # High-tech Optical Sensor Lenses
    d.ellipse([cx - 25, cy - 25, cx + 5, cy + 5], fill=c_lens)
    d.ellipse([cx - 15, cy - 15, cx - 5, cy - 5], fill=(255, 255, 255, 220)) # Lens highlight
    d.ellipse([cx + 10, cy - 15, cx + 28, cy + 5], fill=(255, 120, 40, 220)) # Thermal IR sensor

    # Dual 7.62mm Micro-Gatling Autocannons (facing front/down)
    for gx in [cx - 28, cx + 18]:
        d.rectangle([gx, cy + 25, gx + 12, cy + 95], fill=c_dark, outline=c_light)
        # Rotary cooling sleeve & muzzle crowns
        for yb in range(cy + 35, cy + 90, 12):
            d.line([(gx - 2, yb), (gx + 14, yb)], fill=c_light, width=2)
        d.rectangle([gx - 1, cy + 95, gx + 13, cy + 108], fill=(15, 16, 18, 255), outline=c_light)

    # Flanking Twin 70mm Micro-Missile Pods (Left & Right)
    # Left Pod
    d.polygon([(40, cy - 35), (cx - 85, cy - 25), (cx - 85, cy + 45), (40, cy + 35)], fill=c_pod, outline=c_light)
    for ly in [cy - 18, cy + 12]:
        d.ellipse([cx - 96, ly - 8, cx - 80, ly + 8], fill=c_dark, outline=c_light)
        d.ellipse([cx - 92, ly - 5, cx - 84, ly + 5], fill=c_missile_tip)

    # Right Pod
    d.polygon([(cx + 85, cy - 25), (w - 40, cy - 35), (w - 40, cy + 35), (cx + 85, cy + 45)], fill=c_pod, outline=c_light)
    for ry in [cy - 18, cy + 12]:
        d.ellipse([cx + 80, ry - 8, cx + 96, ry + 8], fill=c_dark, outline=c_light)
        d.ellipse([cx + 84, ry - 5, cx + 92, ry + 5], fill=c_missile_tip)

    # Hazard markings & stencil text
    d.line([(cx - 70, 75), (cx + 70, 75)], fill=(240, 200, 30, 255), width=3)

    return img

def create_robot_chaingun():
    w, h = 512, 400
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Articulated Heavy Mech Weapon Arm: 30mm Autocannon + 4-cell Rocket Pod
    c_mech = (48, 54, 60, 255)
    c_dark = (24, 26, 30, 255)
    c_light = (78, 88, 98, 255)
    c_piston = (180, 190, 205, 255)
    c_ammo_belt = (200, 160, 45, 255)
    c_laser = (40, 230, 140, 255)

    base_y = 200

    # Shoulder / Arm Joint (left)
    d.ellipse([30, base_y - 65, 130, base_y + 65], fill=c_dark, outline=c_light, width=4)
    d.ellipse([55, base_y - 40, 105, base_y + 40], fill=c_mech, outline=c_light)
    # Hydraulic pistons
    d.line([(95, base_y - 30), (190, base_y - 45)], fill=c_piston, width=8)
    d.line([(95, base_y + 30), (190, base_y + 45)], fill=c_piston, width=8)

    # Weapon Housing & Receiver
    d.polygon([(150, base_y - 60), (320, base_y - 50), (320, base_y + 65), (150, base_y + 55)], fill=c_mech, outline=c_light)
    # Ammo feed chute with linked 30mm shells
    d.polygon([(130, base_y + 40), (220, base_y + 50), (210, base_y + 110), (120, base_y + 95)], fill=(30, 32, 36, 255), outline=c_light)
    for bx in range(135, 210, 12):
        d.rectangle([bx, base_y + 60, bx + 7, base_y + 90], fill=c_ammo_belt, outline=(100, 80, 20, 255))

    # Top 4-cell Micro-Rocket Pod
    d.rectangle([190, base_y - 110, 310, base_y - 55], fill=c_dark, outline=c_light)
    # 4 rocket tube apertures
    for rtx in [205, 230, 255, 280]:
        d.ellipse([rtx, base_y - 95, rtx + 18, base_y - 70], fill=(12, 12, 14, 255), outline=c_light)
        d.ellipse([rtx + 4, base_y - 90, rtx + 14, base_y - 75], fill=(230, 50, 50, 255))

    # Heavy 30mm Autocannon Barrel (extending right)
    d.rectangle([320, base_y - 20, 440, base_y + 20], fill=c_dark, outline=c_light)
    # Recoil buffer sleeves
    d.rectangle([330, base_y - 28, 380, base_y + 28], fill=c_mech, outline=c_light)
    # Long fluted barrel
    d.rectangle([440, base_y - 12, 485, base_y + 12], fill=(30, 33, 38, 255), outline=c_light)
    # Slotted Muzzle Brake
    d.rectangle([485, base_y - 22, 510, base_y + 22], fill=c_dark, outline=c_light)
    d.line([(492, base_y - 20), (492, base_y + 20)], fill=(12, 12, 14, 255), width=3)
    d.line([(502, base_y - 20), (502, base_y + 20)], fill=(12, 12, 14, 255), width=3)

    # Green tactical status HUD light
    d.rectangle([210, base_y - 40, 260, base_y - 30], fill=(15, 18, 20, 255))
    d.line([(215, base_y - 35), (255, base_y - 35)], fill=c_laser, width=3)

    return img

def create_boss_drone_commander_weapons():
    w, h = 600, 400
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # 360° AESA Phased Array Radar Dome + Quad Salvo Missile Pods
    cx, cy = 300, 200
    c_stealth = (32, 36, 42, 255)
    c_dark = (18, 20, 24, 255)
    c_light = (60, 70, 80, 255)
    c_aesa_glow = (40, 160, 255, 220)
    c_missile_tip = (240, 60, 40, 255)

    # Central AESA Stealth Radar Dome
    d.polygon([(cx - 100, cy - 70), (cx + 100, cy - 70), (cx + 130, cy + 20), (cx, cy + 80), (cx - 130, cy + 20)], fill=c_stealth, outline=c_light, width=3)
    # Glowing concentric AESA radar array
    for r in range(25, 80, 18):
        d.arc([cx - r, cy - 30 - r, cx + r, cy - 30 + r], 20, 160, fill=c_aesa_glow, width=3)

    # 4 Swarm Missile Salvo Pods (Top-Left, Top-Right, Bot-Left, Bot-Right)
    pod_locs = [(cx - 200, cy - 110), (cx + 100, cy - 110), (cx - 210, cy + 40), (cx + 110, cy + 40)]
    for px, py in pod_locs:
        d.rectangle([px, py, px + 100, py + 65], fill=c_dark, outline=c_light, width=2)
        # 4 launch cells in each pod (total 16 cruise missiles)
        for rx, ry in [(px + 15, py + 12), (px + 60, py + 12), (px + 15, py + 40), (px + 60, py + 40)]:
            d.ellipse([rx, ry, rx + 24, ry + 18], fill=(10, 10, 12, 255), outline=c_light)
            d.ellipse([rx + 6, ry + 4, rx + 18, ry + 14], fill=c_missile_tip)

    # Dual 20mm High-Velocity Rotary Cannons extending from base
    for gx in [cx - 60, cx + 45]:
        d.rectangle([gx, cy + 80, gx + 15, cy + 180], fill=c_dark, outline=c_light)
        for by in range(cy + 95, cy + 170, 15):
            d.line([(gx - 2, by), (gx + 17, by)], fill=c_light, width=2)
        d.ellipse([gx - 1, cy + 175, gx + 16, cy + 188], fill=(12, 14, 16, 255))

    return img

def create_boss_siege_railgun():
    w, h = 600, 400
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Dual 120mm Heavy Siege Railgun with Magnetic Accelerators
    c_armor = (42, 46, 52, 255)
    c_dark = (20, 22, 26, 255)
    c_light = (85, 95, 110, 255)
    c_plasma = (0, 220, 255, 230)
    c_rail = (60, 68, 78, 255)

    cy = 200

    # Massive Mount Mantle & Recoil Cylinders
    d.polygon([(50, cy - 90), (180, cy - 75), (180, cy + 75), (50, cy + 90)], fill=c_armor, outline=c_light, width=4)
    # Heavy Hydraulic Recoil Buffers
    d.rectangle([110, cy - 110, 240, cy - 80], fill=c_dark, outline=c_light)
    d.rectangle([110, cy + 80, 240, cy + 110], fill=c_dark, outline=c_light)

    # Parallel Magnetic Accelerator Rails (Upper & Lower)
    d.rectangle([180, cy - 55, 520, cy - 20], fill=c_rail, outline=c_light)
    d.rectangle([180, cy + 20, 520, cy + 55], fill=c_rail, outline=c_light)

    # Glowing Magnetic Acceleration Coils between rails
    for x in range(210, 500, 36):
        d.rectangle([x, cy - 62, x + 16, cy - 14], fill=c_plasma, outline=(255, 255, 255, 240))
        d.rectangle([x, cy + 14, x + 16, cy + 62], fill=c_plasma, outline=(255, 255, 255, 240))
        # Central energy arc
        d.line([(x + 8, cy - 20), (x + 8, cy + 20)], fill=(120, 245, 255, 180), width=3)

    # Heavy Muzzle Aperture Crown
    d.polygon([(520, cy - 65), (570, cy - 45), (570, cy + 45), (520, cy + 65)], fill=c_dark, outline=c_light, width=3)
    d.ellipse([555, cy - 25, 575, cy + 25], fill=(10, 12, 14, 255))
    d.ellipse([560, cy - 15, 570, cy + 15], fill=c_plasma)

    return img

def create_boss_apex_battery():
    w, h = 600, 450
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Final Assault Boss: Quad Gatling Battery + Dual Hyper-Velocity Siege Cannons
    cx, cy = 300, 225
    c_armor = (38, 42, 48, 255)
    c_dark = (16, 18, 22, 255)
    c_light = (80, 90, 105, 255)
    c_hyper_glow = (255, 90, 30, 240) # Plasma orange/red glow
    c_vls = (25, 28, 33, 255)

    # Central Armored Core Turret
    d.polygon([(cx - 140, cy - 100), (cx + 140, cy - 100), (cx + 180, cy + 80), (cx - 180, cy + 80)], fill=c_armor, outline=c_light, width=4)

    # Dual Hyper-Velocity Plasma Siege Cannons (Upper)
    for bx in [cx - 110, cx + 55]:
        d.rectangle([bx, cy - 180, bx + 55, cy - 90], fill=c_dark, outline=c_light, width=3)
        # Cooling ribs & plasma injector rings
        for ry in range(cy - 170, cy - 100, 20):
            d.line([(bx - 4, ry), (bx + 59, ry)], fill=c_hyper_glow, width=4)
        d.ellipse([bx + 8, cy - 188, bx + 47, cy - 172], fill=(10, 10, 12, 255), outline=c_hyper_glow)

    # 8-Cell VLS Missile Matrix on Turret Top
    for vx, vy in [(cx - 75, cy - 80), (cx - 45, cy - 80), (cx - 15, cy - 80), (cx + 15, cy - 80), (cx + 45, cy - 80)]:
        d.rectangle([vx, vy, vx + 22, vy + 30], fill=c_vls, outline=c_light)
        d.ellipse([vx + 4, vy + 6, vx + 18, vy + 24], fill=(240, 200, 30, 255))

    # Quad Heavy Rotary Gatling Pods (Lower Left & Lower Right)
    for px, py in [(cx - 220, cy + 40), (cx + 80, cy + 40)]:
        d.rectangle([px, py, px + 140, py + 120], fill=c_dark, outline=c_light, width=3)
        # 6 barrels per pod
        for bx in range(px + 20, px + 120, 22):
            d.rectangle([bx, py + 80, bx + 14, py + 160], fill=(28, 30, 35, 255), outline=c_light)
            d.ellipse([bx + 1, py + 155, bx + 13, py + 165], fill=(10, 10, 12, 255))

    # Hazard stripes on shield skirts
    d.polygon([(cx - 160, cy + 60), (cx - 120, cy + 60), (cx - 140, cy + 90), (cx - 180, cy + 90)], fill=(240, 200, 30, 255))
    d.polygon([(cx + 120, cy + 60), (cx + 160, cy + 60), (cx + 180, cy + 90), (cx + 140, cy + 90)], fill=(240, 200, 30, 255))

    return img

if __name__ == "__main__":
    ak12 = create_ak12()
    ak12.save("assets/textures/weapons/tex_wpn_enemy_ak12.png")
    print("Saved tex_wpn_enemy_ak12.png")

    rpg = create_rpg7v2()
    rpg.save("assets/textures/weapons/tex_wpn_enemy_rpg7v2.png")
    print("Saved tex_wpn_enemy_rpg7v2.png")

    drone_w = create_drone_turret()
    drone_w.save("assets/textures/weapons/tex_wpn_enemy_drone_turret.png")
    print("Saved tex_wpn_enemy_drone_turret.png")

    robot_w = create_robot_chaingun()
    robot_w.save("assets/textures/weapons/tex_wpn_enemy_robot_chaingun.png")
    print("Saved tex_wpn_enemy_robot_chaingun.png")

    boss1_w = create_boss_drone_commander_weapons()
    boss1_w.save("assets/textures/weapons/tex_wpn_boss_drone_commander.png")
    print("Saved tex_wpn_boss_drone_commander.png")

    boss2_w = create_boss_siege_railgun()
    boss2_w.save("assets/textures/weapons/tex_wpn_boss_siege_railgun.png")
    print("Saved tex_wpn_boss_siege_railgun.png")

    boss3_w = create_boss_apex_battery()
    boss3_w.save("assets/textures/weapons/tex_wpn_boss_apex_battery.png")
    print("Saved tex_wpn_boss_apex_battery.png")
    print("All Modern Warfare enemy weapon system textures generated successfully!")
