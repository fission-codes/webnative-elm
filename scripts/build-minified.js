import esbuild from "esbuild"
import fs from "fs"


const globalName = "webnativeElm"


console.log("📦 Bundling & minifying...")

await esbuild.build({
  entryPoints: [ "src/index.ts" ],
  outdir: "dist",
  bundle: true,
  splitting: true,
  minify: true,
  sourcemap: true,
  platform: "browser",
  format: "esm",
  target: "es2020",
  globalName,
  define: {
    "global": "globalThis",
    "globalThis.process.env.NODE_ENV": "production"
  },
})


fs.renameSync("dist/index.js", "dist/index.esm.min.js")
fs.renameSync("dist/index.js.map", "dist/index.esm.min.js.map")



// UMD


const UMD = {
  banner:
    `(function (root, factory) {
    if (typeof define === 'function' && define.amd) {
        // AMD. Register as an anonymous module.
        define([], factory);
    } else if (typeof module === 'object' && module.exports) {
        // Node. Does not work with strict CommonJS, but
        // only CommonJS-like environments that support module.exports,
        // like Node.
        module.exports = factory();
    } else {
        // Browser globals (root is window)
        root.${globalName} = factory();
  }
}(typeof self !== 'undefined' ? self : this, function () {  `,
  footer:
    `return ${globalName};
}));`
}

await esbuild.build({
  entryPoints: [ "src/index.ts" ],
  outfile: "dist/index.umd.min.js",
  bundle: true,
  minify: true,
  sourcemap: true,
  platform: "browser",
  format: "iife",
  target: "es2020",
  globalName,
  define: {
    "global": "globalThis",
    "globalThis.process.env.NODE_ENV": "production"
  },
  banner: { js: UMD.banner },
  footer: { js: UMD.footer },
})