// Previous attempts

// Render to a texture with compute shader
struct Point {
    x: f32,
    y: f32,
};

struct Uniforms {
    p: vec2<f32>,
    height: f32,
    horizon: f32,
    scale_height: f32,
    distance: i32,
    screen_width: i32,
    screen_height: i32,
};

@group(0) @binding(0) var<uniform> uniforms: Uniforms;
@group(0) @binding(1) var heightmap: texture_2d<f32>;
@group(0) @binding(2) var colormap: texture_2d<f32>;
@group(0) @binding(3) var outputTex: texture_storage_2d<rgba8unorm, write>;

@compute @workgroup_size(1)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let i = i32(global_id.x);
    let z_start = uniforms.distance;
    let z_end = 1;

    for (var z = z_start; z > z_end; z = z - 1) {
        let pleft = vec2<f32>(-f32(z) + uniforms.p.x, -f32(z) + uniforms.p.y);
        let pright = vec2<f32>(f32(z) + uniforms.p.x, -f32(z) + uniforms.p.y);

        let dx = (pright.x - pleft.x) / f32(uniforms.screen_width);
        var current = pleft + vec2<f32>(f32(i) * dx, 0.0);

        let height_val = textureLoad(heightmap, vec2<i32>(i32(current.x), i32(current.y)), 0).r;
        let height_on_screen = ((uniforms.height - height_val) / f32(z)) * uniforms.scale_height + uniforms.horizon;

        let color = textureLoad(colormap, vec2<i32>(i32(current.x), i32(current.y)), 0);
        DrawVerticalLine(i, height_on_screen, uniforms.screen_height, color);
    }
}

fn DrawVerticalLine(x: i32, y_start: f32, y_end: i32, color: vec4<f32>) {
    for (var y = i32(y_start); y < y_end; y = y + 1) {
        textureStore(outputTex, vec2<i32>(x, y), color);
    }
}

// Camera experiments

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let horizon = f32(camera.screen_height) / 2.0;
    let scale_factor = f32(camera.screen_height) * 2.0;

    let sinPhi = sin(camera.angle);
    let cosPhi = cos(camera.angle);

    let forward = vec2<f32>(cosPhi, sinPhi);
    let right = vec2<f32>(-sinPhi, cosPhi); // Perpendicular to forward

    let distance = 1000.0;

    let uv = in.pos.xy / vec2<f32>(f32(camera.screen_width), f32(camera.screen_height)) + 0.5;
    var color = vec4<f32>(0.5 * uv.y, 0.7 * uv.y, 1.0, 1.0);

    let map_size = vec2<f32>(textureDimensions(t_height_map, 0));

    // Screen x in range [-0.5, 0.5]
    let screen_x = (in.pos.x / f32(camera.screen_width)) - 0.5;

    for (var z = distance; z > 1.0; z = z - 0.5) {
        // Ray direction for this column: forward + offset * right
        let world_pos = camera.p + forward * z + right * (screen_x * z);
        let map_uv = world_pos / (map_size - vec2<f32>(1.0));

        let height_val = textureSample(t_height_map, s_height_map, map_uv).r * 255.0;
        let height_on_screen = ((camera.height - height_val) / z) * scale_factor + horizon;

        if (height_on_screen < in.pos.y) {
            color = textureSample(t_color_map, s_color_map, map_uv);
        }
    }

    return color;
}