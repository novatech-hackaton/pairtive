// AI models for report verification, loaded lazily and cached across warm invocations.
// - Images: NSFWJS (MobileNetV2 CNN, bundled weights) on pure-JS TensorFlow.js.
// - Text: @tensorflow-models/toxicity (Universal Sentence Encoder based; not a CNN,
//   because CNNs are the right tool for images, not chat text).
import jpeg from 'jpeg-js';
import { amMeanLuminance } from '../shared/amModeration.js';

let tfPromise;
let nsfwPromise;
let toxicityPromise;

async function amTf() {
  if (!tfPromise) {
    tfPromise = (async () => {
      const tf = await import('@tensorflow/tfjs');
      await tf.setBackend('cpu');
      await tf.ready();
      return tf;
    })();
  }
  return tfPromise;
}

export async function amLoadNsfw() {
  if (!nsfwPromise) {
    nsfwPromise = (async () => {
      await amTf();
      const nsfwjs = await import('nsfwjs');
      return nsfwjs.load('MobileNetV2');
    })().catch((err) => {
      nsfwPromise = undefined;
      throw err;
    });
  }
  return nsfwPromise;
}

export async function amLoadToxicity() {
  if (!toxicityPromise) {
    toxicityPromise = (async () => {
      await amTf();
      const toxicity = await import('@tensorflow-models/toxicity');
      // threshold only affects `match`; we read raw probabilities.
      return toxicity.load(0.5, []);
    })().catch((err) => {
      toxicityPromise = undefined;
      throw err;
    });
  }
  return toxicityPromise;
}

/** Decode a JPEG buffer into { tensor, luminance }. Caller must dispose the tensor. */
export async function amDecodeJpeg(buffer) {
  const tf = await amTf();
  const { width, height, data } = jpeg.decode(buffer, { useTArray: true, maxMemoryUsageInMB: 64 });
  const rgb = new Int32Array(width * height * 3);
  for (let i = 0, j = 0; i < data.length; i += 4, j += 3) {
    rgb[j] = data[i];
    rgb[j + 1] = data[i + 1];
    rgb[j + 2] = data[i + 2];
  }
  return { tensor: tf.tensor3d(rgb, [height, width, 3], 'int32'), luminance: amMeanLuminance(data) };
}

/** Classify JPEG frames. Returns [{ predictions, luminance }]. */
export async function amClassifyFrames(buffers) {
  const model = await amLoadNsfw();
  const out = [];
  for (const buf of buffers) {
    const { tensor, luminance } = await amDecodeJpeg(buf);
    try {
      const predictions = await model.classify(tensor, 5);
      out.push({ predictions, luminance });
    } finally {
      tensor.dispose();
    }
  }
  return out;
}

export async function amClassifyText(sentences) {
  if (!sentences.length) return [];
  const model = await amLoadToxicity();
  return model.classify(sentences.map((s) => s.slice(0, 500)));
}
