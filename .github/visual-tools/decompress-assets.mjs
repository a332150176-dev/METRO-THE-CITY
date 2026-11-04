import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import { dequantize } from '@gltf-transform/functions';
import { MeshoptDecoder } from 'meshoptimizer';

const paths = [
  'assets/visual_upgrade/downtown.glb',
  'assets/visual_upgrade/alley-apartments.glb',
  'assets/visual_upgrade/tree.glb',
];

await MeshoptDecoder.ready;
const reader = new NodeIO()
  .registerExtensions(ALL_EXTENSIONS)
  .registerDependencies({ 'meshopt.decoder': MeshoptDecoder });
const writer = new NodeIO().registerExtensions(ALL_EXTENSIONS);

for (const path of paths) {
  const document = await reader.read(path);
  await document.transform(dequantize());
  for (const extension of document.getRoot().listExtensionsUsed()) {
    if (extension.extensionName === 'EXT_meshopt_compression') {
      extension.dispose();
    }
  }
  await writer.write(path, document);
  console.log('Decoded to Godot-compatible GLB:', path);
}
