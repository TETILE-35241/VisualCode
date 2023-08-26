// ==UserScript==
// @name        Bromus for Kirka.io
// @namespace   Bromus
// @version     1.0
// @description Aimbot and Wallhack for Kirka.io
// @author      Bromus
// @icon        https://www.google.com/s2/favicons?sz=64&domain_url=kirka.io
// @grant       none
// @run-at      document-start
// @require     https://cdn.jsdelivr.net/npm/three@0.155.0/build/three.min.js#sha256-ec0a84377f1dce9d55b98f04ac7057376fa5371c33ab1cd907b85ae5f18fab7e
// @require     https://cdn.jsdelivr.net/npm/three-mesh-bvh@0.6.3/build/index.umd.cjs#sha256-4781a92a7e9b459164f7f1c4a78f14664ced5d853626640ce3f0aac4d01daf10
// @match       https://kirka.io/*
// ==/UserScript==

(() => {
  // src/core/utils/dom.ts
  function createElement(parent, tagName) {
    const elem = document.createElement(tagName);
    parent.appendChild(elem);
    return elem;
  }

  // src/core/Module.ts
  var Module = class {
    constructor(key, name, description) {
      this.key = key;
      this.name = name;
      this.description = description;
      this.key = this.key.toUpperCase();
    }
    state;
    onGameEnter() {
    }
    onGameExit() {
    }
    onTick() {
    }
    onKeyDown(event) {
    }
    onKeyUp(event) {
    }
    onMouseDown(event) {
    }
    onMouseUp(event) {
    }
  };

  // src/core/utils/format.ts
  function joinOxfordComma(items) {
    switch (items.length) {
      case 0:
        return "";
      case 1:
        return items[0];
      case 2:
        return `${items[0]} and ${items[1]}`;
      default:
        return `${items.slice(0, items.length - 1).join(", ")}, and ${items[items.length - 1]}`;
    }
  }

  // src/core/modules/ToggleModule.ts
  var ToggleModule = class extends Module {
    constructor(key, name, description, modes, defaultModeIndex = 0) {
      super(key, name, description);
      this.modes = modes;
      this.defaultModeIndex = defaultModeIndex;
      this.currentModeIndex = defaultModeIndex;
    }
    currentModeIndex;
    onKeyDown(event) {
      super.onKeyDown(event);
      if (event.key.toUpperCase() === this.key) {
        this.currentModeIndex = (this.currentModeIndex + 1) % this.modes.length;
        this.onModeChange();
      }
    }
    onModeChange() {
    }
    getCurrentMode() {
      return this.modes[this.currentModeIndex];
    }
    isEnabled() {
      return this.currentModeIndex > 0;
    }
    getMenuItem() {
      return `[${this.key}] ${this.name}: ${this.getCurrentMode()}`;
    }
    getDocumentation() {
      return `**${this.name} (toggle key: ${this.key}, modes: ${joinOxfordComma(this.modes.map((mode, i) => i === this.defaultModeIndex ? `${mode} (default)` : mode))})**: ${this.description}`;
    }
  };

  // src/core/modules/MenuModule.ts
  var MenuModule = class extends ToggleModule {
    constructor(key, position, modules) {
      super(key, "Menu", "Displays the status of all features.", ["Off", "On"], 1);
      this.position = position;
      this.modules = modules;
    }
    container = void 0;
    activationKeys = void 0;
    onGameEnter() {
      super.onGameEnter();
      if (this.container === void 0) {
        this.container = this.state.widgets.createWidget(this.position);
        this.activationKeys = new Set(this.modules.map((module) => module.key));
      }
      if (this.isEnabled()) {
        this.setVisible(true);
        this.updateMenu();
      } else {
        this.setVisible(false);
      }
    }
    onModeChange() {
      super.onModeChange();
      if (this.isEnabled()) {
        this.setVisible(true);
        this.updateMenu();
      } else {
        this.setVisible(false);
      }
    }
    onKeyDown(event) {
      super.onKeyDown(event);
      if (this.isEnabled() && this.activationKeys.has(event.key.toUpperCase())) {
        this.updateMenu();
      }
    }
    onKeyUp(event) {
      super.onKeyUp(event);
      if (this.isEnabled() && this.activationKeys.has(event.key.toUpperCase())) {
        this.updateMenu();
      }
    }
    updateMenu() {
      this.container.innerHTML = "";
      this.appendLine(`Bromus ${GM.info.script.version}`, 18, "white");
      for (const module of this.modules) {
        this.appendLine(module.getMenuItem(), 16, module.isEnabled() ? "green" : "red");
      }
    }
    appendLine(text, size, color) {
      const div = createElement(this.container, "div");
      div.textContent = text;
      div.style.fontSize = `${size}px`;
      div.style.color = color;
    }
    setVisible(visible) {
      this.container.style.display = visible ? "block" : "none";
    }
  };

  // src/core/WidgetContainer.ts
  var WidgetContainer = class {
    element;
    constructor() {
      this.element = createElement(document.body, "div");
      this.element.style.zIndex = "2147483647";
      this.element.style.width = "100vw";
      this.element.style.height = "100vh";
      this.setVisible(false);
    }
    setVisible(visible) {
      this.element.style.display = visible ? "block" : "none";
    }
    createWidget(position) {
      const div = createElement(this.element, "div");
      div.style.position = "absolute";
      div.style.left = position.left;
      div.style.right = position.right;
      div.style.top = position.top;
      div.style.bottom = position.bottom;
      div.style.zIndex = "2147483647";
      div.style.padding = "4px";
      div.style.backgroundColor = "rgba(0, 0, 0, 0.8)";
      div.style.fontFamily = "monospace";
      return div;
    }
  };

  // src/core/Script.ts
  var Script = class {
    constructor(websiteName, iconDomain, requires, matchPatterns, changelog, modules, state, menuKey, menuPosition) {
      this.websiteName = websiteName;
      this.iconDomain = iconDomain;
      this.requires = requires;
      this.matchPatterns = matchPatterns;
      this.changelog = changelog;
      this.modules = modules;
      this.state = state;
      const menuModule = new MenuModule(menuKey, menuPosition, modules);
      modules.push(menuModule);
      for (const module of modules) {
        module.state = this.state;
      }
    }
    inGame = false;
    init() {
      this.state.widgets = new WidgetContainer();
      document.addEventListener("keydown", (event) => {
        this.onKeyDown(event);
      });
      document.addEventListener("keyup", (event) => {
        this.onKeyUp(event);
      });
      document.addEventListener("mousedown", (event) => {
        this.onMouseDown(event);
      });
      document.addEventListener("mouseup", (event) => {
        this.onMouseUp(event);
      });
      this.setUp();
    }
    onGameEnter() {
      if (this.inGame) {
        this.onGameExit();
      }
      this.inGame = true;
      this.state.widgets.setVisible(true);
      for (const module of this.modules) {
        module.onGameEnter();
      }
    }
    onGameExit() {
      this.inGame = false;
      this.state.widgets.setVisible(false);
      for (const module of this.modules) {
        module.onGameExit();
      }
    }
    onTick() {
      if (!this.inGame) {
        return;
      }
      for (const module of this.modules) {
        if (module.isEnabled()) {
          module.onTick();
        }
      }
    }
    onKeyDown(event) {
      if (this.shouldSkipEvent(event)) {
        return;
      }
      for (const module of this.modules) {
        module.onKeyDown(event);
      }
    }
    onKeyUp(event) {
      if (this.shouldSkipEvent(event)) {
        return;
      }
      for (const module of this.modules) {
        module.onKeyUp(event);
      }
    }
    onMouseDown(event) {
      if (this.shouldSkipEvent(event)) {
        return;
      }
      for (const module of this.modules) {
        module.onMouseDown(event);
      }
    }
    onMouseUp(event) {
      if (this.shouldSkipEvent(event)) {
        return;
      }
      for (const module of this.modules) {
        module.onMouseUp(event);
      }
    }
    shouldSkipEvent(event) {
      if (!this.inGame) {
        return true;
      }
      const tagName = event.target.tagName;
      return tagName === "INPUT" || tagName === "TEXTAREA" || tagName === "A" || tagName === "BUTTON";
    }
  };

  // src/core/utils/hook.ts
  function hookApply(obj, prop, callback) {
    obj[prop] = new Proxy(obj[prop], {
      apply(target, thisArg, args) {
        const value = callback(...args);
        return value !== void 0 ? value : Reflect.apply(target, thisArg, args);
      }
    });
  }

  // src/core/State.ts
  var State = class {
    widgets;
  };

  // src/scripts/kirka/KirkaState.ts
  var KirkaState = class extends State {
    THREE;
    MeshBVHLib;
    game;
    scene;
    camera;
    me;
    players;
    entityManager;
    getOtherPlayers() {
      return this.scene.children.filter((v) => v.type === "Group");
    }
    getOpponents() {
      const otherPlayers = this.getOtherPlayers();
      if (this.me.team === void 0) {
        return otherPlayers;
      }
      return otherPlayers.filter((p) => p.entity.colyseusObject.team !== this.me.team);
    }
    getComponent(id) {
      return this.entityManager._entities.filter((e) => e._components[id]).map((e) => e._components[id])[0];
    }
  };

  // src/scripts/kirka/modules/AimbotModule.ts
  var AimbotModule = class extends ToggleModule {
    holdingRMB = false;
    constructor() {
      super(
        "V",
        "Aimbot",
        "Automatically aims at the nearest attackable player. In **Always** mode it always aims automatically, in **RMB** mode only when the right mouse button is held down. Works best when you're standing still while shooting.",
        ["Off", "Always", "RMB"]
      );
    }
    onMouseDown(event) {
      super.onMouseDown(event);
      if (event.button === 2) {
        this.holdingRMB = true;
      }
    }
    onMouseUp(event) {
      super.onMouseUp(event);
      if (event.button === 2) {
        this.holdingRMB = false;
      }
    }
    onGameEnter() {
      super.onGameEnter();
      const chunks = this.state.scene.children.filter((c) => c.type === "Mesh");
      for (const chunk of chunks) {
        chunk.geometry.boundingBox = null;
        chunk.geometry.boundsTree = void 0;
      }
      this.currentModeIndex = 0;
    }
    onTick() {
      super.onTick();
      if (this.getCurrentMode() === "RMB" && !this.holdingRMB) {
        return;
      }
      const { Vector3 } = this.state.THREE;
      const myPosition = this.state.me.pos;
      const cameraPosition = new Vector3(myPosition.x, myPosition.y, myPosition.z).add(this.state.camera.position);
      const targets = this.state.getOpponents().filter((p) => p.entity.colyseusObject.isAlive).map((p) => new Vector3().copy(p.position).add(p.children[1].position)).sort((a, b) => cameraPosition.distanceToSquared(a) - cameraPosition.distanceToSquared(b));
      for (const target of targets) {
        if (!this.isVisible(cameraPosition, target)) {
          continue;
        }
        const directionVector = new Vector3().subVectors(cameraPosition, target).normalize();
        const cameraControl = this.state.getComponent(44);
        cameraControl.x = Math.asin(-directionVector.y);
        cameraControl.y = Math.atan2(directionVector.x, directionVector.z);
        cameraControl.deltaX = 0;
        cameraControl.deltaY = 0;
        break;
      }
    }
    isVisible(camera, target) {
      const { Raycaster, Vector3 } = this.state.THREE;
      const { MeshBVH, acceleratedRaycast } = this.state.MeshBVHLib;
      Vector3.prototype.mWwnNTo = Vector3.prototype.distanceTo;
      const direction = new Vector3().subVectors(target, camera).normalize();
      const far = new Vector3().subVectors(target, camera).length();
      const raycaster = new Raycaster(camera, direction, 0, far);
      raycaster.firstHitOnly = true;
      const chunks = this.state.scene.children.filter((c) => c.type === "Mesh");
      for (const chunk of chunks) {
        if (chunk.geometry.boundingBox === null) {
          chunk.geometry.computeBoundingBox();
        }
        if (chunk.geometry.boundsTree === void 0) {
          chunk.geometry.boundsTree = new MeshBVH(chunk.geometry);
        }
        chunk.matrixWorld = chunk.wnNWMm;
        const chunkPrototype = Object.getPrototypeOf(chunk);
        const originalRaycast = chunkPrototype.raycast;
        chunkPrototype.raycast = acceleratedRaycast;
        const intersections = raycaster.intersectObject(chunk, false).length;
        chunk.matrixWorld = void 0;
        chunkPrototype.raycast = originalRaycast;
        if (intersections > 0) {
          return false;
        }
      }
      return true;
    }
  };

  // src/scripts/kirka/modules/WallhackModule.ts
  var WallhackModule = class extends ToggleModule {
    constructor() {
      super(
        "B",
        "Wallhack",
        "Displays other players through walls. In **All** mode it displays all other players through walls, in **Opps** mode only opponents.",
        ["Off", "All", "Opps"]
      );
    }
    onModeChange() {
      super.onModeChange();
      if (this.isEnabled()) {
        this.update();
      } else {
        for (const player of this.state.getOtherPlayers()) {
          this.setVisible(player, false);
        }
      }
    }
    onTick() {
      super.onTick();
      this.update();
    }
    update() {
      const allPlayers = this.state.getOtherPlayers();
      let toShow;
      if (this.getCurrentMode() === "All") {
        toShow = new Set(allPlayers.map((p) => p.entity.id));
      } else {
        toShow = new Set(this.state.getOpponents().map((p) => p.entity.id));
      }
      for (const player of allPlayers) {
        this.setVisible(player, toShow.has(player.entity.id));
      }
    }
    setVisible(player, visible) {
      const material = player.children[0].children[0].children[1].material;
      material.fog = !visible;
      material.alphaTest = visible ? 0.99 : 1;
      material.depthTest = !visible;
    }
  };

  // src/scripts/kirka/KirkaScript.ts
  var KirkaScript = class extends Script {
    constructor() {
      super(
        "Kirka.io",
        "kirka.io",
        [
          "https://cdn.jsdelivr.net/npm/three@0.155.0/build/three.min.js#sha256-ec0a84377f1dce9d55b98f04ac7057376fa5371c33ab1cd907b85ae5f18fab7e",
          "https://cdn.jsdelivr.net/npm/three-mesh-bvh@0.6.3/build/index.umd.cjs#sha256-4781a92a7e9b459164f7f1c4a78f14664ced5d853626640ce3f0aac4d01daf10"
        ],
        ["https://kirka.io/*"],
        [
          {
            version: "1.0",
            date: "TODO",
            changes: ["Initial public release."]
          }
        ],
        [new AimbotModule(), new WallhackModule()],
        new KirkaState(),
        "N",
        { right: "0", bottom: "50%" }
      );
    }
    setUp() {
      this.state.THREE = window.THREE;
      delete window.THREE;
      this.state.MeshBVHLib = window.MeshBVHLib;
      delete window.MeshBVHLib;
      hookApply(WeakMap.prototype, "set", (key) => {
        if (key.type === "Scene" && key.children.length > 1) {
          this.state.scene = key;
        }
      });
      hookApply(window, "requestAnimationFrame", () => {
        this.onTick();
      });
      this.state.players = {};
      hookApply(Object, "defineProperty", (obj, key) => {
        if (key === "fov" && obj.wnWmN) {
          this.state.me = obj.wnWmN;
        } else if (key === "isAlive") {
          this.state.players[obj.name] = obj;
        } else if (key === "filmGauge" && obj.position.y > 0) {
          this.state.camera = obj;
        } else if (key === "client") {
          this.state.game = obj;
        } else if (key === "_entityManager") {
          this.state.entityManager = obj._entityManager;
        }
      });
      let previousHasGameInterface = false;
      setInterval(() => {
        const hasGameInterface = document.querySelector(".game-interface") !== null;
        if (hasGameInterface !== previousHasGameInterface) {
          if (hasGameInterface) {
            this.onGameEnter();
          } else {
            this.onGameExit();
          }
          previousHasGameInterface = hasGameInterface;
        }
      }, 100);
    }
  };

  // <stdin>
  var script = new KirkaScript();
  script.init();
})();













