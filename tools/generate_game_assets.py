#!/usr/bin/env python3
"""
최후의 참호 (LAST TRENCH) - 3D 텍스처, 스카이박스 파노라마 및 모바일 UI 에셋 생성기
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter

random.seed(42)

def clamp(v, min_v=0, max_v=255):
    return max(min_v, min(max_v, int(v)))

# -------------------------------------------------------------
# 1. 3D 텍스처 생성기 (Seamless Tileable & Model Textures)
# -------------------------------------------------------------

def generate_trench_ground(path="assets/textures/tex_trench_ground.png", size=512):
    img = Image.new("RGB", (size, size), (45, 36, 26))
    draw = ImageDraw.Draw(img)
    
    # Layer 1: Base earthy dirt noise
    pixels = img.load()
    for y in range(size):
        for x in range(size):
            # Tileable sine noise
            nx = math.sin(x * 2 * math.pi / size * 4) + math.sin(x * 2 * math.pi / size * 8) * 0.5
            ny = math.cos(y * 2 * math.pi / size * 4) + math.cos(y * 2 * math.pi / size * 8) * 0.5
            noise = (nx + ny) * 12 + random.uniform(-18, 18)
            r = clamp(52 + noise * 1.1)
            g = clamp(42 + noise * 0.9)
            b = clamp(30 + noise * 0.7)
            pixels[x, y] = (r, g, b)
            
    # Layer 2: Mud splatters & pebbles
    for _ in range(800):
        px = random.randint(0, size - 1)
        py = random.randint(0, size - 1)
        pr = random.randint(2, 6)
        color = (
            clamp(random.randint(25, 35)),
            clamp(random.randint(20, 28)),
            clamp(random.randint(15, 22))
        ) if random.random() < 0.6 else (
            clamp(random.randint(75, 95)),
            clamp(random.randint(65, 80)),
            clamp(random.randint(50, 65))
        )
        draw.ellipse([px - pr, py - pr, px + pr, py + pr], fill=color)
        
    img = img.filter(ImageFilter.SMOOTH_MORE)
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_sandbag(path="assets/textures/tex_sandbag.png", size=512):
    img = Image.new("RGB", (size, size), (140, 118, 80))
    pixels = img.load()
    
    # Burlap cross-weave pattern
    for y in range(size):
        for x in range(size):
            wx = (x % 8) < 4
            wy = (y % 8) < 4
            weave = 16 if (wx ^ wy) else -16
            noise = random.uniform(-12, 12) + weave
            
            # Subtle vertical sack folds
            fold = math.sin(x * 2 * math.pi / 64) * 15
            
            r = clamp(142 + noise + fold)
            g = clamp(120 + noise * 0.9 + fold)
            b = clamp(85 + noise * 0.7 + fold)
            pixels[x, y] = (r, g, b)
            
    draw = ImageDraw.Draw(img)
    # Sack stitching lines
    for sy in [size // 4, size // 2, size * 3 // 4]:
        for sx in range(0, size, 12):
            draw.line([(sx, sy), (sx + 6, sy + 2)], fill=(70, 55, 35), width=2)
            
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_bunker_wall(path="assets/textures/tex_base_bunker.png", size=512):
    img = Image.new("RGB", (size, size), (50, 55, 60))
    draw = ImageDraw.Draw(img)
    
    # Concrete and riveted steel plates
    plate_size = size // 2
    for py in range(2):
        for px in range(2):
            x0 = px * plate_size + 4
            y0 = py * plate_size + 4
            x1 = (px + 1) * plate_size - 4
            y1 = (py + 1) * plate_size - 4
            
            # Steel plate base
            draw.rectangle([x0, y0, x1, y1], fill=(58, 64, 70), outline=(35, 40, 44), width=3)
            # Inner bevel highlight
            draw.line([(x0 + 2, y0 + 2), (x1 - 2, y0 + 2)], fill=(85, 95, 105), width=2)
            draw.line([(x0 + 2, y0 + 2), (x0 + 2, y1 - 2)], fill=(85, 95, 105), width=2)
            
            # Corner rivets/bolts
            for rx, ry in [(x0 + 16, y0 + 16), (x1 - 16, y0 + 16), (x0 + 16, y1 - 16), (x1 - 16, y1 - 16)]:
                draw.ellipse([rx - 6, ry - 6, rx + 6, ry + 6], fill=(25, 28, 30), outline=(110, 120, 130), width=1)
                draw.ellipse([rx - 2, ry - 2, rx + 2, ry + 2], fill=(160, 170, 180))
                
    # Center hazard stripe
    hz_y = size // 2 - 20
    draw.rectangle([0, hz_y, size, hz_y + 40], fill=(30, 32, 35))
    for sx in range(-40, size + 40, 32):
        draw.polygon([(sx, hz_y), (sx + 16, hz_y), (sx + 32, hz_y + 40), (sx + 16, hz_y + 40)], fill=(210, 160, 30))
        
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_soldier_camo(path="assets/textures/tex_soldier_camo.png", size=512):
    # Olive drab tactical digital camo
    img = Image.new("RGB", (size, size), (58, 72, 52))
    draw = ImageDraw.Draw(img)
    
    colors = [
        (42, 54, 38),   # Dark olive
        (78, 96, 70),   # Light sage
        (85, 75, 55),   # Khaki brown
        (32, 38, 30),   # Charcoal green
    ]
    
    # Camo blotches
    for _ in range(120):
        cx = random.randint(0, size)
        cy = random.randint(0, size)
        c = random.choice(colors)
        rw = random.randint(30, 90)
        rh = random.randint(20, 60)
        draw.ellipse([cx, cy, cx + rw, cy + rh], fill=c)
        
    # Tactical vest webbing bands
    for wy in [140, 200, 260]:
        draw.rectangle([0, wy, size, wy + 18], fill=(35, 42, 32))
        for wx in range(10, size, 40):
            draw.line([(wx, wy), (wx, wy + 18)], fill=(20, 24, 18), width=3)
            
    # Unit insignia badge
    draw.polygon([(size//2 - 25, 340), (size//2 + 25, 340), (size//2, 380)], fill=(180, 140, 40), outline=(230, 190, 60), width=2)
    
    img = img.filter(ImageFilter.SMOOTH)
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_enemy_infantry(path="assets/textures/tex_enemy_infantry.png", size=512):
    # Sinister dark assault gear with crimson tactical accents
    img = Image.new("RGB", (size, size), (36, 40, 46))
    draw = ImageDraw.Draw(img)
    
    # Charcoal urban camo
    for _ in range(80):
        cx = random.randint(0, size)
        cy = random.randint(0, size)
        c = random.choice([(26, 28, 32), (48, 54, 62), (60, 68, 78)])
        draw.rectangle([cx, cy, cx + random.randint(20, 60), cy + random.randint(20, 60)], fill=c)
        
    # Crimson ballistic armor plates
    draw.rectangle([60, 120, size - 60, 280], fill=(40, 20, 20), outline=(160, 35, 35), width=4)
    # Sinister red skull/hazard chevron
    draw.polygon([(size//2, 150), (size//2 - 40, 210), (size//2 - 15, 210), (size//2, 240), (size//2 + 15, 210), (size//2 + 40, 210)], fill=(220, 40, 40))
    
    # Glowing visor bar
    draw.rectangle([100, 40, size - 100, 75], fill=(240, 30, 30))
    draw.rectangle([140, 48, size - 140, 67], fill=(255, 120, 120))
    
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_enemy_drone(path="assets/textures/tex_enemy_drone.png", size=512):
    # Matte carbon fiber hull with orange warning stripes & sensor optics
    img = Image.new("RGB", (size, size), (28, 30, 34))
    pixels = img.load()
    
    # Carbon fiber weave texture
    for y in range(size):
        for x in range(size):
            cf = 10 if ((x // 4) % 2) ^ ((y // 4) % 2) else -10
            pixels[x, y] = (clamp(28 + cf), clamp(30 + cf), clamp(34 + cf))
            
    draw = ImageDraw.Draw(img)
    # Orange high-visibility hazard stripes
    for ax in range(-50, size + 50, 40):
        draw.polygon([(ax, 0), (ax + 18, 0), (ax + 38, 80), (ax + 20, 80)], fill=(230, 90, 15))
        draw.polygon([(ax, size - 80), (ax + 18, size - 80), (ax + 38, size), (ax + 20, size)], fill=(230, 90, 15))
        
    # Central sensor lens (Glowing red/orange eye)
    cx, cy = size // 2, size // 2
    draw.ellipse([cx - 80, cy - 80, cx + 80, cy + 80], fill=(15, 18, 22), outline=(80, 85, 95), width=6)
    draw.ellipse([cx - 50, cy - 50, cx + 50, cy + 50], fill=(180, 40, 10), outline=(240, 90, 20), width=4)
    draw.ellipse([cx - 20, cy - 20, cx + 20, cy + 20], fill=(255, 180, 60))
    
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_turret_texture(path="assets/textures/tex_mg_turret.png", size=512):
    # Heavy industrial gunmetal, ammo feed, cooling vents
    img = Image.new("RGB", (size, size), (38, 42, 45))
    draw = ImageDraw.Draw(img)
    
    # Steel panels
    draw.rectangle([10, 10, size - 10, size - 10], outline=(70, 78, 85), width=4)
    # Cooling vent perforations
    for vy in range(60, 220, 20):
        for vx in range(60, size - 60, 30):
            draw.ellipse([vx, vy, vx + 16, vy + 10], fill=(18, 20, 22), outline=(90, 100, 110), width=1)
            
    # Brass ammo belt section
    draw.rectangle([40, 260, size - 40, 340], fill=(25, 28, 30), outline=(50, 55, 60), width=2)
    for bx in range(50, size - 50, 24):
        # Brass cartridge
        draw.rounded_rectangle([bx, 270, bx + 16, 330], radius=4, fill=(195, 150, 50), outline=(230, 185, 75))
        draw.ellipse([bx + 4, 264, bx + 12, 274], fill=(220, 90, 30))
        
    # Caliber warning stencil
    draw.rectangle([40, 380, size - 40, 460], fill=(28, 32, 34))
    draw.rectangle([48, 388, size - 48, 452], outline=(220, 170, 30), width=3)
    
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_defense_slot_marker(path="assets/textures/tex_defense_slot.png", size=512):
    # Circular concrete mount with glowing cyan tactical marker and yellow hazard ring
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy = size // 2, size // 2
    r_outer = size // 2 - 10
    
    # Outer dark steel ring
    draw.ellipse([cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer], fill=(45, 50, 55, 240), outline=(80, 90, 100, 255), width=6)
    
    # Hazard segments
    r_hz_out = r_outer - 15
    r_hz_in = r_outer - 55
    steps = 24
    for i in range(steps):
        start_deg = i * (360 / steps)
        end_deg = (i + 1) * (360 / steps)
        color = (230, 180, 25, 240) if i % 2 == 0 else (25, 28, 30, 240)
        draw.pieslice([cx - r_hz_out, cy - r_hz_out, cx + r_hz_out, cy + r_hz_out], start_deg, end_deg, fill=color)
        
    # Inner tactical mounting ring
    draw.ellipse([cx - r_hz_in, cy - r_hz_in, cx + r_hz_in, cy + r_hz_in], fill=(30, 35, 40, 255), outline=(50, 160, 220, 255), width=6)
    
    # 4 Anchor bolt mounts
    for angle in [0, 90, 180, 270]:
        rad = math.radians(angle)
        bx = cx + int(math.cos(rad) * (r_hz_in - 30))
        by = cy + int(math.sin(rad) * (r_hz_in - 30))
        draw.ellipse([bx - 14, by - 14, bx + 14, by + 14], fill=(70, 80, 90, 255), outline=(130, 145, 160, 255), width=2)
        draw.ellipse([bx - 5, by - 5, bx + 5, by + 5], fill=(20, 25, 30, 255))
        
    # Center tactical turret anchor logo
    draw.ellipse([cx - 40, cy - 40, cx + 40, cy + 40], fill=(20, 60, 85, 230), outline=(60, 200, 255, 255), width=4)
    draw.line([(cx - 25, cy), (cx + 25, cy)], fill=(60, 200, 255, 255), width=4)
    draw.line([(cx, cy - 25), (cx, cy + 25)], fill=(60, 200, 255, 255), width=4)
    
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

# -------------------------------------------------------------
# 2. 배경 스카이박스 파노라마 생성기
# -------------------------------------------------------------

def generate_sky_panorama(path="assets/environment/sky_battlefield_panorama.png", width=1024, height=512):
    # Dramatic battlefield overcast sky with war smoke and fiery artillery sunset glow
    img = Image.new("RGB", (width, height))
    pixels = img.load()
    
    for y in range(height):
        # Vertical gradient factor (0=top sky, 1=horizon, >0.6 horizon fog)
        v = y / height
        
        for x in range(width):
            # Cloud and smoke turbulence
            nx = math.sin(x * 2 * math.pi / width * 3) + math.sin(x * 2 * math.pi / width * 7) * 0.4
            cloud = nx * 18 + random.uniform(-10, 10)
            
            if v < 0.45:
                # Top storm clouds: Dark slate-blue / stormy gray
                t = v / 0.45
                r = clamp(35 + t * 45 + cloud * 0.8)
                g = clamp(42 + t * 35 + cloud * 0.8)
                b = clamp(55 + t * 25 + cloud * 0.9)
            elif v < 0.72:
                # Mid altitude: War smoke & distant fiery artillery glow
                t = (v - 0.45) / 0.27
                # Horizon orange glow centered around middle front (x ~ width/2)
                hx = math.exp(-((x - width / 2) / 320) ** 2) * 55
                r = clamp(80 + t * 90 + hx + cloud)
                g = clamp(77 + t * 35 + hx * 0.4 + cloud * 0.6)
                b = clamp(80 - t * 25 - hx * 0.3 + cloud * 0.4)
            else:
                # Lower horizon: Dusty battlefield haze & no-man's land fog
                t = (v - 0.72) / 0.28
                r = clamp(170 - t * 95)
                g = clamp(112 - t * 65)
                b = clamp(55 - t * 30)
                
            pixels[x, y] = (r, g, b)
            
    img = img.filter(ImageFilter.GaussianBlur(radius=2))
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

# -------------------------------------------------------------
# 3. UI 버튼 및 HUD 그래픽 생성기 (RGBA Alpha Icons)
# -------------------------------------------------------------

def generate_joystick_base(path="assets/ui/ui_joystick_base.png", size=256):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy = size // 2, size // 2
    r_outer = size // 2 - 8
    
    # Translucent dark glass disc
    draw.ellipse([cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer], fill=(20, 26, 24, 130), outline=(80, 130, 90, 210), width=4)
    # Inner reticle ring
    r_inner = r_outer - 24
    draw.ellipse([cx - r_inner, cy - r_inner, cx + r_inner, cy + r_inner], outline=(60, 100, 70, 140), width=2)
    
    # Tactical directional cross ticks
    for angle in [0, 90, 180, 270]:
        rad = math.radians(angle)
        x1 = cx + math.cos(rad) * (r_outer - 18)
        y1 = cy + math.sin(rad) * (r_outer - 18)
        x2 = cx + math.cos(rad) * r_outer
        y2 = cy + math.sin(rad) * r_outer
        draw.line([(x1, y1), (x2, y2)], fill=(120, 220, 140, 230), width=4)
        
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_joystick_knob(path="assets/ui/ui_joystick_knob.png", size=128):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy = size // 2, size // 2
    r = size // 2 - 6
    
    # Beveled tactical thumbstick
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(45, 62, 50, 230), outline=(130, 210, 150, 255), width=4)
    # Concentric knurled grip ring
    draw.ellipse([cx - r + 14, cy - r + 14, cx + r - 14, cy + r - 14], fill=(30, 42, 34, 240), outline=(90, 140, 100, 200), width=2)
    # Center glowing tactical chevron
    draw.polygon([(cx, cy - 14), (cx - 10, cy + 8), (cx + 10, cy + 8)], fill=(150, 255, 170, 240))
    
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_btn_fire(path="assets/ui/btn_fire.png", size=160):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy = size // 2, size // 2
    r = size // 2 - 6
    
    # High-intensity red/crimson combat button
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(65, 20, 20, 200), outline=(240, 60, 60, 255), width=5)
    draw.ellipse([cx - r + 10, cy - r + 10, cx + r - 10, cy + r - 10], outline=(180, 40, 40, 150), width=2)
    
    # Central Stylized Bullet Cartridge & Muzzle Flash
    # Center bullet
    draw.rounded_rectangle([cx - 12, cy - 18, cx + 12, cy + 30], radius=4, fill=(240, 200, 70, 255), outline=(255, 230, 130, 255), width=2)
    draw.polygon([(cx - 12, cy - 18), (cx + 12, cy - 18), (cx, cy - 36)], fill=(255, 110, 30, 255))
    
    # Side flanking bullets
    for offset_x in [-28, 28]:
        draw.rounded_rectangle([cx + offset_x - 8, cy - 8, cx + offset_x + 8, cy + 28], radius=3, fill=(200, 160, 50, 230))
        draw.polygon([(cx + offset_x - 8, cy - 8), (cx + offset_x + 8, cy - 8), (cx + offset_x, cy - 22)], fill=(230, 80, 20, 230))
        
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_btn_aim(path="assets/ui/btn_aim.png", size=140):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy = size // 2, size // 2
    r = size // 2 - 6
    
    # Tactical Cyan/Blue Sniper ADS button
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(18, 38, 55, 200), outline=(50, 180, 240, 255), width=4)
    
    # Sniper scope crosshair
    scope_r = 38
    draw.ellipse([cx - scope_r, cy - scope_r, cx + scope_r, cy + scope_r], outline=(80, 210, 255, 255), width=3)
    draw.line([(cx - scope_r - 12, cy), (cx - 12, cy)], fill=(80, 210, 255, 255), width=3)
    draw.line([(cx + 12, cy), (cx + scope_r + 12, cy)], fill=(80, 210, 255, 255), width=3)
    draw.line([(cx, cy - scope_r - 12), (cx, cy - 12)], fill=(80, 210, 255, 255), width=3)
    draw.line([(cx, cy + 12), (cx, cy + scope_r + 12)], fill=(80, 210, 255, 255), width=3)
    draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(255, 60, 60, 255))
    
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_btn_reload(path="assets/ui/btn_reload.png", size=140):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy = size // 2, size // 2
    r = size // 2 - 6
    
    # Emerald green reload button
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(20, 48, 32, 200), outline=(60, 210, 120, 255), width=4)
    
    # Circular clockwise reload arrows
    arrow_r = 32
    draw.arc([cx - arrow_r, cy - arrow_r, cx + arrow_r, cy + arrow_r], start=30, end=150, fill=(80, 240, 140, 255), width=6)
    draw.arc([cx - arrow_r, cy - arrow_r, cx + arrow_r, cy + arrow_r], start=210, end=330, fill=(80, 240, 140, 255), width=6)
    
    # Arrowheads
    draw.polygon([(cx - arrow_r + 10, cy - 18), (cx - arrow_r - 8, cy - 18), (cx - arrow_r + 1, cy - 32)], fill=(80, 240, 140, 255))
    draw.polygon([(cx + arrow_r - 10, cy + 18), (cx + arrow_r + 8, cy + 18), (cx + arrow_r - 1, cy + 32)], fill=(80, 240, 140, 255))
    
    # Center magazine icon
    draw.rectangle([cx - 10, cy - 14, cx + 10, cy + 14], fill=(40, 80, 55, 230), outline=(130, 230, 160, 255), width=2)
    
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_btn_interact(path="assets/ui/btn_interact.png", size=160):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy = size // 2, size // 2
    r = size // 2 - 6
    
    # Amber gold tactical engineering button
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(55, 42, 16, 220), outline=(245, 185, 35, 255), width=5)
    
    # Turret gun silhouette & wrench icon
    # Turret base
    draw.polygon([(cx - 28, cy + 26), (cx + 28, cy + 26), (cx + 18, cy + 8), (cx - 18, cy + 8)], fill=(245, 195, 45, 255))
    # Turret swivel & twin barrels
    draw.rounded_rectangle([cx - 16, cy - 4, cx + 16, cy + 8], radius=3, fill=(255, 225, 90, 255))
    draw.rectangle([cx - 8, cy - 28, cx - 2, cy - 4], fill=(255, 225, 90, 255))
    draw.rectangle([cx + 2, cy - 28, cx + 8, cy - 4], fill=(255, 225, 90, 255))
    
    # Crossed wrench tool behind
    draw.line([(cx - 30, cy - 20), (cx + 30, cy + 18)], fill=(180, 130, 25, 230), width=4)
    
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_crosshair(path="assets/ui/ui_crosshair.png", size=128):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy = size // 2, size // 2
    
    # Sharp tactical military crosshair with center red/cyan dot and brackets
    draw.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(255, 60, 60, 255))
    
    # Crosshair posts
    color = (255, 255, 255, 210)
    draw.line([(cx - 32, cy), (cx - 10, cy)], fill=color, width=2)
    draw.line([(cx + 10, cy), (cx + 32, cy)], fill=color, width=2)
    draw.line([(cx, cy - 32), (cx, cy - 10)], fill=color, width=2)
    draw.line([(cx, cy + 10), (cx, cy + 32)], fill=color, width=2)
    
    # 4 Tactical corner brackets
    d = 26
    len_b = 10
    # Top-Left
    draw.line([(cx - d, cy - d), (cx - d + len_b, cy - d)], fill=color, width=2)
    draw.line([(cx - d, cy - d), (cx - d, cy - d + len_b)], fill=color, width=2)
    # Top-Right
    draw.line([(cx + d, cy - d), (cx + d - len_b, cy - d)], fill=color, width=2)
    draw.line([(cx + d, cy - d), (cx + d, cy - d + len_b)], fill=color, width=2)
    # Bottom-Left
    draw.line([(cx - d, cy + d), (cx - d + len_b, cy + d)], fill=color, width=2)
    draw.line([(cx - d, cy + d), (cx - d, cy + d - len_b)], fill=color, width=2)
    # Bottom-Right
    draw.line([(cx + d, cy + d), (cx + d - len_b, cy + d)], fill=color, width=2)
    draw.line([(cx + d, cy + d), (cx + d, cy + d - len_b)], fill=color, width=2)
    
    img.save(path, "PNG", optimize=True)
    print(f"[OK] Generated: {path}")

def generate_hud_icons():
    # 1. Soldier HP icon (Helmet shield)
    img_soldier = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_soldier)
    d.polygon([(32, 6), (56, 16), (50, 48), (32, 60), (14, 48), (8, 16)], fill=(40, 110, 60, 240), outline=(80, 220, 120, 255), width=3)
    # Red Cross on helmet
    d.rectangle([28, 22, 36, 42], fill=(255, 255, 255, 255))
    d.rectangle([22, 28, 42, 36], fill=(255, 255, 255, 255))
    img_soldier.save("assets/ui/icon_hp_soldier.png", "PNG", optimize=True)
    
    # 2. Base HP icon (Fortress Bunker)
    img_base = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_base)
    d.polygon([(32, 8), (56, 20), (52, 56), (12, 56), (8, 20)], fill=(35, 75, 125, 240), outline=(75, 155, 245, 255), width=3)
    # Bunker gun slit
    d.rectangle([20, 30, 44, 38], fill=(15, 25, 45, 255), outline=(130, 190, 255, 255), width=2)
    img_base.save("assets/ui/icon_hp_base.png", "PNG", optimize=True)
    
    # 3. Ammo icon (Golden cartridge)
    img_ammo = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_ammo)
    d.rounded_rectangle([24, 18, 40, 56], radius=4, fill=(225, 175, 45, 255), outline=(255, 215, 90, 255), width=2)
    d.polygon([(24, 18), (40, 18), (32, 6)], fill=(240, 100, 30, 255))
    img_ammo.save("assets/ui/icon_ammo.png", "PNG", optimize=True)
    
    # 4. Revive Token icon (Golden eagle medical crest)
    img_rev = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_rev)
    d.ellipse([6, 6, 58, 58], fill=(60, 48, 15, 230), outline=(245, 195, 40, 255), width=3)
    d.polygon([(32, 12), (48, 26), (40, 48), (32, 54), (24, 48), (16, 26)], fill=(230, 170, 30, 255))
    d.rectangle([29, 24, 35, 40], fill=(255, 255, 255, 255))
    d.rectangle([24, 29, 40, 35], fill=(255, 255, 255, 255))
    img_rev.save("assets/ui/icon_revive.png", "PNG", optimize=True)
    print("[OK] Generated HUD icons")

def main():
    print("[ASSET GENERATOR] Generating high-resolution mobile-optimized game assets...")
    generate_trench_ground()
    generate_sandbag()
    generate_bunker_wall()
    generate_soldier_camo()
    generate_enemy_infantry()
    generate_enemy_drone()
    generate_turret_texture()
    generate_defense_slot_marker()
    generate_sky_panorama()
    generate_joystick_base()
    generate_joystick_knob()
    generate_btn_fire()
    generate_btn_aim()
    generate_btn_reload()
    generate_btn_interact()
    generate_crosshair()
    generate_hud_icons()
    generate_result_banners()
    print("[ASSET GENERATOR] All game assets successfully created!")

def generate_result_banners():
    # 1. Victory Banner (512x128)
    img_v = Image.new("RGBA", (512, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_v)
    d.rounded_rectangle([10, 10, 502, 118], radius=16, fill=(20, 45, 25, 230), outline=(235, 195, 50, 255), width=4)
    d.rounded_rectangle([18, 18, 494, 110], radius=12, outline=(100, 180, 120, 160), width=2)
    # Golden laurel leaves / stars
    for sx in [60, 100, 412, 452]:
        d.ellipse([sx - 12, 64 - 12, sx + 12, 64 + 12], fill=(245, 205, 55, 255))
    img_v.save("assets/ui/banner_victory.png", "PNG", optimize=True)
    
    # 2. Defeat Banner (512x128)
    img_d = Image.new("RGBA", (512, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_d)
    d.rounded_rectangle([10, 10, 502, 118], radius=16, fill=(45, 18, 20, 230), outline=(225, 50, 50, 255), width=4)
    d.rounded_rectangle([18, 18, 494, 110], radius=12, outline=(160, 60, 60, 160), width=2)
    # Hazard warning triangles
    for tx in [70, 442]:
        d.polygon([(tx, 44), (tx - 18, 80), (tx + 18, 80)], fill=(235, 60, 60, 255))
        d.rectangle([tx - 2, 54, tx + 2, 70], fill=(255, 255, 255, 255))
        d.ellipse([tx - 2, 73, tx + 2, 77], fill=(255, 255, 255, 255))
    img_d.save("assets/ui/banner_defeat.png", "PNG", optimize=True)
    print("[OK] Generated Victory & Defeat Banners")

if __name__ == "__main__":
    main()
