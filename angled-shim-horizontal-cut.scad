// --- EAP615-Wall wedge spacer (single piece, prints flat) ---
plate_x   = 120;     // X width (mm)
plate_y   = 86;      // Y depth (mm) – slope runs along Y
thin_z    = 5;       // thin edge (mm)
tilt_deg  = 7;       // wedge angle (deg)
flip_tilt = false;   // true => thick edge at +Y

// device/yoke mount (US)
device_spacing = 83.3;  // mm
use_slots      = true;  // oval slots for wiggle
slot_play_x    = 4;     // slot length along X (mm)
device_hole_d  = 4.5;   // clearance for 6-32
cbore_d        = 8;     // counterbore diameter
cbore_h        = 1.5;   // counterbore depth

// cable cutout (thick Z face → past center, plus small outside bleed)
cutout_w      = 16;    // X width
cutout_h      = 20;    // Z height at thick face
cutout_offset = 0;     // X shift
round_r       = 3;
epsY_in       = 20;    // inward past center (mm)
epsY_out      = 1.0;   // outward beyond thick edge (mm)

thick_z = thin_z + plate_y * tan(tilt_deg);
echo("Computed thin_z =", thin_z, "mm");
echo("Computed thick_z =", thick_z, "mm");

// ---------------- geometry helpers ----------------
module wedge_block(){
  y_thin  =  flip_tilt ?  plate_y/2 : -plate_y/2;
  y_thick = !flip_tilt ?  plate_y/2 : -plate_y/2;
  hull(){
    translate([0, y_thin,  thin_z/2])  cube([plate_x, 0.1, thin_z],  center=true);
    translate([0, y_thick, thick_z/2]) cube([plate_x, 0.1, thick_z], center=true);
    translate([0, 0, 0])               cube([plate_x, plate_y, 0.001], center=true);
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

// ---------------- MODEL ----------------
difference(){
  wedge_block();

  // subtract all cutters together
  union(){

    // device through-holes / slots
    if (use_slots){
      for (p = device_positions)
        translate([p[0], p[1], thick_z/2]) slotX(d=device_hole_d, len=slot_play_x);
    } else {
      for (p = device_positions)
        translate([p[0], p[1], -0.5]) cylinder(h=thick_z+1, d=device_hole_d, $fn=64);
    }

    // counterbore on thick face
    for (p = device_positions)
      translate([p[0], p[1], thick_z - cbore_h])
        cylinder(h=cbore_h+0.01, d=cbore_d, $fn=64);

    // cable cutout on THICK Z face, running along Y toward/through center
    y_thick_edge = (!flip_tilt ?  plate_y/2 : -plate_y/2);
    dir          = (!flip_tilt ? 1 : -1);
    L_in         = plate_y/2 + epsY_in;   // toward center
    L_out        = epsY_out;              // outside edge
    cutout_depth = L_in + L_out;
    cut_y        = y_thick_edge - dir * ((L_in - L_out)/2.0);
    cut_z        = thick_z - cutout_h/2;  // at thick face

    translate([cutout_offset, cut_y, cut_z])
      rounded_box(cutout_w, cutout_depth, cutout_h, round_r);
  }
}