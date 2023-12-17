#version 330 core

in vec2         v_texCoord;     // normalized texture coordinates
out vec4        fragColor;      // the output of the fragment shader 

// shadertoy variables

uniform vec3    iResolution;    // .xy viewport resolution, .z = 1.0 for square pixels

// shadertoy code starts here

vec4 circle (vec2 uv, vec2 pos, float radius, float blur)
{  
    float d = length(uv-pos);
    float c = 1.0 - smoothstep(radius-blur, radius, d);
    
    return vec4(c,c,c,1.0);
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
            
    vec4 col, face, smile;       
            
    face  = circle (uv, vec2(0.0, 0.0), 0.5, 0.0025);    
    face -= circle (uv, vec2(-0.23, 0.18), 0.085, 0.0025); // left eye
    face -= circle (uv, vec2( 0.23, 0.18), 0.085, 0.0025); // right eye
    face  = clamp (face, 0.0, 1.0) * vec4(1,1,0,1.0); // yellow
    
    smile  = circle (uv, vec2(0.0,-0.07), 0.32, 0.0025);
    smile -= circle (uv, vec2(0.0, 0.04), 0.34, 0.0025);
    smile  = clamp (smile, 0.0, 1.0);
    
    // subtracting will cut the the smile mask away from the face
    col = face - smile;
    
    fragColor = col;
}

void main () {   
  mainImage(fragColor, v_texCoord * iResolution.xy);  
}

