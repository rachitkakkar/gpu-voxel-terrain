struct CameraUniform {
    p: vec2<f32>,
    height: f32,
    angle: f32,
    fov: f32,
    screen_width: u32,
    screen_height: u32,
};

@group(0) @binding(0) var<uniform> camera: CameraUniform;
@group(1) @binding(0) var t_height_map: texture_2d<f32>;
@group(1) @binding(1) var s_height_map: sampler;
@group(2) @binding(0) var t_color_map: texture_2d<f32>;
@group(2) @binding(1) var s_color_map: sampler;
@group(3) @binding(0) var frame: texture_storage_2d<rgba8unorm, read_write>;

@compute @workgroup_size(256)
fn render(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let x = i32(global_id.x);
    let j = i32(global_id.y);

    // Only run algorithm on every column (vertical scan lines) to save compute
    if (j == 0) {
        // Camera constants (scaled based off screen dimensions)
        let horizon = f32(camera.screen_height) / 4.0;
        let scale_factor = f32(camera.screen_height) * 1.2;
        let sinPhi = sin(camera.angle);
        let cosPhi = cos(camera.angle);
        let distance = 1500.0;
        var step_size = 0.2f;

        // Run algorithm on map
        let map_size = textureDimensions(t_height_map, 0).xy;
        var maximum_height = i32(camera.screen_height);

        for (var z = 0.2f; z < distance; z += step_size) {
            // Incremental step size (less level of detail with further distance)
            step_size += 0.005f;

            // Field of view scaling and rotation calculations
            let half_width = z * tan(camera.fov * 0.5);
            let pleft = vec2(
                -cosPhi * half_width - sinPhi * z + camera.p.x,
                sinPhi * half_width - cosPhi * z + camera.p.y
            );
            let pright = vec2(
                cosPhi * half_width - sinPhi * z + camera.p.x,
                -sinPhi * half_width - cosPhi * z + camera.p.y
            );

            let dx = (pright - pleft) / f32(camera.screen_width);
            var current = pleft + f32(x) * dx;

            // Normalize texture sampling coordinates to [0, 1.0]
            let map_uv = (current.xy / vec2<f32>(f32(map_size.x - 1u), f32(map_size.y - 1u)));
            let height_val = textureSampleLevel(t_height_map, s_height_map, map_uv, 0.0).r * 255;

            // Adjust height on screen based on camera constants like height and distance from camera (z value)
            let height_on_screen = ((camera.height - height_val) / z) * scale_factor + horizon;

            // Sample terrain color from color map
            let terrain_color = textureSampleLevel(t_color_map, s_color_map, map_uv, 0.0);

            for (var y = i32(height_on_screen); y < maximum_height; y = y + 1) {
                // Sample repeating texture for color and compute fog based of z distance (blends into sky with distance)
                let norm_y = (f32(y) / f32(camera.screen_height - 1u));
                let sky_color = vec4f(vec3f(0.3, 0.5, 1.0) * (1.0 - norm_y), 1.0);
                let fog = pow((distance - z) / distance, 0.5);
                let shaded_terrain = ((fog * terrain_color) + (1 - fog) * sky_color);

                textureStore(frame, vec2<i32>(x, y), shaded_terrain);
            }

            // Adjust maximum height
            if (i32(height_on_screen) < maximum_height) {
                maximum_height = i32(height_on_screen);
            }
        }

        // Draw a sky
        for (var y = 0; y < maximum_height; y = y + 1) {
            let norm_y = (f32(j) / f32(camera.screen_height - 1u));
            let sky_color = vec4f(vec3f(0.3, 0.5, 1.0) * (1.0 - norm_y), 1.0);
            textureStore(frame, vec2<i32>(x, y), sky_color);
        }

        // DrawVerticalLineGradient(x, 0.0, maximum_height, vec3f(0.3f, 0.5f, 1.0f), camera.screen_height);
    }
}

// fn DrawVerticalLine(x: i32, y_start: f32, y_end: i32, color: vec4<f32>) {
//     for (var y = i32(y_start); y < y_end; y = y + 1) {
//         textureStore(frame, vec2<i32>(x, y), color);
//     }
// }

// fn DrawVerticalLineGradient(x: i32, y_start: f32, y_end: i32, color: vec3<f32>, screen_height: u32) {
//     for (var y = i32(y_start); y < y_end; y = y + 1) {
//         var gradient_color = vec4f(vec3f(color * (1.0 - (f32(y) / f32(screen_height - 1u)))), 1.0);
//         textureStore(frame, vec2<i32>(x, y), gradient_color);
//     }
// }