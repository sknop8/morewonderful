uniform sampler2D tDiffuse;
uniform float u_amount;
varying vec2 f_uv;
uniform vec2 u_resolution;

bool inWindow(float xMin, float xMax, float yMin, float yMax)
{
  return (gl_FragCoord.x > xMin && gl_FragCoord.x < xMax && gl_FragCoord.y > yMin && gl_FragCoord.y < yMax);
}


const float numY = 2.0;
const float numX = 3.0;

void main() {
    vec4 col = vec4(1.0);

    // Dimensions of each window pane
    float dimX = u_resolution.x * 0.3;
    float dimY = u_resolution.y * 0.5;

    // Size of segment the browser is divided into
    float segX = u_resolution.x / numX;
    float segY = u_resolution.y / numY;

    // Space between panes
    float buffer = u_resolution.x * 0.01;

    // Show image if we're in a window
    for (float i = 1.0; i <= numX; i += 1.0)
    {
      for (float j = 1.0; j <= numY; j+= 1.0)
      {
        if (inWindow(segX * (i) + buffer + dimX / 2.0,
                     segX * (i + 1.0) - buffer + dimX / 2.0,
                     segY * (j) + buffer ,
                     segY * (j + 1.0 ) - buffer ))
        {
          col = texture2D(tDiffuse, f_uv);
        }
      }
    }

    gl_FragColor = col;

}
