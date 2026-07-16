<template>
    <article class="building-scene">
        <header class="building-scene__header">
            <div>
                <p>Interactive digital twin</p>
                <h3>3D building visualization</h3>
            </div>

            <div class="building-scene__controls" aria-label="3D scene controls">
                <button
                    type="button"
                    :class="{ 'building-scene__control--active': environment === 'day' }"
                    @click="environment = 'day'"
                >
                    ☀ Day
                </button>

                <button
                    type="button"
                    :class="{ 'building-scene__control--active': environment === 'night' }"
                    @click="environment = 'night'"
                >
                    ◐ Night
                </button>

                <button
                    type="button"
                    :class="{ 'building-scene__control--active': autoRotate }"
                    @click="autoRotate = !autoRotate"
                >
                    ↻ Auto rotate
                </button>

                <button type="button" @click="resetCamera">
                    Reset view
                </button>
            </div>
        </header>

        <div class="building-scene__content">
            <div class="building-scene__viewport">
                <canvas
                    ref="canvasRef"
                    class="building-scene__canvas"
                    aria-label="Navigable three-dimensional building model"
                    @pointerdown="handlePointerDown"
                    @pointermove="handlePointerMove"
                    @pointerup="handlePointerUp"
                    @pointercancel="handlePointerUp"
                    @wheel.prevent="handleWheel"
                ></canvas>

                <div class="building-scene__hint">
                    <span>Drag to orbit</span>
                    <span>Scroll to zoom</span>
                </div>

                <div class="building-scene__compass" aria-hidden="true">
                    <span>N</span>
                    <i></i>
                </div>

                <div v-if="webglError" class="building-scene__error">
                    <strong>3D view unavailable</strong>
                    <p>{{ webglError }}</p>
                </div>
            </div>

            <aside class="building-scene__floors-panel">
                <div class="building-scene__panel-heading">
                    <div>
                        <p>Scene levels</p>
                        <h4>Building floors</h4>
                    </div>

                    <span>{{ normalizedFloorCount }}</span>
                </div>

                <button
                    v-for="(floor, index) in floors"
                    :key="String(floor.id)"
                    class="building-scene__floor-button"
                    :class="{
                        'building-scene__floor-button--selected':
                            selectedFloorId === String(floor.id),
                        'building-scene__floor-button--attention':
                            getAttentionCount(floor) > 0
                    }"
                    type="button"
                    @mouseenter="hoveredFloorIndex = index"
                    @mouseleave="hoveredFloorIndex = null"
                    @focus="hoveredFloorIndex = index"
                    @blur="hoveredFloorIndex = null"
                    @click="selectFloor(floor, index)"
                >
                    <span class="building-scene__floor-number">
                        {{ index + 1 }}
                    </span>

                    <span class="building-scene__floor-copy">
                        <strong>{{ floor.name }}</strong>
                        <small>
                            {{ floor.devices.length }}
                            {{ floor.devices.length === 1 ? 'device' : 'devices' }}
                        </small>
                    </span>

                    <span
                        class="building-scene__floor-status"
                        :class="{
                            'building-scene__floor-status--healthy':
                                getAttentionCount(floor) === 0
                        }"
                    >
                        {{
                            getAttentionCount(floor) === 0
                                ? 'Operational'
                                : `${getAttentionCount(floor)} alert${getAttentionCount(floor) === 1 ? '' : 's'}`
                        }}
                    </span>
                </button>

                <div v-if="floors.length === 0" class="building-scene__empty">
                    Fleet Manager groups will appear here as building floors.
                </div>

                <div class="building-scene__legend">
                    <span><i class="building-scene__legend-dot building-scene__legend-dot--healthy"></i> Operational</span>
                    <span><i class="building-scene__legend-dot building-scene__legend-dot--attention"></i> Requires attention</span>
                </div>
            </aside>
        </div>
    </article>
</template>

