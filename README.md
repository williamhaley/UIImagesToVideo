# UIImagesToVideo

## Bug

[Stack Overflow Thread: Video generated from UIImage array is corrupt at certain dimensions
](https://stackoverflow.com/questions/62868226/)

```
// The image sizes are consistent. Use the first one to determine the video size. 3024 × 4032
let originalSize = images[0].size

// This fails. ❌
//        let outputSize = CGSize(width: originalSize.width, height: originalSize.height)

// This fails. ❌
//        let outputSize = CGSize(width: originalSize.width - 512, height: originalSize.height - 509)

// This fails. ❌
//        let outputSize = CGSize(width: originalSize.width - 511, height: originalSize.height - 510)

// This works. ✅ We could go smaller and keep the aspect ratio, but the specific numbers
// for the cutoff seem worth nothing here.
let outputSize = CGSize(width: originalSize.width - 512, height: originalSize.height - 510)
```
