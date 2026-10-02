/// <reference lib="dom" />
// Entry for the `browser` export condition. Hand-written: everything under
// generated/ is ubrn output from `just build-wasm`.
//
// The generated `uniffiInitAsync(source)` takes the .wasm location with no
// default, because only the host knows how its bundler names assets. The file
// ships beside this entry, so it can supply one. `new URL(..., import.meta.url)`
// resolves in Node and is rewritten by Vite, webpack 5 and Rollup when they
// copy the asset. Other hosts pass `source`, e.g. the `bdk-rn/bdkffi.wasm`
// export run through their asset pipeline.
import type { WasmSource } from '@ubjs/wasm';
import { uniffiInitAsync as openWasm } from './generated/index';

export * from './generated/index';
export { default } from './generated/index';

/**
 * Load the wasm module. Await it once before any other call. Later calls
 * return the first call's promise. The React Native entry exports the same
 * function as a no-op, so app code calls it on every platform.
 */
export function uniffiInitAsync(source?: WasmSource): Promise<void> {
  return openWasm(
    source ?? new URL('./generated/bdkffi.wasm', import.meta.url)
  );
}
