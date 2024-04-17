#type vertex
#version 330 core

in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;

uniform mat4 mvp;

out vec2 fragTexCoord;
out vec4 fragColor;

out vec3 vPos;
out vec4 vColor;

void main() {
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;

    vPos = vertexPosition;

    gl_Position = mvp * vec4(vPos, 1);
}

#type fragment
#version 330 core

in vec3 vPos;
in vec4 fragColor;

out vec4 finalColor;

void main() {
    finalColor = fragColor;
}