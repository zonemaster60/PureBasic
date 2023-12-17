#version 330 core

in vec2         v_texCoord;     // normalized texture coordinates
out vec4        fragColor;      // the output of the fragment shader 

// shadertoy variables

uniform vec3    iResolution;    // .xy viewport resolution, .z = 1.0 for square pixels

// shadertoy code starts here

#define S(edge1, edge2, value) smoothstep(edge1, edge2, value)  // smoothstep
#define B(source1, source2, mixing) mix(source1, source2, mixing) // blend
#define NUV(uv, rect) NormalizeUV(uv, rect) // normalize set of coordinates to 0.0-1.0

float MapToZeroOne (float low, float high, float value)
{
 return clamp((value - low) / (high - low), 0.0, 1.0);
}

float MapToRange (float low, float high, float new_low, float new_high, float value)
{
 return clamp(new_low + (value - low) * (new_high - new_low) / (high - low), new_low, new_high);
}

vec2 NormalizeUV (vec2 uv, vec4 rect) {
 return (uv-rect.xy)/(rect.zw-rect.xy);
}

vec4 Brow (vec2 uv)
{
 uv -= 0.5; // center the local uv
 
 // push down the eyebrows
 uv.y += uv.x * 0.75;
 uv.x -= 0.1;
 
 vec4 col = vec4(0.0);
    
 float blur = .1;
  
 float d1 = length(uv);
 float s1 = S(.45, .45-blur, d1);
 float d2 = length(uv-vec2(.1, -.2)*.7);
 float s2 = S(.5, .5-blur, d2);
    
 float browMask = clamp(s1-s2, 0.0, 1.0);
    
 float colMask = MapToZeroOne(.7, .8, uv.y)*.75;
 
 colMask *= S(.6, .9, browMask);
    
 vec4 browCol = mix(vec4(.4, .2, .2, 1.), vec4(1., .75, .5, 1.), colMask); 
 col = mix(col, browCol, S(.2, .4, browMask));
    
 return col;
}   

vec4 Eye (vec2 uv, float side)
{
 uv -= 0.5; // center the local uv
 uv.x *= side;
 
 vec4 col;
 vec4 whiteCol = vec4 (1.0, 1.0, 1.0, 1.0); // white
 vec4 irisCol = vec4(0.2, 0.5, 1.0, 1.0); // blue
 
 float d = length(uv);
 
 // turn the white circle into a white-blueish
 col = B(whiteCol, irisCol, S(0.0, 0.5, d) * 0.3); 
  
 // hilite bottom of the eye
 col *= 1.0 - S(0.45, 0.5, d) * clamp(-uv.y - uv.x, 0.0, 1.0);
 
 // iris
 irisCol.rgb *= 1.0 + S(0.35, 0.1, d);
 
 // outline black
 col = B(col, vec4(0.0), S(0.29, 0.28, d));
 col = B(col, irisCol, S(0.27, 0.26, d));

 // pupil
 col = B(col, vec4(0.0), S(0.16, 0.14, d));
 
 
 // hilite reflexes
 float hilite = S(0.08, 0.07,  length(uv - vec2(0.1, 0.1))); 
 col = B(col, vec4(1.0), hilite);
 hilite = S(0.04, 0.03,  length(uv - vec2(-0.1, -0.1))); 
 col = B(col, vec4(1.0), hilite);

 col.a = S(0.5, 0.45, d); // modifiy the alpha to cut the eye circle
 
 return col;
}

vec4 Smile (vec2 uv)
{
 uv -= 0.5; // center the local uv
 
 vec4 col = vec4 (0.5, 0.18, 0.0, 1.0); 
 
 // tongue
 vec4 tongueCol = vec4(1.0, 0.5, 0.4, 1.0);
 float td2 = length(uv - vec2(0.0, 0.7)); 
 col = B(col, tongueCol, S(0.5, 0.44, td2));

 uv.y += uv.x * uv.x * 1.7;
 
 float d = length(uv); // mouth
 
 vec4 teethCol = vec4(1.0); 
 teethCol *=  S(0.5, 0.44, d); // shadow on teeth
 
 float td1 = length(uv - vec2(0.0, -0.5)); // teeth
 col = B(col, teethCol, S(0.4, 0.38, td1));
  
 col.a = S(0.50, 0.48, d); // modifiy the alpha to cut the mouth 
 
 return col;
}

vec4 Head (vec2 uv)
{
 vec4 col = vec4 (0.9, 0.6, 0.1, 1.0); // orange
    
 float d = length(uv);
 float r = 0.5;
    
 // modify the alpha to make a circle with alpha = 1 from the whole orange screen
 col.a = S(r, r - 0.001, d);
 
 // we got an edge around the circle going for 0 to 1 after x = 0.35
 float edgeShading = MapToZeroOne (0.35, 0.5, d);
    
 // this is to make it less linear and more parabolic 
 edgeShading *= edgeShading;
    
 // now the egde is tapering off
 col.rgb *= 1.0 - edgeShading * 0.25;
 
 // thin outline around the head
 col.rgb = B(col.rgb, vec3(0.9, 0.3, 0.0), S(0.49, 0.50, d));
    
 // highlight on the upper part of the head
    
 // a white circle 
 float msk_hilite = S(0.41, 0.40, d);
    
 // but with its intensity reduced toward the center
 msk_hilite *= MapToRange (-0.1, 0.41, 0.0, 0.75, uv.y);
    
 // we mix it with all the rest
 col.rgb = B(col.rgb, vec3(1.0), msk_hilite);
    
 // we create the cheeks, with a little offset from the center
 float dc = length (uv - vec2(0.25, -0.22));
 float msk_cheek = S(0.2, 0.05, dc) * 0.3;
 
 dc = length (uv - vec2(-0.25, -0.22));
 msk_cheek += S(0.2, 0.05, dc) * 0.3;
        
 // we mix it with all the rest
 col.rgb = B(col.rgb, vec3(1.0, 0.1, 0.1), msk_cheek);
   
 return vec4(col);
}

vec4 Smiley (vec2 uv)
{
 float side = sign(uv.x);
 
 uv.x = abs(uv.x);
     
 vec4 col = vec4(0.0); // black background
      
 vec4 head_col = Head(uv); // get color with alpha from Head()
    
 vec4 eye_col = Eye(NUV(uv, vec4(0.03, -0.08, 0.36, 0.25)), side); // inside a virtual box

 vec4 brow_col = Brow(NUV(uv, vec4( 0.03, 0.1, 0.42, 0.38))); // inside a virtual box    

 // blend Smiley() starting color with Head() using alpha
 col = B(col, head_col, head_col.a);
   
 // blend Eye() using alpha
 col = B(col, eye_col, eye_col.a);
 
 // blend Brow() using alpha
 col = B(col, brow_col, brow_col.a);

 // blend Smile() using alpha
 vec4 mouth_col = Smile(NUV(uv, vec4(-0.30, -0.18, 0.30, -0.44))); // inside a virtual box
 
 col = B(col, mouth_col, mouth_col.a);
 
 return col; // the final color
}

vec2 SetCoordinateSystem (vec2 fragCoord)
{
 // normalize pixel coordinates to UV coords
 vec2 uv = fragCoord / iResolution.xy;
    
 // put origin (0,0) to center
 uv -= 0.5;
    
 // corrects for aspect ratio
 uv.x *= (iResolution.x / iResolution.y);
            
 return uv;
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
 vec2 uv = SetCoordinateSystem (fragCoord);
    
 vec4 col = Smiley (uv);
    
 fragColor = col;    
}

void main () {   
  mainImage(fragColor, v_texCoord * iResolution.xy);  
}
