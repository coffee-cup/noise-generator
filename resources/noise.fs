#version 330

#define OCTAVES 6

in vec2 fragTexCoord;
out vec4 finalColor;

uniform vec2 resolution;
uniform float noiseType;// 0.0 for random noise, 1.0 for Perlin noise
uniform float scale;// New uniform for scaling

// Improved hash function for better randomness
float hash(vec2 p){
  p=fract(p*vec2(123.34,456.21));
  p+=dot(p,p+45.32);
  return fract(p.x*p.y);
}

// Improved Perlin noise function
float perlinNoise(vec2 p){
  vec2 i=floor(p);
  vec2 f=fract(p);
  
  // Four corners in 2D of a tile
  float a=hash(i);
  float b=hash(i+vec2(1.,0.));
  float c=hash(i+vec2(0.,1.));
  float d=hash(i+vec2(1.,1.));
  
  // Smooth interpolation
  vec2 u=f*f*(3.-2.*f);
  
  // Mix 4 corners percentages
  return mix(a,b,u.x)+
  (c-a)*u.y*(1.-u.x)+
  (d-b)*u.x*u.y;
}

// Updated function: Fractal Brownian Motion (fBm) with normalization
float fbm(vec2 p){
  float value=0.;
  float amplitude=.5;
  float frequency=1.;
  float max_value=0.;
  
  // Use OCTAVES define for the loop
  for(int i=0;i<OCTAVES;i++){
    value+=amplitude*perlinNoise(p*frequency);
    max_value+=amplitude;
    frequency*=2.;
    amplitude*=.5;
  }
  
  // Normalize the result
  return value/max_value;
}

void main(){
  vec2 uv=gl_FragCoord.xy/resolution;
  float noise;
  
  if(noiseType<.5){
    // Random noise with proper scaling
    vec2 scaledUV=floor(uv*scale)/scale;
    noise=hash(scaledUV);
  }else{
    // More detailed Perlin noise using fBm
    noise=fbm(uv*20.);// Increased frequency for more detail
  }
  
  finalColor=vec4(vec3(noise),1.);
}
