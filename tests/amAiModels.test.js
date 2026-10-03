// @vitest-environment node
// End-to-end check of the real NSFWJS CNN on a safe synthetic image: must come back "rejected".
import jpeg from 'jpeg-js';
import { describe, expect, it } from 'vitest';
import { amClassifyFrames } from '../server/amAiModels.js';
import { amAggregateFrameScores, amNsfwFrameScore, amVerdictFromScore } from '../shared/amModeration.js';

function amSafeFrame(width = 224, height = 224, shade = 120) {
  const data = Buffer.alloc(width * height * 4);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 4;
      data[i] = (x * 255) / width; // gradient "whiteboard"
      data[i + 1] = shade;
      data[i + 2] = (y * 255) / height;
      data[i + 3] = 255;
    }
  }
  return jpeg.encode({ data, width, height }, 85).data;
}

describe('NSFWJS end-to-end', () => {
  it('rejects a safe frame', async () => {
    const results = await amClassifyFrames([amSafeFrame(), amSafeFrame(224, 224, 40)]);
    expect(results).toHaveLength(2);
    expect(results[0].predictions.map((p) => p.className)).toContain('Neutral');
    const score = amAggregateFrameScores(results.map((r) => amNsfwFrameScore(r.predictions)));
    expect(amVerdictFromScore(score)).toBe('rejected');
    expect(results[0].luminance).toBeGreaterThan(20);
  }, 120_000);
});
