#version 330 core

// attributes of the vertex
layout (location = 0) in vec4 position;
layout (location = 1) in vec2 texCoord;

uniform mat4    projection;

out vec2 v_texCoord;

void main () {
 gl_Position = projection * position;
 v_texCoord = texCoord;
}
