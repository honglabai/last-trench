import os
import wave
import numpy as np

AUDIO_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/assets/audio"
SR = 44100


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
    hp = lp - lowpass_1pole(lp, low_hz)
    return hp


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


def gen_rifle_shot():
    """Sharp supersonic crack + chest-punching gunpowder thump + trench echo."""
    rng = np.random.default_rng(101)
    dur = 0.45
    t = np.linspace(0.0, dur, int(SR * dur), endpoint=False)

    # 1. Supersonic muzzle crack (0-25ms)
    noise = rng.standard_normal(len(t))
    crack = bandpass_simple(noise, 1200.0, 7500.0) * np.exp(-t * 85.0) * 1.4

    # 2. Gunpowder low-mid body punch (pitch-dropping sine + sub-thump)
    freq_env = 190.0 * np.exp(-t * 38.0) + 52.0
    phase = 2.0 * np.pi * np.cumsum(freq_env) / SR
    thump = np.sin(phase) * np.exp(-t * 24.0) * 0.95

    # 3. Broad blast roar
    roar = lowpass_1pole(noise, 1800.0) * np.exp(-t * 14.0) * 0.75

    # 4. Crisp metallic bolt snap at 22ms
    bolt_t = np.maximum(0.0, t - 0.022)
    bolt = np.sin(2.0 * np.pi * 2400.0 * bolt_t) * np.exp(-bolt_t * 180.0) * (t >= 0.022) * 0.25

    mix = crack + thump + roar + bolt
    mix = np.tanh(mix * 1.6) * 0.88
    mix = add_trench_reverb(mix, wet=0.32)
    mix /= max(1e-6, np.max(np.abs(mix))) * 1.05
    save_wav("sfx_rifle_shot.wav", mix)


def gen_enemy_shot():
    """Distinct AK-series bark + snappy transient + distant echo."""
    rng = np.random.default_rng(202)
    dur = 0.40
    t = np.linspace(0.0, dur, int(SR * dur), endpoint=False)
    noise = rng.standard_normal(len(t))

    crack = bandpass_simple(noise, 900.0, 5800.0) * np.exp(-t * 72.0) * 1.15
    freq_env = 240.0 * np.exp(-t * 42.0) + 68.0
    thump = np.sin(2.0 * np.pi * np.cumsum(freq_env) / SR) * np.exp(-t * 26.0) * 0.85
    roar = lowpass_1pole(noise, 1400.0) * np.exp(-t * 15.0) * 0.70

    # AK metallic clack
    clack_t = np.maximum(0.0, t - 0.018)
    clack = bandpass_simple(noise, 2200.0, 5500.0) * np.exp(-clack_t * 140.0) * (t >= 0.018) * 0.35

    mix = np.tanh((crack + thump + roar + clack) * 1.5) * 0.85
    mix = add_trench_reverb(mix, wet=0.38)
    mix /= max(1e-6, np.max(np.abs(mix))) * 1.08
    save_wav("sfx_enemy_shot.wav", mix)


def gen_reload():
    """3-stage tactical reload: mag release/slide out -> mag insert clack -> bolt pull & slam."""
    rng = np.random.default_rng(303)
    dur = 1.15
    t = np.linspace(0.0, dur, int(SR * dur), endpoint=False)
    noise = rng.standard_normal(len(t))
    out = np.zeros_like(t)

    def metallic_hit(t0, f1, f2, dec, amp):
        dt = np.maximum(0.0, t - t0)
        mask = t >= t0
        body = (np.sin(2.0 * np.pi * f1 * dt) + 0.6 * np.sin(2.0 * np.pi * f2 * dt)) * np.exp(-dt * dec)
        scrape = bandpass_simple(noise, 1400.0, 5200.0) * np.exp(-dt * (dec * 1.1))
        return (body * 0.6 + scrape * 0.8) * mask * amp

    # Stage 1: Mag release click (0.04s) + slide out friction (0.08s)
    out += metallic_hit(0.04, 1850.0, 3200.0, 120.0, 0.55)
    slide_mask = (t >= 0.08) & (t <= 0.24)
    out += bandpass_simple(noise, 900.0, 3200.0) * slide_mask * np.sin(np.pi * np.clip((t - 0.08) / 0.16, 0, 1)) * 0.35

    # Stage 2: Mag insert slide (0.42s) + firm lock-in thunk (0.52s)
    ins_mask = (t >= 0.42) & (t <= 0.52)
    out += bandpass_simple(noise, 700.0, 2600.0) * ins_mask * 0.32
    out += metallic_hit(0.52, 420.0, 1450.0, 55.0, 0.85)

    # Stage 3: Charging handle pull back (0.80s) + forward bolt slam (0.94s)
    out += metallic_hit(0.80, 1600.0, 3800.0, 95.0, 0.65)
    out += metallic_hit(0.94, 520.0, 2100.0, 65.0, 0.95)

    out = np.tanh(out * 1.35)
    out /= max(1e-6, np.max(np.abs(out))) * 1.08
    save_wav("sfx_reload.wav", out)


