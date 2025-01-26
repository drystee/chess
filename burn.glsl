// burn.glsl
extern number time;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
    float burnAmount = time; // Use time to control burn
    if (texture_coords.y < burnAmount) {
        return vec4(0.0, 0.0, 0.0, 0.0); // Burned area
    }
    return pixel * color;
}