<script setup lang="ts">
import {
    computed,
    nextTick,
    onBeforeUnmount,
    onMounted,
    ref,
    watch
} from 'vue';

import type { Floor } from '../../models/Floor';

const props = defineProps<{
    floors: Floor[];
}>();

const emit = defineEmits<{
    'select-floor': [floor: Floor];
}>();

const canvasRef = ref<HTMLCanvasElement | null>(null);
const environment = ref<'day' | 'night'>('night');
const autoRotate = ref(false);
const hoveredFloorIndex = ref<number | null>(null);
const selectedFloorId = ref<string | null>(null);
const webglError = ref<string | null>(null);

const normalizedFloorCount = computed(() => {
    return Math.max(props.floors.length, 1);
});

let gl: WebGLRenderingContext | null = null;
let program: WebGLProgram | null = null;
let positionBuffer: WebGLBuffer | null = null;
let normalBuffer: WebGLBuffer | null = null;
let resizeObserver: ResizeObserver | null = null;
let animationFrame = 0;
let previousTimestamp = 0;

let yaw = -0.72;
let pitch = 0.48;
let distance = 15.5;
let pointerId: number | null = null;
let previousPointerX = 0;
let previousPointerY = 0;

const CUBE_VERTEX_COUNT = 36;

const cubePositions = new Float32Array([
    -1, -1,  1,  1, -1,  1,  1,  1,  1,
    -1, -1,  1,  1,  1,  1, -1,  1,  1,
     1, -1, -1, -1, -1, -1, -1,  1, -1,
     1, -1, -1, -1,  1, -1,  1,  1, -1,
    -1,  1,  1,  1,  1,  1,  1,  1, -1,
    -1,  1,  1,  1,  1, -1, -1,  1, -1,
    -1, -1, -1,  1, -1, -1,  1, -1,  1,
    -1, -1, -1,  1, -1,  1, -1, -1,  1,
     1, -1,  1,  1, -1, -1,  1,  1, -1,
     1, -1,  1,  1,  1, -1,  1,  1,  1,
    -1, -1, -1, -1, -1,  1, -1,  1,  1,
    -1, -1, -1, -1,  1,  1, -1,  1, -1
]);

const cubeNormals = new Float32Array([
     0,  0,  1,  0,  0,  1,  0,  0,  1,
     0,  0,  1,  0,  0,  1,  0,  0,  1,
     0,  0, -1,  0,  0, -1,  0,  0, -1,
     0,  0, -1,  0,  0, -1,  0,  0, -1,
     0,  1,  0,  0,  1,  0,  0,  1,  0,
     0,  1,  0,  0,  1,  0,  0,  1,  0,
     0, -1,  0,  0, -1,  0,  0, -1,  0,
     0, -1,  0,  0, -1,  0,  0, -1,  0,
     1,  0,  0,  1,  0,  0,  1,  0,  0,
     1,  0,  0,  1,  0,  0,  1,  0,  0,
    -1,  0,  0, -1,  0,  0, -1,  0,  0,
    -1,  0,  0, -1,  0,  0, -1,  0,  0
]);

const vertexShaderSource = `
    attribute vec3 a_position;
    attribute vec3 a_normal;

    uniform mat4 u_viewProjection;
    uniform mat4 u_model;

    varying vec3 v_normal;
    varying vec3 v_worldPosition;

    void main() {
        vec4 worldPosition = u_model * vec4(a_position, 1.0);
        gl_Position = u_viewProjection * worldPosition;
        v_worldPosition = worldPosition.xyz;
        v_normal = normalize(mat3(u_model) * a_normal);
    }
`;

