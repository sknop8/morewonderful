"use strict"
require("babel-core/register");
require("babel-polyfill");

const THREE = require('three');
import EffectComposer, { RenderPass, ShaderPass, CopyShader } from 'three-effectcomposer-es6'
import Framework from './framework'
import Audio from './audio'
// import Sparkle from './postprocessing/sparkle'
import Rainbow from './postprocessing/rainbow'
import Window from './postprocessing/window'

var clock = new THREE.Clock(false);

var scene
var camera
var renderer
var directionalLight
var video, image, imageContext, imageReflection, imageReflectionContext, imageReflectionGradient,
  texture, textureReflection

var composer
var allPost = [ Rainbow, Window ]
var currentPost = []

var audioControl = { 'mute': false };

function onLoad(framework) {
  scene = framework.scene;
  camera = framework.camera;
  renderer = framework.renderer;
  var gui = framework.gui;
  var stats = framework.stats;

  directionalLight = new THREE.DirectionalLight( 0xffffff, 1 );
  directionalLight.color.setHSL(0.1, 1, 0.95);
  directionalLight.position.set(1, 5, 2);
  directionalLight.position.multiplyScalar(10);
  scene.add(directionalLight);

  scene.background = new THREE.Color(1, 1, 1)

  camera.position.set(0, 0, -10);
  camera.lookAt(new THREE.Vector3(0, 0, camera.position.z - 20));
  camera.updateProjectionMatrix();

  Audio.init();

  if (audioControl.mute) Audio.mute()

  gui.add(audioControl, 'mute').onChange(function(newVal) {
    if (newVal) { Audio.mute() } else { Audio.unmute() }
  })

  currentPost = [ Rainbow, Window ]
  setPostProcessing()

  var width = window.innerWidth,
      height = window.innerHeight

  Rainbow.shader.material.uniforms.u_resolution.value = new THREE.Vector2(width, height)
  Window.shader.material.uniforms.u_resolution.value = new THREE.Vector2(width, height)

  camera.position.z = 1000;

  // Embed the video as a texture onto a plane in the scene
  image = document.createElement('canvas');
  image.width = 1920;
  image.height = 1080;

  imageContext = image.getContext('2d');
  imageContext.fillStyle = '#000000';
  imageContext.fillRect(0, 0, 1920, 1080);

  video = document.getElementById('video');
  video.playbackRate = 6.5;

  texture = new THREE.Texture(video);
  texture.minFilter = THREE.NearestFilter;
  texture.magFilter = THREE.NearestFilter;
  texture.format = THREE.RGBFormat;
  texture.wrapS = THREE.ClampToEdgeWrapping;
  texture.wrapT = THREE.ClampToEdgeWrapping;

  var material = new THREE.MeshBasicMaterial({
      map: texture,
      overdraw: true
  });
  var plane = new THREE.PlaneGeometry(1280, 768, 4, 4);
  var mesh = new THREE.Mesh(plane, material);
  scene.add(mesh);

  clock.start()
}

function setPostProcessing(shaders) {
  for (var s in allPost) { allPost[s].turnOff() }
  composer = new EffectComposer(renderer)
  var renderPass = new RenderPass(scene, camera);
  renderPass.renderToScreen = false;
  composer.addPass(renderPass)

  for (var s in currentPost) {
    currentPost[s].turnOn();
    var pass = currentPost[s].shader

    // Only set the last pass to render to screen
    pass.renderToScreen = (s == currentPost.length - 1);

    composer.addPass(pass);
  }

  render()
}

function render() {
  requestAnimationFrame(render)
  composer.render()

camera.lookAt(scene.position);
  if (video && video.readyState === video.HAVE_ENOUGH_DATA) {
    imageContext.drawImage(video, 0, 0);
    if (texture) texture.needsUpdate = true;
  }
}

function cosine_interp(a, b, t) {
  var cos_t = (1 - Math.cos(t * Math.PI)) * 0.5
  return a * (1 - cos_t) + b * cos_t
}

function onUpdate(framework) {
  clock.getDelta()
  var time = clock.elapsedTime

  if (Audio.isPlaying()) {
    // Only start the video once the auto is on
    video.play()

    var size = Audio.getSizeFromSound()
    Rainbow.shader.material.uniforms.u_size.value = size

    var bpm = Audio.getRateFromSound()
    Rainbow.shader.material.uniforms.u_bpm.value = bpm ? bpm : 60
  }

  Rainbow.shader.material.uniforms.u_time.value = time

  var width = window.innerWidth,
      height = window.innerHeight

  Rainbow.shader.material.uniforms.u_resolution.value = new THREE.Vector2(width, height)
  Window.shader.material.uniforms.u_resolution.value = new THREE.Vector2(width, height)
}

Framework.init(onLoad, onUpdate);
