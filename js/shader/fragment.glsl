uniform float time;
uniform vec2 resolution;
varying vec2 vUv;
float PI = 3.141592653589793238;
float THRESHOLD = 0.0001;
// Distance from camera, when you know for sure that there is no hit
float MARCHING_MAX = 5.;

float sdSphere(vec3 point, float radius) {
    return length(point) - radius;
}

// Our aim is to find a sphere with radius 0.5
float distToTarget(vec3 point) {
    return sdSphere(point, 0.4);
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
    vec3 colour = vec3(0.);
    if(marchedDistance < MARCHING_MAX) {
        vec3 normal = calcNormal(ray*marchedDistance+cameraPosition);
        float diff = dot(vec3(1.), normal);
        colour = vec3(diff);
    }

	gl_FragColor = vec4(colour, 1.);
}
