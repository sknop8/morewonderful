const THREE = require('three')
import { analyze, guess } from 'web-audio-beat-detector';
import pitchHelper from './pitchHelper'
var playing = false
var context
var sourceNode
var gainNode
var analyser
var splitter
var tempo

function init() {
  if (! window.AudioContext) { // check if the default naming is enabled, if not use the chrome one.
      if (! window.webkitAudioContext) alert('no audiocontext found')
      window.AudioContext = window.webkitAudioContext
  }
  context = new AudioContext()
  setupAudioNodes()
  loadSound("audio/morewonderful.mp3")
}

function loadSound(url) {
  var request = new XMLHttpRequest()
  request.open('GET', url, true)
  request.responseType = 'arraybuffer'
  request.onload = function() {
    context.decodeAudioData(request.response, function(buffer) {
      playSound(buffer)
    }, (e) => {console.log(e)})
  }
  request.send()
}

function playSound(buffer) {
  sourceNode.buffer = buffer
  sourceNode.loop = true
  sourceNode.start(0)
  playing = true
}

function stopSound() {
  sourceNode.stop()
  playing = false
}

function mute() { gainNode.gain.value = 0 }

function unmute() { gainNode.gain.value = 1 }

function isPlaying() { return playing }

function setupAudioNodes() {
  sourceNode = context.createBufferSource()
  // sourceNode.connect(context.destination);

  // jsNode = context.createScriptProcessor(2048, 1, 1); //ScriptProcessorNode

  analyser = context.createAnalyser()
  analyser.smoothingTimeConstant = 0.3
  analyser.fftSize = 2048

  // splitter = context.createChannelSplitter(); // splits into left and right stream

  sourceNode.connect(analyser)

  gainNode = context.createGain()
  sourceNode.connect(gainNode)
  gainNode.connect(context.destination)
}

function getAverageVolume(array) {
   var values = 0
   for (var i = 0; i < array.length; i++) { values += array[i] }
   return values / array.length
}

// Calculated based on the volume / amplitude
function getSizeFromSound() {
  var arr =  new Uint8Array(analyser.frequencyBinCount)
  analyser.getByteFrequencyData(arr)
  return getAverageVolume(arr)
}


function detectPitch() {
	var buffer = new Uint8Array(analyser.fftSize)
	analyser.getByteTimeDomainData(buffer)

	var fundFreq = pitchHelper.findFundamentalFreq(buffer, context.sampleRate)

	if (fundFreq) return fundFreq
}

function colorChange(c1, c2, hi, lo) {
  var dr = Math.abs(c1.r - c2.r)
  var dg = Math.abs(c1.g - c2.g)
  var db = Math.abs(c1.b - c2.b)
  return (dr < hi) & (dr > lo) & (dg < hi) & (dg > lo) & (db < hi) & (db > lo)
}

// Returns a new color based on the given color
// Calculated based on the pitch of the audio
function getColorFromSound(oldColor) {
  var color = oldColor
    var pitch = detectPitch()
    if (pitch) {
      var hex = Math.floor(pitch).toString(16)
      hex = ("000" + hex).substr(-3)
      color = new THREE.Color("#" + hex)

      var brt = 0.6   // Brightness
      var lgt = 0.4   // Lightness
      var i   = 0.1   // Lerp index
      var hi  = 1.0   // Color change upper bound
      var lo  = 0.0   // Color change lower bound
      var red = 0.1
      var yel = 0.01

      color.r = ((1 - i) * oldColor.r + i * color.r) * brt + lgt
      color.g = ((1 - i) * oldColor.g + i * color.g) * brt + lgt
      color.b = ((1 - i) * oldColor.b + i * color.b) * brt + lgt

      color.r += red
      color.b -= yel

      if (!colorChange(oldColor, color, hi, lo)) {
        color = oldColor
      }
    }
  return color;
}

// Detects the bpm and returns it (tempo)
// Only needs to be called once per song
function detectBeat() {
  analyze(sourceNode.buffer)
    .then( (tmp) => {
        // console.log("Tempo: "  + tmp)
        tempo = tmp
        return tmp
    })
    .catch((err) => { console.log(err) })
}

function getRateFromSound() {
  if (!tempo) return detectBeat()
  return tempo
}


export default {
  init: init,
  mute: mute,
  unmute: unmute,
  isPlaying: isPlaying,
  getSizeFromSound: getSizeFromSound,
  getColorFromSound: getColorFromSound,
  getRateFromSound: getRateFromSound
}
