// Vertex shader

var<private> quad: array<vec2f, 6> = array<vec2f, 6>(
  vec2f(-1.0,  1.0),
  vec2f(-1.0, -1.0),
  vec2f( 1.0,  1.0),
  vec2f( 1.0,  1.0),
  vec2f(-1.0, -1.0),
  vec2f( 1.0, -1.0),
);

@vertex
fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> @builtin(position) vec4f {
    return vec4<f32>(quad[in_vertex_index], 0.0, 1.0);
}

// Fragment shader

@group(0) @binding(0) var frame: texture_storage_2d<rgba8unorm, read_write>;

@fragment
fn fs_main(@builtin(position) pos: vec4f) -> @location(0) vec4<f32> {
    // // Camera constants (scaled based off screen dimensions)
    // let horizon = f32(camera.screen_height) / 4.0;
    // let scale_factor = f32(camera.screen_height) * 1.2;
    // let sinPhi = sin(camera.angle);
    // let cosPhi = cos(camera.angle);
    // let distance = 1200.0;

    // // Normalize coordinates to [0, 1.0] and compute sky gradient
    // let uv = pos.xy / vec2f(f32(camera.screen_width - 1u), f32(camera.screen_height - 1u));
    // var sky_color = vec4f(vec3f(0.3, 0.5, 1.0) * (1.0 - uv.y), 1.0);

    // // Run algorithm on map
    // let map_size = textureDimensions(t_height_map, 0).xy;
    // for (var z = 0.2; z < distance; z += 1.0) {
    //     // Field of view scaling and rotation calculations
    //     let half_width = z * tan(camera.fov * 0.5);
    //     let pleft = vec2(
    //         -cosPhi * half_width - sinPhi * z + camera.p.x,
    //         sinPhi * half_width - cosPhi * z + camera.p.y
    //     );
    //     let pright = vec2(
    //         cosPhi * half_width - sinPhi * z + camera.p.x,
    //         -sinPhi * half_width - cosPhi * z + camera.p.y
    //     );

    //     let dx = (pright - pleft) / f32(camera.screen_width);
    //     var current = pleft + pos.x * dx;

    //     // Normalize texture sampling coordinates to [0, 1.0] and sample repeating texture for height
    //     let map_uv = (current.xy / vec2<f32>(f32(map_size.x - 1u), f32(map_size.y - 1u)));
    //     let height_val = textureSample(t_height_map, s_height_map, map_uv).r * 255; 

    //     // Adjust height on screen based on camera constants like height and distance from camera (z value)
    //     let height_on_screen = ((camera.height - height_val) / z) * scale_factor + horizon;

    //     if (height_on_screen < pos.y) {
    //         // Sample repeating texture for color and compute fog based of z distance
    //         let terrain_color = textureSample(t_color_map, s_height_map, map_uv);
    //         let fog = pow((distance - z) / distance, 0.2f);
    //         let shaded_terrain = ((fog * terrain_color) + (1 - fog) * sky_color);
    //         return shaded_terrain;
    //     }
    // }

    // return sky_color;

    let x = i32(pos.x);
    let y = i32(pos.y);
    return textureLoad(frame, vec2<i32>(x, y));
}
