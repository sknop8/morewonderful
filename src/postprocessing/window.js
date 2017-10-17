const THREE = require('three');
import { ShaderPass } from 'three-effectcomposer-es6'

var on = false;
function turnOn() { on = true }
function turnOff() { on = false }
function isOn() { return on }

var shader = new ShaderPass({
    uniforms: {
        tDiffuse: { type: 't', value: null },
        u_amount: { type: 'f', value: 1.0 },
        u_resolution: { type: '2fv', value: new THREE.Vector2() }
    },
    vertexShader: require('../shaders/vert.glsl'),
    fragmentShader: require('../shaders/window-frag.glsl')
});

export default {
  shader: shader,
  turnOn: turnOn,
  turnOff: turnOff,
  isOn: isOn
}
