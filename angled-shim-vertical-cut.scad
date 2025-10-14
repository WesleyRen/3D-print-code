// =================== CONFIG ===================
standard     = "EU";   // "US" or "EU"

// Plate
plate_x      = 120;    // width (X)
plate_y      = 86;     // height (Y)
plate_z      = 5;      // thickness (Z)

// Junction-box standards
device_spacing_US = 83.3;  // mm (3.281")
device_spacing_EU = 60.0;  // mm (common EU round box)
device_hole_d_US  = 4.5;   // 6-32 clearance
device_hole_d_EU  = 4.0;   // M3–M3.5 clearance

use_slots    = true;       // oval slots for alignment wiggle
slot_play    = 4.0;        // slot length in the axis of spacing (mm)
cbore_d      = 8.0;        // counterbore diameter (pan/oval heads)
cbore_h      = 1.5;        // counterbore depth

// RJ45 cable cutout
cutout_w     = 16;         // width across the slot (perpendicular to travel)
round_r      = 3;          // corner radius of the tunnel

// US (slot travels along Y from the TOP edge toward center)
epsY_in      = 20;         // past center (Y direction)
epsY_out     = 0;          // outside beyond top edge

// EU (slot travels along X from the LEFT edge toward center)
epsX_in      = 20;         // past center (X direction)
epsX_out     = 0;          // outside beyond left edge

// Mouth rounding (small internal soften at the mouth edge)
lip_r        = 3.0;
lip_inset    = 1.0;        // how far inside the mouth edge to start the round

// =================== DERIVED ===================
isUS             = (standard == "US");
device_spacing   = isUS ? device_spacing_US : device_spacing_EU;
device_hole_d    = isUS ? device_hole_d_US  : device_hole_d_EU;

// Device screw positions: US along X, EU along Y
device_positions = isUS
  ? [ [ +device_spacing/2, 0 ],
      [ -device_spacing/2, 0 ] ]
  : [ [ 0,  +device_spacing/2 ],
      [ 0,  -device_spacing/2 ] ];

// =================== HELPERS ===================
// simple oval slots for screws
module slotX(d=4.0, len=4){
  hull(){
    translate([-len/2, 0, 0]) cylinder(h=plate_z+1, d=d, center=true, $fn=48);
    translate([+len/2, 0, 0]) cylinder(h=plate_z+1, d=d, center=true, $fn=48);
  }
}
module slotY(d=4.0, len=4){
  hull(){
    translate([0, -len/2, 0]) cylinder(h=plate_z+1, d=d, center=true, $fn=48);
    translate([0, +len/2, 0]) cylinder(h=plate_z+1, d=d, center=true, $fn=48);
  }
}

// robust 3D rounded slot made from a 2D rounded rectangle
module rounded_slot3d(len, wid, h, r){
  // len is travel direction, wid is transverse
  linear_extrude(height=h, center=true)
    offset(r=r)
      square([max(0.01,len-2*r), max(0.01,wid-2*r)], center=true);
}

// =================== MODEL ===================
difference(){
  // Base flat plate centered at origin
  translate([0,0, plate_z/2]) cube([plate_x, plate_y, plate_z], center=true);

  union(){
    // --- Junction-box holes/slots ---
    if (use_slots){
      for (p = device_positions)
        if (isUS)
          translate([p[0], p[1], plate_z/2]) slotX(d=device_hole_d, len=slot_play);
        else
          translate([p[0], p[1], plate_z/2]) slotY(d=device_hole_d, len=slot_play);
    } else {
      for (p = device_positions)
        translate([p[0], p[1], -0.5])
          cylinder(h=plate_z+1, d=device_hole_d, $fn=64);
    }

    // Counterbore for screw heads on top face
    for (p = device_positions)
      translate([p[0], p[1], plate_z - cbore_h])
        cylinder(h=cbore_h+0.01, d=cbore_d, $fn=64);

    // --- RJ45 cable cutout (centered through Z) ---
    cut_h = plate_z + 0.6;     // just exceed plate thickness
    cut_z = plate_z/2;         // center through Z

    if (isUS){
      // travels along Y from TOP edge
      y_top  = +plate_y/2;
      depthY = (plate_y/2 + epsY_in) + epsY_out;               // total travel along Y
      cy     = y_top - (( (plate_y/2 + epsY_in) - epsY_out )/2);

      translate([0, cy, cut_z])
        rounded_slot3d(depthY, cutout_w, cut_h, round_r);

      // small mouth soften at top edge
      mouth_y = y_top - lip_inset;
      for (sx = [-1, 1])
        translate([sx*(cutout_w/2 - 0.01), mouth_y, cut_z])
          cylinder(h=plate_z+0.6, r=lip_r, center=true, $fn=48);

    } else {
      // EU: travels along X from LEFT edge
      x_left = -plate_x/2 - 1;
      depthX = (plate_x/2 + epsX_in) + epsX_out;               // total travel along X
      cx     = x_left + epsX_out + depthX/2;

      translate([cx, 0, cut_z])
        // note: len=X depth, wid=slot width in Y
        rounded_slot3d(depthX, cutout_w, cut_h, round_r);

      // mouth soften at left edge
      mouth_x = x_left + lip_inset;
      for (sy = [-1, 1])
        translate([mouth_x, sy*(cutout_w/2 - 0.01), cut_z])
          cylinder(h=plate_z+0.6, r=lip_r, center=true, $fn=48);
    }
  }
}