const fragmentShaderSource = `
    precision mediump float;

    uniform vec3 u_color;
    uniform vec3 u_lightDirection;
    uniform vec3 u_ambientColor;
    uniform float u_emissive;

    varying vec3 v_normal;
    varying vec3 v_worldPosition;

    void main() {
        float diffuse = max(dot(normalize(v_normal), normalize(u_lightDirection)), 0.0);
        float heightGlow = clamp((v_worldPosition.y + 2.0) / 12.0, 0.0, 1.0);
        vec3 lit = u_color * (u_ambientColor + diffuse * 0.72);
        lit += u_color * u_emissive * (0.65 + heightGlow * 0.35);
        gl_FragColor = vec4(lit, 1.0);
    }
`;

onMounted(async () => {
    await nextTick();
    initializeWebGL();
});

onBeforeUnmount(() => {
    cancelAnimationFrame(animationFrame);
    resizeObserver?.disconnect();
});

watch(
    () => props.floors.length,
    () => {
        selectedFloorId.value = null;
    }
);

function initializeWebGL(): void {
    const canvas = canvasRef.value;

    if (!canvas) {
        return;
    }

    gl = canvas.getContext('webgl', {
        antialias: true,
        alpha: false,
        depth: true
    });

    if (!gl) {
        webglError.value = 'Your browser or graphics driver does not expose WebGL.';
        return;
    }

    try {
        program = createProgram(gl, vertexShaderSource, fragmentShaderSource);
        positionBuffer = gl.createBuffer();
        normalBuffer = gl.createBuffer();

        if (!positionBuffer || !normalBuffer) {
            throw new Error('Unable to allocate 3D geometry buffers.');
        }

        gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
        gl.bufferData(gl.ARRAY_BUFFER, cubePositions, gl.STATIC_DRAW);

        gl.bindBuffer(gl.ARRAY_BUFFER, normalBuffer);
        gl.bufferData(gl.ARRAY_BUFFER, cubeNormals, gl.STATIC_DRAW);

        gl.enable(gl.DEPTH_TEST);
        gl.enable(gl.CULL_FACE);
        gl.cullFace(gl.BACK);

        resizeObserver = new ResizeObserver(() => resizeCanvas());
        resizeObserver.observe(canvas);
        resizeCanvas();
        animationFrame = requestAnimationFrame(renderScene);
    } catch (error) {
        webglError.value = error instanceof Error
            ? error.message
            : 'The 3D scene could not be initialized.';
    }
}

function resizeCanvas(): void {
    const canvas = canvasRef.value;

    if (!canvas || !gl) {
        return;
    }

    const pixelRatio = Math.min(window.devicePixelRatio || 1, 2);
    const width = Math.max(1, Math.floor(canvas.clientWidth * pixelRatio));
    const height = Math.max(1, Math.floor(canvas.clientHeight * pixelRatio));

    if (canvas.width !== width || canvas.height !== height) {
        canvas.width = width;
        canvas.height = height;
    }

    gl.viewport(0, 0, width, height);
}

function renderScene(timestamp: number): void {
    if (!gl || !program || !canvasRef.value) {
        return;
    }

    const delta = previousTimestamp === 0
        ? 0
        : Math.min((timestamp - previousTimestamp) / 1000, 0.05);
    previousTimestamp = timestamp;

    if (autoRotate.value && pointerId === null) {
        yaw += delta * 0.22;
    }

    const isNight = environment.value === 'night';
    const clearColor = isNight
        ? [0.018, 0.043, 0.085]
        : [0.73, 0.84, 0.94];

    gl.clearColor(clearColor[0], clearColor[1], clearColor[2], 1);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.useProgram(program);

    bindGeometry();

    const aspect = canvasRef.value.width / Math.max(canvasRef.value.height, 1);
    const floorCount = normalizedFloorCount.value;
    const targetY = floorCount * 0.82;
    const eye = [
        Math.sin(yaw) * Math.cos(pitch) * distance,
        targetY + Math.sin(pitch) * distance,
        Math.cos(yaw) * Math.cos(pitch) * distance
    ];

    const projection = perspectiveMatrix(Math.PI / 4.1, aspect, 0.1, 100);
    const view = lookAtMatrix(eye, [0, targetY, 0], [0, 1, 0]);
    const viewProjection = multiplyMatrices(projection, view);

    const viewProjectionLocation = gl.getUniformLocation(program, 'u_viewProjection');
    gl.uniformMatrix4fv(viewProjectionLocation, false, viewProjection);

    const lightDirection = isNight
        ? [0.35, 0.92, 0.4]
        : [-0.45, 0.9, 0.25];
    const ambient = isNight
        ? [0.22, 0.27, 0.4]
        : [0.52, 0.56, 0.62];

    gl.uniform3fv(gl.getUniformLocation(program, 'u_lightDirection'), lightDirection);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_ambientColor'), ambient);

    drawGround(isNight);
    drawBuilding(floorCount, isNight);

    animationFrame = requestAnimationFrame(renderScene);
}

