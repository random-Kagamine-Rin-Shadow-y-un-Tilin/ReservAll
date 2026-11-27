import { readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const raw = (process.argv[2] ?? "").replace(/^v/, "");

if (!/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/.test(raw)) {
  throw new Error("Uso: node scripts/update-version.mjs <versión semántica>");
}

// Dart/Flutter solo acepta versiones numéricas + número de build.
const version = raw.split(/[-+]/)[0];

function updateJson(relativePath) {
  const path = resolve(root, relativePath);
  const data = JSON.parse(readFileSync(path, "utf8"));
  data.version = version;
  writeFileSync(path, `${JSON.stringify(data, null, 2)}\n`);
}

function updatePubspec(relativePath) {
  const path = resolve(root, relativePath);
  const content = readFileSync(path, "utf8");
  const buildMatch = content.match(/^version:\s*\d+\.\d+\.\d+\+(\d+)\s*$/m);
  if (!buildMatch) {
    throw new Error(`No se encontró una versión válida en ${relativePath}`);
  }
  const build = Number(buildMatch[1]) + 1;
  const updated = content.replace(
    /^version:.*(?=\r?$)/m,
    `version: ${version}+${build}`,
  );
  writeFileSync(path, updated);
}

updateJson("package.json");
updateJson("web-negocio/package.json");
updatePubspec("movil-negocio/pubspec.yaml");
updatePubspec("movil-cliente/pubspec.yaml");
writeFileSync(resolve(root, "VERSION"), `${version}\n`);

console.log(`Versiones actualizadas a ${version}`);
