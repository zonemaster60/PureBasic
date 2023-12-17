#version 330 core

in vec2         v_texCoord;     // normalized texture coordinates
out vec4        fragColor;      // the output of the fragment shader 

// shadertoy variables

uniform vec3    iResolution;    // .xy viewport resolution, .z = 1.0 for square pixels

// shadertoy code starts here

#define AA 1

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    
    float ratio = iResolution.x / iResolution.y;
        
    uv -= 0.5;
    
    uv.x *= ratio;
    
    float r = 0.5;
    float d = length(uv); // we are going to compare this to the radius
    float col;
    
    #if AA == 1
        col = 1.0 - smoothstep(r-0.005, r, d);
    #else
        col = (d > r) ? 0.0 : 1.0;    
    #endif
    
    fragColor = vec4(col, col, col, 1.0);       
}


void main () {   
  mainImage(fragColor, v_texCoord * iResolution.xy);  
}