function bindGeometry(): void {
    if (!gl || !program || !positionBuffer || !normalBuffer) {
        return;
    }

    const positionLocation = gl.getAttribLocation(program, 'a_position');
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    gl.enableVertexAttribArray(positionLocation);
    gl.vertexAttribPointer(positionLocation, 3, gl.FLOAT, false, 0, 0);

    const normalLocation = gl.getAttribLocation(program, 'a_normal');
    gl.bindBuffer(gl.ARRAY_BUFFER, normalBuffer);
    gl.enableVertexAttribArray(normalLocation);
    gl.vertexAttribPointer(normalLocation, 3, gl.FLOAT, false, 0, 0);
}

function drawGround(isNight: boolean): void {
    drawBox(
        [0, -0.45, 0],
        [8.2, 0.18, 7.2],
        isNight ? [0.055, 0.12, 0.16] : [0.28, 0.48, 0.38],
        0
    );

    drawBox(
        [0, -0.2, 0],
        [5.15, 0.12, 3.9],
        isNight ? [0.11, 0.15, 0.22] : [0.45, 0.48, 0.5],
        0
    );
}

function drawBuilding(floorCount: number, isNight: boolean): void {
    const floorHeight = 1.55;
    const floorGap = 0.13;

    for (let index = 0; index < floorCount; index += 1) {
        const floor = props.floors[index];
        const attention = floor ? getAttentionCount(floor) : 0;
        const isHovered = hoveredFloorIndex.value === index;
        const isSelected = floor && selectedFloorId.value === String(floor.id);
        const y = index * (floorHeight + floorGap) + floorHeight / 2;

        let bodyColor: [number, number, number] = isNight
            ? [0.12, 0.22, 0.38]
            : [0.56, 0.68, 0.78];

        if (attention > 0) {
            bodyColor = isNight
                ? [0.34, 0.12, 0.17]
                : [0.73, 0.37, 0.35];
        } else if (isHovered || isSelected) {
            bodyColor = isNight
                ? [0.14, 0.35, 0.58]
                : [0.35, 0.63, 0.84];
        }

        drawBox([0, y, 0], [4.7, floorHeight / 2, 3.35], bodyColor, isSelected ? 0.12 : 0);

        drawBox(
            [0, y - floorHeight / 2 + 0.08, 0],
            [4.92, 0.08, 3.57],
            isNight ? [0.23, 0.33, 0.48] : [0.31, 0.39, 0.47],
            0
        );

        drawWindows(index, y, floorHeight, isNight, attention > 0);
    }

    const roofY = floorCount * (floorHeight + floorGap) - floorGap + 0.18;
    drawBox(
        [0, roofY, 0],
        [5.0, 0.18, 3.65],
        isNight ? [0.12, 0.18, 0.28] : [0.42, 0.48, 0.52],
        0
    );

    drawBox(
        [0, roofY + 0.48, 0],
        [1.15, 0.3, 0.85],
        isNight ? [0.16, 0.25, 0.36] : [0.54, 0.61, 0.65],
        0
    );
}

