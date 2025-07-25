fn mulsw(b: i16, c:i16) i32 {
    return @as(i32,b) * c;
}

fn abs(val: i16) i16 {
    return @abs(val) orelse 32767;
}

fn clamp(val: i32) i16 {
    return 32767 if (val > 32767) else -32768 if (val < -32768) else val;
}

fn distortion(val: i16, gain: u8) i16 {
    val temp:i32;
    val res:i16;
    val = clamp(val * gain >> 5) >> 1;
    temp = mulsw(val, 32767-abs(val));
    res = temp >> 16;
    return res << 3;
}

fn vol(val: i16, gain: u8) i16 {
    return mulsw(val, gain) >> 7;
}

fn oscsaw(instance: u8, freq: i16, gain: u8) i16 {
    counter_saw[instance] +%= freq;
    return vol(counter_saw[instance], gain);
}

fn sh(instance: u8, val1: i16, step: u8) i16 {
    const step2:i16 = mulsw(step, step) >> 2;
    counter_sh[instance]--;
    if (counter_sh[instance] < 0) {
        buffer_sh[instance] = val1;
        counter_sh[instance] = step2;
    }
    return buffer_sh[instance];
}

fn osc_tri(instance: u8, freq: i16, gain: u8) i16 {
    counter_tri[instance] += freq;
    val buf:i16 = counter_tri[instance];
    if (buf < 0) buf = 65535 - buf;
    buf -= 16384;
    buf <<= 1;
    return vol(buf, gain);
}

fn osc_sine(instance: u8, freq: i16, gain: u8) i16 {
    counter_sine[instance] +%= freq;
    const buf:i16 = counter_sine[instance] - 16384;
    const temp = mulsw(buf, 32767-abs(buf));
    const res = temp >> 16;
    return vol(res << 3, gain);
}

fn osc_pulse(instance: u8, freq: i16, gain: u8, dutycycle: u8) i16 {
    counter_pulse[instance] +%= freq;
    var buf:i16 = counter_pulse[instance];
    buf = if (buf < (dutycycle-32) << 9) -32768 else 32767;
    return vol(buf,gain);
}

var g_x1:u32 = 0x67452301;
var g_x2:u32 = 0xefcdab89;
var g_x3:u32 = 0;

fn osc_noise(sample:u16, gain:u8) i16 {
    g_x1 ^= g_x2;
    g_x3 += g_x2;
    g_x2 += g_x1;
    const buf:i16=g_x3;
    return vol(buf, gain);   
}

fn enva(sample:i16, attack:i8, sustain:i8, gain:u8) i16 {
    var t:i16 = decayTable[attack];
    var buf:i16 = ((sample * t) >> 8);
    if (buf > 32767) buf = 32767;
    return vol(buf, gain);
}

fn envd(sample:i16, decay:i8, sustain:i8, gain:u8) i16 {
    var sustain16:i32 = sustain<<8;
    const t:i32 = decayTable[decay];
    var buf:i32 = 32767 - ((sample * t) >> 8);
    if (buf <= sustain16) buf = sustain16;
    return vol(buf, gain);
}
