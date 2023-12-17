#version 330 core

// attributes of the vertex
layout (location = 0) in vec4 position;
layout (location = 1) in vec2 texCoord;

uniform mat4 u_projection;

void main () {
 gl_Position = u_projection * position;
}