function drawWindows(
    floorIndex: number,
    y: number,
    floorHeight: number,
    isNight: boolean,
    hasAttention: boolean
): void {
    const windowColor: [number, number, number] = hasAttention
        ? [0.95, 0.2, 0.25]
        : isNight
            ? [0.12, 0.72, 0.96]
            : [0.14, 0.45, 0.68];
    const emissive = isNight ? 0.28 : 0.04;
    const windowY = y + 0.06;

    for (let column = -3; column <= 3; column += 1) {
        drawBox(
            [column * 1.08, windowY, 3.38],
            [0.35, floorHeight * 0.29, 0.035],
            windowColor,
            emissive
        );

        drawBox(
            [column * 1.08, windowY, -3.38],
            [0.35, floorHeight * 0.29, 0.035],
            windowColor,
            emissive
        );
    }

    for (let column = -2; column <= 2; column += 1) {
        drawBox(
            [4.73, windowY, column * 1.08],
            [0.035, floorHeight * 0.29, 0.35],
            windowColor,
            emissive
        );

        drawBox(
            [-4.73, windowY, column * 1.08],
            [0.035, floorHeight * 0.29, 0.35],
            windowColor,
            emissive
        );
    }

    if (floorIndex === 0) {
        drawBox(
            [0, floorHeight * 0.42, 3.42],
            [0.72, floorHeight * 0.42, 0.06],
            isNight ? [0.07, 0.2, 0.32] : [0.13, 0.3, 0.42],
            0.08
        );
    }
}

function drawBox(
    translation: [number, number, number],
    scale: [number, number, number],
    color: [number, number, number],
    emissive: number
): void {
    if (!gl || !program) {
        return;
    }

    const model = multiplyMatrices(
        translationMatrix(translation[0], translation[1], translation[2]),
        scaleMatrix(scale[0], scale[1], scale[2])
    );

    gl.uniformMatrix4fv(gl.getUniformLocation(program, 'u_model'), false, model);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_color'), color);
    gl.uniform1f(gl.getUniformLocation(program, 'u_emissive'), emissive);
    gl.drawArrays(gl.TRIANGLES, 0, CUBE_VERTEX_COUNT);
}

function selectFloor(floor: Floor, index: number): void {
    selectedFloorId.value = String(floor.id);
    hoveredFloorIndex.value = index;
    emit('select-floor', floor);
}

function getAttentionCount(floor: Floor): number {
    return floor.devices.filter((device) => {
        return device.status === 'offline' || device.status === 'warning';
    }).length;
}

function handlePointerDown(event: PointerEvent): void {
    const canvas = canvasRef.value;

    if (!canvas) {
        return;
    }

    pointerId = event.pointerId;
    previousPointerX = event.clientX;
    previousPointerY = event.clientY;
    canvas.setPointerCapture(event.pointerId);
}

function handlePointerMove(event: PointerEvent): void {
    if (pointerId !== event.pointerId) {
        return;
    }

    const deltaX = event.clientX - previousPointerX;
    const deltaY = event.clientY - previousPointerY;
    previousPointerX = event.clientX;
    previousPointerY = event.clientY;

    yaw -= deltaX * 0.007;
    pitch = clamp(pitch + deltaY * 0.005, -0.08, 1.18);
}

function handlePointerUp(event: PointerEvent): void {
    if (pointerId !== event.pointerId) {
        return;
    }

    canvasRef.value?.releasePointerCapture(event.pointerId);
    pointerId = null;
}

function handleWheel(event: WheelEvent): void {
    distance = clamp(distance + event.deltaY * 0.012, 8.5, 26);
}

function resetCamera(): void {
    yaw = -0.72;
    pitch = 0.48;
    distance = 15.5;
    hoveredFloorIndex.value = null;
    selectedFloorId.value = null;
}

