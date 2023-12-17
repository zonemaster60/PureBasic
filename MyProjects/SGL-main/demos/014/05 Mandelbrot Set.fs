#version 330 core

in vec2         v_texCoord;     // normalized texture coordinates
out vec4        fragColor;      // the output of the fragment shader 

// shadertoy variables

uniform vec3    iResolution;    // .xy viewport resolution, .z = 1.0 for square pixels

// shadertoy code starts here

#define MAX_STEPS 64

int mandelbrot (vec2 uv) {
    vec2 z = uv;
    for (int i = 0; i < MAX_STEPS; i++) {        
        if (length(z) > 2.0) return i;       
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + uv;
    }
    return 0;
}

vec2 SetCoordinateSystem (vec2 fragCoord)
{
    // normalize pixel coordinates to UV coords
    vec2 uv = fragCoord / iResolution.xy * 2.5;
    
    // put the set roughly at the center
    uv.y -= 1.25;
    uv.x -= 1.65;
    
    // corrects for aspect ratio
    uv.x *= (iResolution.x / iResolution.y);
            
    return uv;
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{

    vec2 uv = SetCoordinateSystem(fragCoord);
    
    float ret = float(mandelbrot(uv));
    
    ret /= float(MAX_STEPS);
    
    float r = ret;
    float g = ret;
    float b = ret;
        
    fragColor = vec4(r, g, b, 1.0);
}

void main () {   
  mainImage(fragColor, v_texCoord * iResolution.xy);  
}
