#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uCanvasSize;
uniform vec2 uImageSize;
uniform sampler2D uTexture;
uniform float uExposure;
uniform float uContrast;
uniform float uTemperature;
uniform float uTint;
uniform float uSaturation;

out vec4 fragColor;

vec3 rgb2hsl(vec3 c) {
    float maxc = max(c.r, max(c.g, c.b));
    float minc = min(c.r, min(c.g, c.b));
    float l = (maxc + minc) / 2.0;
    float h = 0.0;
    float s = 0.0;
    if (maxc != minc) {
        float d = maxc - minc;
        s = l > 0.5 ? d / (2.0 - maxc - minc) : d / (maxc + minc);
        if (maxc == c.r) h = (c.g - c.b) / d + (c.g < c.b ? 6.0 : 0.0);
        else if (maxc == c.g) h = (c.b - c.r) / d + 2.0;
        else h = (c.r - c.g) / d + 4.0;
        h /= 6.0;
    }
    return vec3(h, s, l);
}

float hue2rgb(float p, float q, float t) {
    if (t < 0.0) t += 1.0;
    if (t > 1.0) t -= 1.0;
    if (t < 1.0/6.0) return p + (q - p) * 6.0 * t;
    if (t < 0.5) return q;
    if (t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6.0;
    return p;
}

vec3 hsl2rgb(vec3 hsl) {
    float h = hsl.x;
    float s = hsl.y;
    float l = hsl.z;
    if (s == 0.0) return vec3(l);
    float q = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
    float p = 2.0 * l - q;
    return vec3(hue2rgb(p, q, h + 1.0/3.0), hue2rgb(p, q, h), hue2rgb(p, q, h - 1.0/3.0));
}

void main() {
    float canvasAspect = uCanvasSize.x / uCanvasSize.y;
    float imageAspect = uImageSize.x / uImageSize.y;
    vec2 scale = vec2(1.0);
    
    if (canvasAspect > imageAspect) {
        scale.x = imageAspect / canvasAspect;
    } else {
        scale.y = canvasAspect / imageAspect;
    }

    vec2 uv = FlutterFragCoord().xy / uCanvasSize;
    uv = (uv - 0.5) / scale + 0.5;

    // Fundo escuro fora da imagem
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.07, 0.07, 0.07, 1.0); // Cor #111111
        return;
    }

    vec4 color = texture(uTexture, uv);

    color.rgb *= pow(2.0, uExposure);
    color.rgb = (color.rgb - 0.5) * uContrast + 0.5;
    color.r += uTemperature + uTint * 0.5;
    color.g -= uTint;
    color.b -= uTemperature;

    vec3 hsl = rgb2hsl(clamp(color.rgb, 0.0, 1.0));
    hsl.y *= (1.0 + uSaturation);
    color.rgb = hsl2rgb(hsl);

    fragColor = vec4(clamp(color.rgb, 0.0, 1.0), color.a);
}
