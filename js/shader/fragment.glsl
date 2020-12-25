uniform float time;
uniform float progress;
uniform vec2 resolution;
uniform vec2 mouse;
uniform sampler2D matcap;
varying vec2 vUv;
float PI = 3.141592653589793238;
float THRESHOLD = 0.0001;
// Distance from camera, when you know for sure that there is no hit
float MARCHING_MAX = 5.;

mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
	mat4 m = rotationMatrix(axis, angle);
	return (m * vec4(v, 1.0)).xyz;
}

vec2 getMatcap(vec3 eye, vec3 normal) {
  vec3 reflected = reflect(eye, normal);
  float m = 2.8284271247461903 * sqrt( reflected.z+1.0 );
  return reflected.xy / m + 0.5;
}

// polynomial smooth min (k = 0.1);
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}



float sdSphere(vec3 point, float radius) {
    return length(point) - radius;
}

float sdBox( vec3 point, vec3 b) {
    vec3 q = abs(point) - b;
    return length(max(q,0.)) + min(max(q.x, max(q.y,q.z)),0.);
}

// Our aim is to find a sphere with radius 0.4
float distToTarget(vec3 point) {
    vec3 rotatedPoint = rotate(point, vec3(1.), time/5.);

    float distToPlainBox = sdBox(rotatedPoint, vec3(0.2));
    float distToSphereMain = sdSphere(rotatedPoint, 0.2);
    float distToRoundedBox = smin(distToPlainBox, distToSphereMain, 0.2);
    float distToBox = mix(distToRoundedBox, distToSphereMain, progress );

    float distToSphere = sdSphere(point - vec3(mouse*resolution, 0.), 0.1);

    return smin(distToBox, distToSphere, 0.1);
}

// Calculate normal vector for any point on a surface (https://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm)
vec3 calcNormal( in vec3 p ) // for function f(p)
{
    const float eps = 0.0001; // or some other value
    const vec2 h = vec2(eps,0);
    return normalize( vec3(distToTarget(p+h.xyy) - distToTarget(p-h.xyy),
                           distToTarget(p+h.yxy) - distToTarget(p-h.yxy),
                           distToTarget(p+h.yyx) - distToTarget(p-h.yyx) ) );
}

void main()	{
    // Background
    float dist = length(vUv - vec2(0.5));
    vec3 bg = mix(vec3(0.3), vec3(0.), dist);

    // UV of display grid
	vec2 displayUV = (vUv - vec2(0.5))*resolution;

    vec3 cameraPosition = vec3(0.,0.,2.);

    // Ray direction
    vec3 ray = normalize(vec3(displayUV,-1.));

    // Raymarching step one
    vec3 rayPosition = cameraPosition;

    float marchedDistance = 0.;

    for(int i=0; i<256; i++) {
        vec3 currentPosition = cameraPosition + marchedDistance * ray;
        float distToTarget = distToTarget(currentPosition);
        if(distToTarget<THRESHOLD || marchedDistance>MARCHING_MAX) break;
        marchedDistance+= distToTarget;
    }

    // Colour indication for pixels, that hit the target
    vec3 colour = bg;
    if(marchedDistance < MARCHING_MAX) {
        vec3 normal = calcNormal(ray*marchedDistance+cameraPosition);
        float diff = dot(vec3(1.), normal);
        vec2 matcapUV = getMatcap(ray, normal);
        colour = texture2D(matcap, matcapUV).xyz;

        float fresnel = pow(1. + dot(ray,normal), 3.);
        // colour = vec3(fresnel);

        colour = mix(colour,bg,fresnel);
    }

	gl_FragColor = vec4(colour, 1.);
}
