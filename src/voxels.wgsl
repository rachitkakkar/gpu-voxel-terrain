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

@compute @workgroup_size(1)
fn render(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let i = i32(global_id.x);
    let j = i32(global_id.y);

    // Only run algorithm on every column (vertical scan lines) to save compute
    if (j == 0) {
        // Camera constants (scaled based off screen dimensions)
        let horizon = f32(camera.screen_height) / 4.0;
        let scale_factor = f32(camera.screen_height) * 1.2;
        let sinPhi = sin(camera.angle);
        let cosPhi = cos(camera.angle);
        let distance = 1200.0;

        // Run algorithm on map
        let map_size = textureDimensions(t_height_map, 0).xy;
        for (var z = 0.2; z < distance; z += 1.0) {
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
            var current = pleft + f32(i) * dx;

            // Normalize texture sampling coordinates to [0, 1.0] and sample repeating texture for height
            // Edit: As of converting to a compute shader, the textureSample function is no longer available (textureLoad is used instead) 
            //       and the normalization step is no longer performed
            // let map_uv = (current.xy / vec2<f32>(f32(map_size.x - 1u), f32(map_size.y - 1u)));

            let tex_size = textureDimensions(t_height_map, 0); // vec2<u32>
            let wrapped_coords = vec2<i32>(
                (i32(current.x) % i32(tex_size.x) + i32(tex_size.x)) % i32(tex_size.x),
                (i32(current.y) % i32(tex_size.y) + i32(tex_size.y)) % i32(tex_size.y)
            );
            let height_val = textureLoad(t_height_map, wrapped_coords, 0).r * 255; 

            // Adjust height on screen based on camera constants like height and distance from camera (z value)
            let height_on_screen = ((camera.height - height_val) / z) * scale_factor + horizon;

            let terrain_color = textureLoad(t_color_map, wrapped_coords, 0);
            DrawVerticalLine(i, height_on_screen, i32(camera.screen_height), terrain_color);
        }
    }
}

fn DrawVerticalLine(x: i32, y_start: f32, y_end: i32, color: vec4<f32>) {
    for (var y = i32(y_start); y < y_end; y = y + 1) {
        textureStore(frame, vec2<i32>(x, y), color);
    }
}