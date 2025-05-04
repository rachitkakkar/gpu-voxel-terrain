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
