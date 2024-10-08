#version 330

in vec2 fragTexCoord;
out vec4 finalColor;
uniform vec2 resolution;

// 0.0 for random noise, 1.0 for Perlin noise
uniform float noiseType;

uniform bool animate;
uniform float scale;
uniform int octaves;
uniform float persistence;
uniform float lacunarity;
uniform float frequency;
uniform float amplitude;
uniform float time;

float hash2(vec2 p){
  p=fract(p*vec2(123.34,456.21));
  p+=dot(p,p+45.32);
  return fract(p.x*p.y);
}

float perlinNoise(vec2 p){
  vec2 i=floor(p);
  vec2 f=fract(p);
  
  // Four corners in 2D of a tile
  float a=hash2(i);
  float b=hash2(i+vec2(1.,0.));
  float c=hash2(i+vec2(0.,1.));
  float d=hash2(i+vec2(1.,1.));
  
  // Smooth interpolation
  vec2 u=f*f*(3.-2.*f);
  
  // Mix 4 corners percentages
  return mix(a,b,u.x)+
  (c-a)*u.y*(1.-u.x)+
  (d-b)*u.x*u.y;
}

// Fractal Brownian Motion (fBm) with normalization
float fbm(vec2 p){
  float value=0.;
  float freq=frequency;
  float amp=amplitude;
  float max_value=0.;
  
  for(int i=0;i<octaves;i++){
    value+=amp*perlinNoise(p*freq);
    max_value+=amp;
    freq*=lacunarity;
    amp*=persistence;
  }
  
  // Normalize the result
  return value/max_value;
}

void main(){
  vec2 uv=gl_FragCoord.xy/resolution;
  float noise;
  
  if(noiseType<.5){
    noise=hash2(uv*scale);
  }else{
    vec2 p=uv*scale;
    if(animate){
      p+=time;
    }
    noise=fbm(p);
  }
  
  finalColor=vec4(vec3(noise),1.);
}
