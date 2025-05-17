use gpu_voxel_terrain::run;

fn main() {
    pollster::block_on(run());
}