function createProgram(
    context: WebGLRenderingContext,
    vertexSource: string,
    fragmentSource: string
): WebGLProgram {
    const vertexShader = createShader(context, context.VERTEX_SHADER, vertexSource);
    const fragmentShader = createShader(context, context.FRAGMENT_SHADER, fragmentSource);
    const shaderProgram = context.createProgram();

    if (!shaderProgram) {
        throw new Error('Unable to create the WebGL shader program.');
    }

    context.attachShader(shaderProgram, vertexShader);
    context.attachShader(shaderProgram, fragmentShader);
    context.linkProgram(shaderProgram);

    if (!context.getProgramParameter(shaderProgram, context.LINK_STATUS)) {
        const message = context.getProgramInfoLog(shaderProgram) || 'Unknown shader link error.';
        context.deleteProgram(shaderProgram);
        throw new Error(message);
    }

    return shaderProgram;
}

function createShader(
    context: WebGLRenderingContext,
    type: number,
    source: string
): WebGLShader {
    const shader = context.createShader(type);

    if (!shader) {
        throw new Error('Unable to create a WebGL shader.');
    }

    context.shaderSource(shader, source);
    context.compileShader(shader);

    if (!context.getShaderParameter(shader, context.COMPILE_STATUS)) {
        const message = context.getShaderInfoLog(shader) || 'Unknown shader compilation error.';
        context.deleteShader(shader);
        throw new Error(message);
    }

    return shader;
}

function perspectiveMatrix(
    fieldOfView: number,
    aspect: number,
    near: number,
    far: number
): Float32Array {
    const f = 1 / Math.tan(fieldOfView / 2);
    const rangeInverse = 1 / (near - far);

    return new Float32Array([
        f / aspect, 0, 0, 0,
        0, f, 0, 0,
        0, 0, (near + far) * rangeInverse, -1,
        0, 0, near * far * rangeInverse * 2, 0
    ]);
}

function lookAtMatrix(
    eye: number[],
    target: number[],
    up: number[]
): Float32Array {
    const zAxis = normalizeVector([
        eye[0] - target[0],
        eye[1] - target[1],
        eye[2] - target[2]
    ]);
    const xAxis = normalizeVector(crossProduct(up, zAxis));
    const yAxis = crossProduct(zAxis, xAxis);

    return new Float32Array([
        xAxis[0], yAxis[0], zAxis[0], 0,
        xAxis[1], yAxis[1], zAxis[1], 0,
        xAxis[2], yAxis[2], zAxis[2], 0,
        -dotProduct(xAxis, eye),
        -dotProduct(yAxis, eye),
        -dotProduct(zAxis, eye),
        1
    ]);
}

function translationMatrix(x: number, y: number, z: number): Float32Array {
    return new Float32Array([
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        x, y, z, 1
    ]);
}

function scaleMatrix(x: number, y: number, z: number): Float32Array {
    return new Float32Array([
        x, 0, 0, 0,
        0, y, 0, 0,
        0, 0, z, 0,
        0, 0, 0, 1
    ]);
}

function multiplyMatrices(a: Float32Array, b: Float32Array): Float32Array {
    const result = new Float32Array(16);

    for (let column = 0; column < 4; column += 1) {
        for (let row = 0; row < 4; row += 1) {
            result[column * 4 + row] =
                a[row] * b[column * 4] +
                a[4 + row] * b[column * 4 + 1] +
                a[8 + row] * b[column * 4 + 2] +
                a[12 + row] * b[column * 4 + 3];
        }
    }

    return result;
}

function normalizeVector(vector: number[]): number[] {
    const length = Math.hypot(vector[0], vector[1], vector[2]) || 1;

    return [
        vector[0] / length,
        vector[1] / length,
        vector[2] / length
    ];
}

function crossProduct(a: number[], b: number[]): number[] {
    return [
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0]
    ];
}

function dotProduct(a: number[], b: number[]): number {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

function clamp(value: number, minimum: number, maximum: number): number {
    return Math.min(Math.max(value, minimum), maximum);
}
</script>

<style scoped src="./BuildingScene3D.css"></style>