def gen_dry_fire():
    """Crisp empty-magazine firing pin 'tic-click!' with hollow receiver resonance."""
    rng = np.random.default_rng(404)
    dur = 0.14
    t = np.linspace(0.0, dur, int(SR * dur), endpoint=False)
    noise = rng.standard_normal(len(t))

    # Primary hammer strike at 0.005s
    dt1 = np.maximum(0.0, t - 0.005)
    m1 = t >= 0.005
    pin = (
        np.sin(2.0 * np.pi * 3400.0 * dt1) * 0.6
        + np.sin(2.0 * np.pi * 1950.0 * dt1) * 0.5
        + bandpass_simple(noise, 2400.0, 7200.0) * 0.9
    ) * np.exp(-dt1 * 165.0) * m1

    # Hollow receiver ring
    ring = np.sin(2.0 * np.pi * 680.0 * dt1) * np.exp(-dt1 * 65.0) * m1 * 0.35

    # Secondary tiny spring rebound at 0.028s
    dt2 = np.maximum(0.0, t - 0.028)
    m2 = t >= 0.028
    rebound = np.sin(2.0 * np.pi * 2800.0 * dt2) * np.exp(-dt2 * 220.0) * m2 * 0.25

    out = np.tanh((pin + ring + rebound) * 1.5)
    out /= max(1e-6, np.max(np.abs(out))) * 1.05
    save_wav("sfx_dry_fire.wav", out)


def gen_turret_shot():
    """Heavy twin-autocannon thump + mechanical shell ejection."""
    rng = np.random.default_rng(505)
    dur = 0.36
    t = np.linspace(0.0, dur, int(SR * dur), endpoint=False)
    noise = rng.standard_normal(len(t))

    freq_env = 140.0 * np.exp(-t * 32.0) + 46.0
    thump = np.sin(2.0 * np.pi * np.cumsum(freq_env) / SR) * np.exp(-t * 20.0) * 1.1
    blast = bandpass_simple(noise, 400.0, 4200.0) * np.exp(-t * 45.0) * 0.95
    mix = add_trench_reverb(np.tanh((thump + blast) * 1.5), wet=0.25)
    mix /= max(1e-6, np.max(np.abs(mix))) * 1.08
    save_wav("sfx_turret_shot.wav", mix)


def gen_explosion():
    """Deep warzone explosion: sub-bass shockwave + debris crackle + canyon rumble."""
    rng = np.random.default_rng(606)
    dur = 1.65
    t = np.linspace(0.0, dur, int(SR * dur), endpoint=False)
    noise = rng.standard_normal(len(t))

    sub = np.sin(2.0 * np.pi * (85.0 * np.exp(-t * 5.0) + 28.0) * t) * np.exp(-t * 3.5) * 1.2
    rumble = lowpass_1pole(noise, 340.0) * np.exp(-t * 2.4) * 1.4
    crackle = bandpass_simple(noise, 1000.0, 5500.0) * np.exp(-t * 9.0) * 0.85
    mix = np.tanh((sub + rumble + crackle) * 1.5)
    mix /= max(1e-6, np.max(np.abs(mix))) * 1.05
    save_wav("sfx_explosion.wav", mix)


def gen_battlefield_bgm():
    """Seamless 14-second looping warzone ambience: wind, low tension pulse, distant artillery & skirmishes."""
    rng = np.random.default_rng(707)
    dur = 14.0
    n = int(SR * dur)
    t = np.linspace(0.0, dur, n, endpoint=False)
    noise = rng.standard_normal(n)

    # Low desolate battlefield wind + sub drone
    wind = lowpass_1pole(noise, 260.0) * 0.25
    drone = (np.sin(2.0 * np.pi * 55.0 * t) * 0.14 + np.sin(2.0 * np.pi * 82.41 * t) * 0.09)
    pulse = 0.7 + 0.3 * np.sin(2.0 * np.pi * (t / 3.5))
    bed = wind + drone * pulse

    # Distant artillery rumbles at 2.1s, 6.8s, 11.2s
    for boom_t in [2.1, 6.8, 11.2]:
        dt = (t - boom_t) % dur
        boom_env = np.exp(-dt * 2.2) * (dt < 2.2)
        boom = lowpass_1pole(rng.standard_normal(n), 140.0) * boom_env * 0.45
        bed += boom

    # Far-off muffled rifle bursts
    for burst_t in [1.0, 4.3, 8.9, 12.6]:
        for k in range(3):
            bt = burst_t + k * 0.11
            dt = (t - bt) % dur
            env = np.exp(-dt * 28.0) * (dt < 0.25)
            pop = bandpass_simple(rng.standard_normal(n), 350.0, 1200.0) * env * 0.18
            bed += pop

    bed = np.tanh(bed * 1.2) * 0.72
    save_wav("bgm_battlefield.wav", bed)


if __name__ == "__main__":
    gen_rifle_shot()
    gen_enemy_shot()
    gen_reload()
    gen_dry_fire()
    gen_turret_shot()
    gen_explosion()
    gen_battlefield_bgm()
