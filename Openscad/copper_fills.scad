radius=100;
width=20;
spacing=5;
top=0;
bottom=0;
edge=1;
edge_width=1;
if(top==1){
difference(){
circle(r=radius+width/2);
circle(r=radius-width/2);
translate([0,radius,0])square([0.1,radius],center=true);
}
circle(r=radius-width/2-spacing);
}
else if(bottom==1){
circle(r=radius+width/2);
}
else if(edge==1){
difference(){
circle(r=radius+width/2);
circle(r=radius+width/2-edge_width);
translate([0,radius,0])square([0.1,radius],center=true);
}
}
