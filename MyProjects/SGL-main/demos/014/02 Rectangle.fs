#version 330 core

in vec2         v_texCoord;     // normalized texture coordinates
out vec4        fragColor;      // the output of the fragment shader 

// shadertoy variables

uniform vec3    iResolution;    // .xy viewport resolution, .z = 1.0 for square pixels

// shadertoy code starts here

vec4 rect (vec2 uv, float xc, float yc, float w, float h, float blur)
{  
    vec4 col;
    float f1, f2, f3, f4;
    float f;
    
    // the four smoothsteps define the regions of space where the pixels will be on or off
    f1 = smoothstep(xc - w/2.0 - blur, xc - w/2.0 + blur, uv.x);
    f2 = smoothstep(xc + w/2.0 + blur, xc + w/2.0 - blur, uv.x);
    
    f3 = smoothstep(yc - h/2.0 - blur, yc - h/2.0 + blur, uv.y);
    f4 = smoothstep(yc + h/2.0 + blur, yc + h/2.0 - blur, uv.y);
    
    // this will merge the regions together
    f = f1 * f2 * f3 * f4;
    
    return vec4(f, f, f, 1.0);
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

void mainImage (out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = SetCoordinateSystem (fragCoord);
 
    vec4 col = rect (uv, 0.0, 0.0, 0.75, 0.75, 0.001);
    
    fragColor = col;
}


void main () {   
  mainImage(fragColor, v_texCoord * iResolution.xy);  
}
