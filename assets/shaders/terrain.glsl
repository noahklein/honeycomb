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

void main() {
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;

    vPos = vertexPosition;

    gl_Position = mvp * vec4(vPos, 1);
}

#type fragment
#version 330 core

in vec3 vPos;
in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

void main() {
    vec4 texelColor = fragColor * texture(texture0, fragTexCoord);
    finalColor = texelColor*colDiffuse;
}