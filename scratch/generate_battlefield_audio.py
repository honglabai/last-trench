import os
import wave
import numpy as np

AUDIO_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/assets/audio"
PCM_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/scratch/megascans/sound_pack_pcm"
SR = 44100


def load_pcm_wav(filename):
    path = os.path.join(PCM_DIR, filename)
    with wave.open(path, "rb") as wf:
        raw = wf.readframes(wf.getnframes())
    data = np.frombuffer(raw, dtype=np.int16).astype(np.float64) / 32768.0
    return data


def save_wav(filename, samples):
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767.0).astype(np.int16)
    path = os.path.join(AUDIO_DIR, filename)
    with wave.open(path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(pcm.tobytes())
    print(f"Generated {filename} ({len(samples)/SR:.2f}s, {os.path.getsize(path)} bytes)")


def lowpass_1pole(x, cutoff_hz):
    rc = 1.0 / (2.0 * np.pi * cutoff_hz)
    dt = 1.0 / SR
    alpha = dt / (rc + dt)
    y = np.zeros_like(x)
    prev = 0.0
    for i in range(len(x)):
        prev = prev + alpha * (x[i] - prev)
        y[i] = prev
    return y


def bandpass_simple(x, low_hz, high_hz):
    lp = lowpass_1pole(x, high_hz)
    return lp - lowpass_1pole(lp, low_hz)


def add_trench_reverb(sig, wet=0.28):
    delays_ms = [23, 41, 67, 103, 149, 211]
    decays = [0.42, 0.30, 0.22, 0.15, 0.10, 0.06]
    tail_len = int(0.30 * SR)
    out = np.zeros(len(sig) + tail_len, dtype=np.float64)
    out[:len(sig)] = sig
    for d_ms, dec in zip(delays_ms, decays):
        d_samp = int((d_ms / 1000.0) * SR)
        reflected = lowpass_1pole(sig, 2200.0) * dec * wet
        out[d_samp:d_samp + len(sig)] += reflected
    return out


def mix_at(dst, src, start_sec, gain=1.0):
    idx = int(start_sec * SR)
    end = min(len(dst), idx + len(src))
    if end > idx:
        dst[idx:end] += src[:end - idx] * gain


def gen_ui_click():
    s = load_pcm_wav("UI_Click_01.wav")
    s /= max(1e-6, np.max(np.abs(s))) * 1.15
    save_wav("sfx_ui_click.wav", s)


def gen_dry_fire():
    """Real Fab interface/metal click layered with crisp firing-pin snap."""
    click = load_pcm_wav("UI_Interface_Click_01.wav")
    metal = load_pcm_wav("Pickaxe_Strike_Metal_Vein_01.wav")[:int(0.08 * SR)]
    metal *= np.exp(-np.linspace(0.0, 1.0, len(metal)) * 12.0)

    dur = 0.14
    out = np.zeros(int(SR * dur), dtype=np.float64)
    mix_at(out, click, 0.0, 0.95)
    mix_at(out, metal, 0.004, 0.55)
    out = np.tanh(out * 1.4)
    out /= max(1e-6, np.max(np.abs(out))) * 1.05
    save_wav("sfx_dry_fire.wav", out)


def gen_reload():
    """3-stage tactical reload using real Fab Slot Insert Click + Armor Plate Foley + bolt slam."""
    slot_click = load_pcm_wav("UI_Slot_Insert_Click_01.wav")
    armor = load_pcm_wav("Armor_Plate_Movement_01.wav")[:int(0.35 * SR)]
    metal = load_pcm_wav("Pickaxe_Strike_Metal_Vein_01.wav")[:int(0.14 * SR)]

    rng = np.random.default_rng(303)
    dur = 1.15
    t = np.linspace(0.0, dur, int(SR * dur), endpoint=False)
    noise = rng.standard_normal(len(t))
    out = np.zeros_like(t)

    # Stage 1: Mag release & slide out (0.04s)
    mix_at(out, armor, 0.02, 0.45)
    mix_at(out, slot_click[:int(0.14 * SR)], 0.05, 0.65)

    # Stage 2: Mag insert & lock (0.44s)
    mix_at(out, slot_click, 0.44, 0.95)

    # Stage 3: Bolt pull & forward metallic slam (0.82s)
    dt = np.maximum(0.0, t - 0.88)
    bolt = (np.sin(2.0 * np.pi * 540.0 * dt) + 0.7 * bandpass_simple(noise, 1500.0, 5000.0)) * np.exp(-dt * 60.0) * (t >= 0.88)
    out += bolt * 0.75
    mix_at(out, metal, 0.88, 0.65)

    out = np.tanh(out * 1.35)
    out /= max(1e-6, np.max(np.abs(out))) * 1.08
    save_wav("sfx_reload.wav", out)


def gen_explosion():
    """Deep warzone explosion using Fab Fireball + Storm Thunder + sub-bass shockwave."""
    fireball = load_pcm_wav("Spell_Fireball_01.wav")
    thunder = load_pcm_wav("Storm_Approaching_Thunder_01.wav")[:int(1.6 * SR)]

    dur = 1.65
    t = np.linspace(0.0, dur, int(SR * dur), endpoint=False)
    sub = np.sin(2.0 * np.pi * (85.0 * np.exp(-t * 5.0) + 28.0) * t) * np.exp(-t * 3.5) * 0.95
    out = sub.copy()
    mix_at(out, fireball, 0.0, 0.85)
    mix_at(out, thunder, 0.02, 0.65)
    out *= np.exp(-t * 1.1)
    out = np.tanh(out * 1.35)
    out /= max(1e-6, np.max(np.abs(out))) * 1.05
    save_wav("sfx_explosion.wav", out)


def gen_drone_rocket():
    """Rocket/RPG launch whoosh + ignition blast using Fab Fireball 02."""
    fb2 = load_pcm_wav("Spell_Fireball_02.wav")[:int(0.95 * SR)]
    fb2 *= np.exp(-np.linspace(0.0, 1.0, len(fb2)) * 2.5)
    fb2 /= max(1e-6, np.max(np.abs(fb2))) * 1.08
    save_wav("sfx_drone_rocket.wav", fb2)


def gen_hit_enemy():
    """Crisp tactical hit confirmation using Fab impact."""
    gore = load_pcm_wav("Gore_Bone_Crack_01.wav")[:int(0.18 * SR)]
    gore *= np.exp(-np.linspace(0.0, 1.0, len(gore)) * 6.0)
    gore /= max(1e-6, np.max(np.abs(gore))) * 1.1
    save_wav("sfx_hit_enemy.wav", gore)


def gen_rifle_shot():
    rng = np.random.default_rng(101)
    dur = 0.45
    t = np.linspace(0.0, dur, int(SR * dur), endpoint=False)
    noise = rng.standard_normal(len(t))
    crack = bandpass_simple(noise, 1200.0, 7500.0) * np.exp(-t * 85.0) * 1.4
    freq_env = 190.0 * np.exp(-t * 38.0) + 52.0
    thump = np.sin(2.0 * np.pi * np.cumsum(freq_env) / SR) * np.exp(-t * 24.0) * 0.95
    roar = lowpass_1pole(noise, 1800.0) * np.exp(-t * 14.0) * 0.75
    bolt_t = np.maximum(0.0, t - 0.022)
    bolt = np.sin(2.0 * np.pi * 2400.0 * bolt_t) * np.exp(-bolt_t * 180.0) * (t >= 0.022) * 0.25
    mix = add_trench_reverb(np.tanh((crack + thump + roar + bolt) * 1.6) * 0.88, wet=0.32)
    mix /= max(1e-6, np.max(np.abs(mix))) * 1.05
    save_wav("sfx_rifle_shot.wav", mix)


def gen_enemy_shot():
    rng = np.random.default_rng(202)
    dur = 0.40
    t = np.linspace(0.0, dur, int(SR * dur), endpoint=False)
    noise = rng.standard_normal(len(t))
    crack = bandpass_simple(noise, 900.0, 5800.0) * np.exp(-t * 72.0) * 1.15
    freq_env = 240.0 * np.exp(-t * 42.0) + 68.0
    thump = np.sin(2.0 * np.pi * np.cumsum(freq_env) / SR) * np.exp(-t * 26.0) * 0.85
    roar = lowpass_1pole(noise, 1400.0) * np.exp(-t * 15.0) * 0.70
    clack_t = np.maximum(0.0, t - 0.018)
    clack = bandpass_simple(noise, 2200.0, 5500.0) * np.exp(-clack_t * 140.0) * (t >= 0.018) * 0.35
    mix = add_trench_reverb(np.tanh((crack + thump + roar + clack) * 1.5) * 0.85, wet=0.38)
    mix /= max(1e-6, np.max(np.abs(mix))) * 1.08
    save_wav("sfx_enemy_shot.wav", mix)


def gen_battlefield_bgm():
    """14-second seamless warzone ambience using Fab Wind & Thunder + distant skirmishes."""
    rng = np.random.default_rng(707)
    dur = 14.0
    n = int(SR * dur)
    t = np.linspace(0.0, dur, n, endpoint=False)

    wind = load_pcm_wav("Wind_Howling_Storm_01.wav")[:n]
    thunder = load_pcm_wav("Storm_Approaching_Thunder_01.wav")[:n]
    bed = wind * 0.32 + thunder * 0.28

    # Crossfade edges for seamless loop
    fade = int(0.5 * SR)
    ramp = np.linspace(0.0, 1.0, fade)
    bed[:fade] = bed[:fade] * ramp + bed[-fade:] * (1.0 - ramp)

    # Distant skirmish pops
    for burst_t in [1.2, 4.8, 9.1, 12.4]:
        for k in range(3):
            bt = burst_t + k * 0.11
            dt = (t - bt) % dur
            env = np.exp(-dt * 28.0) * (dt < 0.25)
            pop = bandpass_simple(rng.standard_normal(n), 350.0, 1200.0) * env * 0.16
            bed += pop

    bed = np.tanh(bed * 1.2) * 0.72
    save_wav("bgm_battlefield.wav", bed)


if __name__ == "__main__":
    gen_ui_click()
    gen_dry_fire()
    gen_reload()
    gen_explosion()
    gen_drone_rocket()
    gen_hit_enemy()
    gen_rifle_shot()
    gen_enemy_shot()
    gen_battlefield_bgm()
