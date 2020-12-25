import * as THREE from "three";
import fragment from "./shader/fragment.glsl";
import vertex from "./shader/vertex.glsl";
let OrbitControls = require("three-orbit-controls")(THREE);

import matcap from "../matcap_1.png";
import * as dat from "dat.gui";
import gsap from "gsap";

export default class Sketch {
  constructor(options) {
    this.scene = new THREE.Scene();

    this.container = options.dom;
    this.width = this.container.offsetWidth;
    this.height = this.container.offsetHeight;
    this.renderer = new THREE.WebGLRenderer();
    this.renderer.setPixelRatio(window.devicePixelRatio);
    this.renderer.setSize(this.width, this.height);
    this.renderer.setClearColor(0xeeeeee, 1);
    this.renderer.outputEncoding = THREE.sRGBEncoding;

    this.container.appendChild(this.renderer.domElement);

    // this.camera = new THREE.PerspectiveCamera(
    //   70,
    //   window.innerWidth / window.innerHeight,
    //   0.001,
    //   1000
    // );

    var frustumSize = 1;
    // var aspect = window.innerWidth / window.innerHeight;
    this.camera = new THREE.OrthographicCamera( frustumSize / - 2, frustumSize / 2, frustumSize / 2, frustumSize / - 2, -1000, 1000 );
    this.camera.position.set(0, 0, 2);
    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.time = 0;

    this.isPlaying = true;

    this.addObjects();
    this.resize();
    this.render();
    this.setupResize();
    this.mouseEvents();
    this.settings();
  }

  settings() {
    let that = this;
    this.settings = {
      progress: 0,
    };
    this.gui = new dat.GUI();
    this.gui.add(this.settings, "progress", 0, 1, 0.01);
  }

  setupResize() {
    window.addEventListener("resize", this.resize.bind(this));
  }

  resize() {
    this.width = this.container.offsetWidth;
    this.height = this.container.offsetHeight;
    this.renderer.setSize(this.width, this.height);
    this.camera.aspect = this.width / this.height;
    this.camera.updateProjectionMatrix();
  }

  addObjects() {

    let a1=1;
    let a2=1;

    if (this.height > this.width) {
        a1=this.width / this.height;
    } else {
        a2 = this.height / this.width;
    }

    const resolution = new THREE.Vector2(a1,a2);

    this.material = new THREE.ShaderMaterial({
      extensions: {
        derivatives: "#extension GL_OES_standard_derivatives : enable"
      },
      side: THREE.DoubleSide,
      uniforms: {
        time: { value: 0 },
        matcap: { value: new THREE.TextureLoader().load(matcap) },
        mouse: { value: new THREE.Vector2() },
        resolution: { value: resolution },
        progress: { value: 0 },
        uvRate1: {
          value: new THREE.Vector2(1, 1)
        }
      },
      // wireframe: true,
      // transparent: true,
      vertexShader: vertex,
      fragmentShader: fragment
    });

    this.geometry = new THREE.PlaneGeometry(1, 1, 1, 1);

    this.plane = new THREE.Mesh(this.geometry, this.material);
    this.scene.add(this.plane);
  }

  stop() {
    this.isPlaying = false;
  }

  play() {
    if(!this.isPlaying){
      this.render()
      this.isPlaying = true;
    }
  }

  render() {
    if (!this.isPlaying) return;
    this.time += 0.05;
    this.material.uniforms.time.value = this.time;
    this.material.uniforms.progress.value = this.settings.progress;
    if (this.mouse) {
        this.material.uniforms.mouse.value = this.mouse;
    }
    requestAnimationFrame(this.render.bind(this));
    this.renderer.render(this.scene, this.camera);
  }

  mouseEvents() {
    this.mouse = new THREE.Vector2()
    document.addEventListener("mousemove", (e)=> {
        // Mouse range from -1 to 1
        this.mouse.x = 2*(e.pageX/this.width -0.5);
        this.mouse.y = 2*(-e.pageY/this.height +0.5);
    })
  }
}

new Sketch({
  dom: document.getElementById("container")
});
