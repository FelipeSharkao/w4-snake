import { $, Glob } from "bun";
import fs from "node:fs/promises";

const isProd = process.env.NODE_ENV?.toLowerCase() == "production";

if (isProd) {
    await build();
} else {
    watch();
}

async function build() {
    const optimize = isProd ? "ReleaseFast" : "Debug";
    await cmd("BUILD", "zig", "build", `-Doptimize=${optimize}`);
}

async function watch() {
    await build();
    run();

    const path = `${import.meta.dir}/src`;

    console.log(`Watching changes in path`);

    const glob = new Glob("**/*.zig");
    const watcher = fs.watch(path, { recursive: true });

    for await (const event of watcher) {
        if (event.filename && glob.match(event.filename)) {
            build();
        }
    }
}

async function run() {
    await cmd("RUN", "w4", "run", "--hot", `${import.meta.dir}/zig-out/bin/cart.wasm`);
}

async function cmd(prefix: string, exec: string, ...args: string[]) {
    const cmd = [exec, ...args];
    console.log();
    console.log(`Running ${cmd.join(" ")}`);
    const proc = Bun.spawn(cmd, { stderr: "pipe" });

    await Promise.allSettled([
        (async () => {
            for await (const line of getLines(proc.stdout)) {
                console.log(`[${prefix}] ${line}`);
            }
        })(),
        (async () => {
            for await (const line of getLines(proc.stderr)) {
                console.log(`[${prefix}] ${line}`);
            }
        })(),
    ]);

    return proc.exited;
}

async function* getLines(stream: ReadableStream<AllowSharedBufferSource>) {
    const nl = /\r*\n\r*/;
    let buffer = "";

    for await (const value of stream.values()) {
        buffer += new TextDecoder().decode(value);
        if (!buffer.match(nl)) {
            continue;
        }
        const lines = buffer.split(nl);
        yield* lines.slice(0, -1);
        buffer = lines.slice(-1)[0];
    }

    if (buffer) {
        yield buffer;
    }
}
