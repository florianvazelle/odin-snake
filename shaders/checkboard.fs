#version 330 core

uniform float size = 32.0;
uniform vec4 color1 = vec4(0.25098039215686274, 0.07450980392156863, 0.8980392156862745, 1.0); 
uniform vec4 color2 = vec4(0.27058823529411763, 0.10196078431372549, 0.9647058823529412, 1.0);

out vec4 fragColor;

void main() {
    // Normalize fragment coordinates
    vec2 pos = floor(gl_FragCoord.xy / size);
    
    // Generate a pattern based on position
    float pattern_mask = mod(pos.x + mod(pos.y, 2.0), 2.0);
    
    // Mix the two colors based on the pattern
    fragColor = mix(color1, color2, pattern_mask);
}
