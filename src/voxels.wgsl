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

struct CameraUniform {
    p: vec2<f32>,
    height: f32,
    angle: f32,
    screen_width: u32,
    screen_height: u32,
};

@group(0) @binding(0)
var<uniform> camera: CameraUniform;
@group(1) @binding(0)
var t_height_map: texture_2d<f32>;
@group(1) @binding(1)
var s_height_map: sampler;
@group(2) @binding(0)
var t_color_map: texture_2d<f32>;
@group(2) @binding(1)
var s_color_map: sampler;

@fragment
fn fs_main(@builtin(position) pos: vec4f) -> @location(0) vec4<f32> {
    let horizon = f32(camera.screen_height / 2);
    let scale_factor = f32(camera.screen_height * 2);
    let sinPhi = sin(camera.angle);
    let cosPhi = cos(camera.angle);
    let distance = 1000.0;

    // Normalize coordinates to [0, 1.0]
    let uv = pos.xy / vec2f(f32(camera.screen_width - 1u), f32(camera.screen_height - 1u));
    var sky_color = vec4f(0.0, uv, 1.0);

    let map_size = textureDimensions(t_height_map, 0).xy;
    for (var z = 0.0; z < distance; z = z + 1.0) {
        // let half_width = z * tan(camera.fov * 0.5);  // Field of view scaling
        let half_width = z * tan(90 * 0.5);  // Field of view scaling

        let pleft = vec2(
            -cosPhi * half_width - sinPhi * z + camera.p.x,
            sinPhi * half_width - cosPhi * z + camera.p.y
        );
        let pright = vec2(
            cosPhi * half_width - sinPhi * z + camera.p.x,
            -sinPhi * half_width - cosPhi * z + camera.p.y
        );

        let dx = (pright - pleft) / f32(camera.screen_width);
        var current = pleft + (pos.x * 0.5 + 0.5) * dx;

        let map_uv = (current.xy / vec2<f32>(f32(map_size.x - 1u), f32(map_size.y - 1u)));
        let height_val = textureSample(t_height_map, s_height_map, map_uv).r;
        let height_on_screen = ((camera.height - (height_val * 255)) / z) * scale_factor + horizon;

        if (height_on_screen < pos.y) {
            let terrain_color = textureSample(t_color_map, s_height_map, map_uv);
            return terrain_color;
        }
    }

    return sky_color;
}
