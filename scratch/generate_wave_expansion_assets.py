#!/usr/bin/env python3
"""
LAST TRENCH - Wave Expansion Visual Asset Generator
Generates high-resolution textures for new enemy types and 3 bosses:
1. RPG Infantry (tex_enemy_rpg_soldier.png)
2. Combat Robot (tex_enemy_combat_robot.png)
3. Boss 1: Drone Swarm Commander (tex_boss_drone_commander.png)
4. Boss 2: Armored Robot Titan (tex_boss_armored_robot.png)
5. Boss 3: Final Assault Dreadnought (tex_boss_final_assault.png)
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = "assets/textures"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def clamp(v, min_v=0, max_v=255):
    return max(min_v, min(max_v, int(v)))

# ---------------------------------------------------------------------------
# 1. RPG Infantry (512x1024 RGBA)
# ---------------------------------------------------------------------------
def generate_rpg_soldier():
    w, h = 512, 1024
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Body center: x = 256, feet at y = 920, head at y = 220
    # Legs
    draw.polygon([(200, 580), (240, 580), (225, 900), (185, 900)], fill=(45, 52, 40, 255))
    draw.polygon([(272, 580), (312, 580), (327, 900), (287, 900)], fill=(45, 52, 40, 255))
    # Boots
    draw.polygon([(175, 880), (230, 880), (225, 930), (160, 930)], fill=(25, 25, 22, 255))
    draw.polygon([(282, 880), (337, 880), (352, 930), (287, 930)], fill=(25, 25, 22, 255))
    
    # Torso (Heavy tactical vest with olive drab / woodland camo)
    draw.polygon([(185, 340), (327, 340), (345, 590), (167, 590)], fill=(62, 70, 52, 255))
    # Plate carrier
    draw.rounded_rectangle([(195, 370), (317, 560)], radius=12, fill=(40, 48, 35, 255), outline=(30, 36, 26, 255), width=3)
    # Ammo pouches
    for px in [205, 245, 285]:
        draw.rectangle([(px, 480), (px + 28, 545)], fill=(50, 58, 42, 255), outline=(20, 25, 18, 255), width=2)
    
    # Shoulder RPG-7 Tube on right shoulder (angled diagonally forward-up)
    # Tube body (metallic dark olive & steel)
    draw.polygon([(300, 580), (325, 560), (385, 200), (360, 220)], fill=(55, 62, 45, 255))
    draw.line([(312, 570), (372, 210)], fill=(90, 100, 75, 255), width=4)
    # Heat shield / wooden grip section
    draw.polygon([(320, 500), (340, 485), (355, 400), (335, 415)], fill=(110, 65, 35, 255))
    # Optical sight PGO-7
    draw.rectangle([(325, 360), (345, 395)], fill=(25, 30, 25, 255), outline=(0, 230, 180, 255), width=2)
    # Warhead (PG-7V ogive conical warhead at top)
    draw.polygon([(360, 220), (385, 200), (410, 140), (385, 125), (345, 180)], fill=(85, 95, 70, 255))
    draw.polygon([(410, 140), (385, 125), (415, 80), (425, 85)], fill=(160, 175, 140, 255)) # Nose fuse
    # Warhead fins / collar
    draw.line([(355, 200), (395, 215)], fill=(30, 35, 25, 255), width=5)
    
    # Left & Right Arms
    draw.polygon([(185, 350), (140, 450), (180, 520), (220, 480)], fill=(55, 62, 48, 255)) # Left arm
    draw.polygon([(325, 350), (350, 430), (330, 490), (305, 460)], fill=(55, 62, 48, 255)) # Right arm supporting RPG
    # Tactical gloves
    draw.ellipse([(170, 495), (205, 530)], fill=(30, 32, 28, 255))
    draw.ellipse([(315, 430), (345, 465)], fill=(30, 32, 28, 255))
    
    # Head & Helmet
    draw.ellipse([(215, 200), (297, 300)], fill=(70, 78, 62, 255)) # Ballistic helmet
    draw.rectangle([(220, 260), (292, 310)], fill=(185, 145, 120, 255)) # Face/balaclava
    draw.rectangle([(228, 275), (284, 292)], fill=(25, 25, 25, 255)) # Ballistic goggles
    draw.line([(232, 283), (280, 283)], fill=(0, 220, 255, 200), width=3) # Goggle sheen
    # Helmet NVG mount
    draw.rectangle([(248, 220), (264, 245)], fill=(35, 40, 32, 255), outline=(15, 18, 14, 255), width=2)
    
    path = os.path.join(OUTPUT_DIR, "tex_enemy_rpg_soldier.png")
    img.save(path, "PNG")
    print(f"[OK] Generated: {path}")

# ---------------------------------------------------------------------------
# 2. Combat Robot (512x512 RGBA)
# ---------------------------------------------------------------------------
def generate_combat_robot():
    w, h = 512, 512
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Heavy armored bipedal/quadruped combat walker
    # Hydraulic Legs
    for lx, rx in [(140, 90), (372, 422)]:
        # Upper thigh
        draw.polygon([(lx, 290), (lx + 45, 290), (rx + 35, 430), (rx, 430)], fill=(45, 48, 55, 255))
        # Hydraulic piston
        draw.line([(lx + 22, 310), (rx + 18, 410)], fill=(180, 190, 205, 255), width=6)
        # Lower leg shin
        draw.polygon([(rx, 420), (rx + 40, 420), (rx + 25, 495), (rx - 15, 495)], fill=(35, 38, 42, 255))
        # Foot pad
        draw.rounded_rectangle([(rx - 30, 485), (rx + 45, 508)], radius=6, fill=(20, 22, 25, 255), outline=(80, 85, 95, 255), width=2)
    
    # Armored Torso Chassis (Gunmetal angular armor)
    draw.polygon([
        (160, 200), (352, 200), (390, 290), (370, 360), (142, 360), (122, 290)
    ], fill=(52, 58, 68, 255), outline=(85, 95, 110, 255))
    # Reinforced chest plates
    draw.polygon([(185, 215), (327, 215), (345, 280), (167, 280)], fill=(38, 42, 50, 255))
    
    # Glowing Cyclops Sensor Visor (Menacing red LED strip)
    draw.rounded_rectangle([(200, 235), (312, 258)], radius=4, fill=(30, 5, 8, 255), outline=(255, 30, 30, 255), width=2)
    draw.rectangle([(220, 242), (292, 251)], fill=(255, 50, 50, 255))
    # Glow dot
    draw.ellipse([(250, 241), (262, 252)], fill=(255, 220, 220, 255))
    
    # Dual Auto-Cannons (Mounted on left & right hardpoints)
    for gx in [85, 390]:
        # Cannon mount
        draw.rounded_rectangle([(gx, 230), (gx + 36, 290)], radius=5, fill=(35, 38, 44, 255))
        # Twin heavy barrels
        draw.rectangle([(gx + 5, 150), (gx + 15, 240)], fill=(20, 22, 26, 255), outline=(90, 95, 105, 255), width=2)
        draw.rectangle([(gx + 20, 150), (gx + 30, 240)], fill=(20, 22, 26, 255), outline=(90, 95, 105, 255), width=2)
        # Muzzle brakes
        draw.rectangle([(gx + 3, 142), (gx + 17, 155)], fill=(15, 15, 18, 255))
        draw.rectangle([(gx + 18, 142), (gx + 32, 155)], fill=(15, 15, 18, 255))
    
    # Exhaust / Heat Vents on top
    for vx in [205, 235, 265, 295]:
        draw.rectangle([(vx, 188), (vx + 15, 202)], fill=(25, 28, 32, 255))
        draw.line([(vx + 2, 195), (vx + 13, 195)], fill=(255, 120, 20, 200), width=2)
        
    path = os.path.join(OUTPUT_DIR, "tex_enemy_combat_robot.png")
    img.save(path, "PNG")
    print(f"[OK] Generated: {path}")

# ---------------------------------------------------------------------------
# 3. Boss 1: Drone Swarm Commander (512x512 RGBA)
# ---------------------------------------------------------------------------
def generate_boss_drone_commander():
    w, h = 512, 512
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Hexacopter Heavy Command Chassis
    # 6 Outrigger Boom Arms
    center = (256, 256)
    angles = [0, 60, 120, 180, 240, 300]
    for deg in angles:
        rad = math.radians(deg)
        x2 = int(256 + 185 * math.cos(rad))
        y2 = int(256 + 185 * math.sin(rad))
        draw.line([center, (x2, y2)], fill=(45, 50, 60, 255), width=14)
        draw.line([center, (x2, y2)], fill=(80, 90, 105, 255), width=6)
        
        # Heavy Rotor Engine Pod
        draw.ellipse([(x2 - 38, y2 - 38), (x2 + 38, y2 + 38)], fill=(32, 35, 42, 255), outline=(220, 50, 40, 255), width=3)
        # Rotor Blades (Motion blurred spin ring)
        draw.arc([(x2 - 55, y2 - 55), (x2 + 55, y2 + 55)], 0, 360, fill=(255, 80, 30, 220), width=4)
        draw.ellipse([(x2 - 12, y2 - 12), (x2 + 12, y2 + 12)], fill=(255, 140, 0, 255))
        
    # Central Command Citadel Hull (Heavy hexagonal fortress body)
    hex_pts = []
    for deg in [30, 90, 150, 210, 270, 330]:
        rad = math.radians(deg)
        hex_pts.append((int(256 + 115 * math.cos(rad)), int(256 + 115 * math.sin(rad))))
    draw.polygon(hex_pts, fill=(38, 42, 52, 255), outline=(100, 115, 135, 255))
    
    # Inner Armor Core
    inner_hex = []
    for deg in [30, 90, 150, 210, 270, 330]:
        rad = math.radians(deg)
        inner_hex.append((int(256 + 75 * math.cos(rad)), int(256 + 75 * math.sin(rad))))
    draw.polygon(inner_hex, fill=(24, 26, 32, 255), outline=(255, 60, 40, 255))
    
    # Glowing Red Swarm Command Eye (Pulsing holographic central sensor)
    draw.ellipse([(205, 205), (307, 307)], fill=(60, 10, 15, 255), outline=(255, 40, 40, 255), width=4)
    draw.ellipse([(225, 225), (287, 287)], fill=(255, 30, 30, 255))
    draw.ellipse([(242, 242), (270, 270)], fill=(255, 230, 200, 255))
    
    # Dual Guided Rocket Pods under hull
    for px in [145, 335]:
        draw.rounded_rectangle([(px, 215), (px + 32, 295)], radius=6, fill=(28, 30, 36, 255), outline=(75, 85, 100, 255), width=2)
        for my in [225, 245, 265, 285]:
            draw.ellipse([(px + 6, my), (px + 14, my + 8)], fill=(255, 60, 20, 255))
            draw.ellipse([(px + 18, my), (px + 26, my + 8)], fill=(255, 60, 20, 255))
            
    path = os.path.join(OUTPUT_DIR, "tex_boss_drone_commander.png")
    img.save(path, "PNG")
    print(f"[OK] Generated: {path}")

# ---------------------------------------------------------------------------
# 4. Boss 2: Armored Robot Titan (512x512 RGBA)
# ---------------------------------------------------------------------------
def generate_boss_armored_robot():
    w, h = 512, 512
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Massive Armored Walker Titan Chassis
    # Heavy Tread/Foot Assemblies
    for tx in [75, 345]:
        # Huge tread / foot pods
        draw.polygon([(tx, 410), (tx + 92, 410), (tx + 105, 498), (tx - 15, 498)], fill=(32, 34, 38, 255), outline=(70, 75, 85, 255), width=3)
        # Tread sprockets & armor skirts
        draw.rounded_rectangle([(tx - 18, 470), (tx + 108, 506)], radius=6, fill=(22, 24, 26, 255))
        for sx in range(tx - 10, tx + 100, 18):
            draw.line([(sx, 480), (sx + 8, 498)], fill=(120, 130, 145, 255), width=3)
        # Massive Hydraulic Struts
        draw.line([(tx + 46, 300), (tx + 46, 415)], fill=(160, 170, 185, 255), width=18)
        draw.line([(tx + 46, 300), (tx + 46, 415)], fill=(60, 65, 75, 255), width=8)
    
    # Heavy Angular Titan Torso
    draw.polygon([
        (130, 140), (382, 140), (430, 260), (405, 360), (107, 360), (82, 260)
    ], fill=(44, 48, 56, 255), outline=(100, 110, 125, 255), width=4)
    
    # Reactive Armor Bricks (ERA tiles)
    for row in range(3):
        ry = 180 + row * 40
        for col in range(6):
            cx = 145 + col * 38
            draw.rectangle([(cx, ry), (cx + 32, ry + 32)], fill=(34, 38, 44, 255), outline=(65, 72, 82, 255), width=2)
            # Bolt rivets
            draw.ellipse([(cx + 4, ry + 4), (cx + 8, ry + 8)], fill=(150, 160, 175, 255))
            draw.ellipse([(cx + 24, ry + 24), (cx + 28, ry + 28)], fill=(150, 160, 175, 255))
            
    # Twin Heavy Railguns / Siege Cannons (Mounted on Shoulders)
    for bx in [45, 420]:
        draw.rectangle([(bx, 60), (bx + 48, 230)], fill=(28, 30, 36, 255), outline=(85, 95, 110, 255), width=3)
        # Heavy Muzzle
        draw.rectangle([(bx - 4, 45), (bx + 52, 75)], fill=(18, 20, 24, 255), outline=(255, 160, 40, 255), width=2)
        # Thermal Energy Rails
        draw.line([(bx + 16, 75), (bx + 16, 220)], fill=(0, 220, 255, 255), width=3)
        draw.line([(bx + 32, 75), (bx + 32, 220)], fill=(0, 220, 255, 255), width=3)
        
    # Armored Head / Sensor Conning Tower
    draw.polygon([(205, 95), (307, 95), (325, 145), (187, 145)], fill=(26, 28, 34, 255), outline=(110, 120, 135, 255), width=2)
    # Target Acquisition Visor (Glowing Amber/Red)
    draw.rounded_rectangle([(220, 115), (292, 133)], radius=4, fill=(20, 5, 5, 255), outline=(255, 80, 20, 255), width=2)
    draw.line([(225, 124), (287, 124)], fill=(255, 120, 30, 255), width=4)
    draw.ellipse([(252, 120), (260, 128)], fill=(255, 240, 200, 255))
    
    path = os.path.join(OUTPUT_DIR, "tex_boss_armored_robot.png")
    img.save(path, "PNG")
    print(f"[OK] Generated: {path}")

# ---------------------------------------------------------------------------
# 5. Boss 3: Final Assault Dreadnought (512x512 RGBA)
# ---------------------------------------------------------------------------
def generate_boss_final_assault():
    w, h = 512, 512
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Apex Assault Dreadnought (Massive Combined Land-Air Warmachine)
    # Heavy Composite Shield Wings
    draw.polygon([(256, 120), (480, 240), (460, 430), (370, 450), (256, 380)], fill=(28, 32, 40, 255), outline=(130, 145, 165, 255), width=3)
    draw.polygon([(256, 120), (32, 240), (52, 430), (142, 450), (256, 380)], fill=(28, 32, 40, 255), outline=(130, 145, 165, 255), width=3)
    
    # Energy Shield Hexagonal Grid Overlay
    for hx, hy in [(110, 320), (160, 360), (350, 360), (400, 320), (256, 410)]:
        draw.regular_polygon = getattr(draw, "regular_polygon", None)
        # Draw glowing cyan shield lines
        draw.arc([(hx - 30, hy - 30), (hx + 30, hy + 30)], 0, 360, fill=(0, 225, 255, 180), width=2)
        
    # Main Battle Hull (Stealth faceted fortress body)
    draw.polygon([
        (170, 70), (342, 70), (410, 210), (380, 410), (256, 460), (132, 410), (102, 210)
    ], fill=(40, 44, 52, 255), outline=(180, 195, 215, 255), width=4)
    
    # Super-Heavy Plasma Core Reactor (Centered in chest)
    draw.ellipse([(195, 210), (317, 332)], fill=(15, 20, 35, 255), outline=(0, 210, 255, 255), width=4)
    draw.ellipse([(215, 230), (297, 312)], fill=(0, 150, 240, 255), outline=(200, 245, 255, 255), width=2)
    draw.ellipse([(235, 250), (277, 292)], fill=(240, 255, 255, 255))
    
    # Quad Missile Launch Racks (Upper deck)
    for rx, ry in [(180, 100), (220, 95), (265, 95), (305, 100)]:
        draw.rounded_rectangle([(rx, ry), (rx + 28, ry + 60)], radius=4, fill=(22, 25, 30, 255), outline=(90, 100, 115, 255), width=2)
        # Red warhead tips
        draw.ellipse([(rx + 6, ry + 6), (rx + 22, ry + 22)], fill=(255, 45, 25, 255))
        
    # Gatling Rotary Cannons (Dual heavy under-wing mounts)
    for gx in [75, 400]:
        draw.rectangle([(gx, 150), (gx + 38, 300)], fill=(20, 22, 26, 255), outline=(100, 110, 125, 255), width=2)
        # Barrel bundle
        for bx in [gx + 6, gx + 16, gx + 26]:
            draw.line([(bx, 120), (bx, 300)], fill=(70, 75, 85, 255), width=4)
        draw.rectangle([(gx + 3, 110), (gx + 35, 130)], fill=(12, 14, 16, 255), outline=(255, 180, 50, 255), width=2)
        
    # Apex Command Visor (Deep menacing crimson with tactical reticle)
    draw.polygon([(215, 145), (297, 145), (310, 175), (202, 175)], fill=(10, 10, 15, 255), outline=(255, 30, 30, 255), width=2)
    draw.line([(220, 160), (292, 160)], fill=(255, 40, 40, 255), width=3)
    draw.ellipse([(250, 154), (262, 166)], fill=(255, 255, 255, 255))
    
    path = os.path.join(OUTPUT_DIR, "tex_boss_final_assault.png")
    img.save(path, "PNG")
    print(f"[OK] Generated: {path}")

if __name__ == "__main__":
    generate_rpg_soldier()
    generate_combat_robot()
    generate_boss_drone_commander()
    generate_boss_armored_robot()
    generate_boss_final_assault()
