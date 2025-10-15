// --- EAP615-Wall wedge spacer (single piece, prints flat) ---
plate_x   = 120;
plate_y   = 86;
thin_z    = 1;
tilt_deg  = 20;
flip_tilt = false;

// device/yoke mount (US)
device_spacing = 83.3;
use_slots      = true;
slot_play_x    = 4;
device_hole_d  = 4.5;
cbore_d        = 8;
cbore_h        = 1.5;

// cable cutout (RJ45 access)
cutout_w      = 16;
cutout_h      = 33;
cutout_offset = 0;
round_r       = 3;
epsY_in       = 20;
epsY_out = 0;   // was 1.0

// mouth rounding
lip_r         = 3.0;
lip_inset     = 1.0;  // how far INSIDE thick edge to start rounding

thick_z = thin_z + plate_y * tan(tilt_deg);
echo("Computed thin_z =", thin_z, "mm");
echo("Computed thick_z =", thick_z, "mm");

module wedge_block(){
  y_thin  =  flip_tilt ?  plate_y/2 : -plate_y/2;
  y_thick = !flip_tilt ?  plate_y/2 : -plate_y/2;
  hull(){
    translate([0, y_thin,  thin_z/2])  cube([plate_x, 0.1, thin_z],  center=true);
    translate([0, y_thick, thick_z/2]) cube([plate_x, 0.1, thick_z], center=true);
    translate([0, 0, 0]) cube([plate_x, plate_y, 0.001], center=true);
  }
}

module rounded_box(x, y, z, r){
  r2 = min(r, min(x,y)/2);
  if (r2 <= 0) cube([x,y,z], center=true);
  else minkowski(){
    cube([x-2*r2, y-2*r2, z], center=true);
    cylinder(r=r2, h=0.001, $fn=48);
  }
}

module slotX(d=4.5, len=4){
  hull(){
    translate([-len/2, 0, 0]) cylinder(h=thick_z+1, d=d, center=true, $fn=48);
    translate([+len/2, 0, 0]) cylinder(h=thick_z+1, d=d, center=true, $fn=48);
  }
}

// device screw positions (aligned along X)
device_positions = [
  [ +device_spacing/2, 0 ],
  [ -device_spacing/2, 0 ]
];

difference(){
  wedge_block();

  union(){

    // device slots
    if (use_slots){
      for (p = device_positions)
        translate([p[0], p[1], thick_z/2]) slotX(d=device_hole_d, len=slot_play_x);
    } else {
      for (p = device_positions)
        translate([p[0], p[1], -0.5])
          cylinder(h=thick_z+1, d=device_hole_d, $fn=64);
    }

    // counterbore
    for (p = device_positions)
      translate([p[0], p[1], thick_z - cbore_h])
        cylinder(h=cbore_h+0.01, d=cbore_d, $fn=64);

    // RJ45 cable cutout
    y_thick_edge = (!flip_tilt ?  plate_y/2 + 2 : -plate_y/2 - 2);
    dir          = (!flip_tilt ? 1 : -1);
    L_in         = plate_y/2 + epsY_in;
    L_out        = epsY_out;
    cutout_depth = L_in + L_out;
    cut_y        = y_thick_edge - dir * ((L_in - L_out)/2.0);
    cut_z        = thick_z - cutout_h/2;

    translate([cutout_offset, cut_y, cut_z])
      rounded_box(cutout_w, cutout_depth, cutout_h, round_r);
    
    

    // --- fixed: subtle internal round-over at slot mouth ---
    mouth_y = (!flip_tilt ?  plate_y/2 - lip_inset : -plate_y/2 + lip_inset);
    for (sx = [-1, 1])
      translate([
        cutout_offset + sx*(cutout_w/2 - 0.01),
        mouth_y,
        thick_z - cutout_h/2
      ])
        cylinder(h=cutout_h, r=lip_r, center=true, $fn=64);

  }
}