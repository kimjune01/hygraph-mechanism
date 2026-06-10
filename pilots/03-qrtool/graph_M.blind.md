## Symptom

`qrtool decode image.jpg` can exit successfully with no stdout and no stderr when the image is readable but no QR grid is detected.

## Localization

`src/app.rs:209`

```rust
let get_contents = |image| {
    let mut image = PreparedImage::prepare(image);
    let grids = image.detect_grids();
    decode::grids_as_bytes(grids).context("could not decode the grid")
};
```

`src/app.rs:218`

```rust
let contents = match get_contents(image.clone()) {
    Err(e) => {
        imageops::invert(&mut image);
        get_contents(image).map_err(|_| e)?
    }
    Ok(contents) if contents.is_empty() => {
        imageops::invert(&mut image);
        get_contents(image).unwrap_or(contents)
    }
    Ok(contents) => contents,
};

for content in contents {
```

`src/decode.rs:47`

```rust
pub fn grids_as_bytes<G: BitGrid>(
    grids: impl AsRef<[Grid<G>]>,
) -> Result<Vec<DecodedBytes>, DeQRError> {
    grids
        .as_ref()
        .iter()
        .map(|grid| grid_as_bytes(grid))
        .collect()
}
```

## Root-cause hypothesis

When `rqrr::PreparedImage::detect_grids()` finds no QR code, it returns an empty grid list. `decode::grids_as_bytes()` treats that as a successful collection over an empty iterator, returning `Ok(vec![])`.

The decode path notices empty contents once and retries with an inverted image, but if that also returns `Ok(vec![])`, `contents` remains empty. The code then enters `for content in contents`, which performs zero iterations, writes nothing, and returns `Ok(())`. Because no error is constructed for the “no grids found” state, `main` has nothing to report.

## Rivals considered and killed

1. Image loading or format detection failure: ruled out because those paths use `context("could not determine the image format")` or `context("could not read the image")` and return an error, not silent success.

2. QR decode failure after detecting a grid: ruled out because `grid.decode_to(...)` returns `DeQRError`, `grids_as_bytes(...)` propagates it, and the caller either retries inverted or returns an error. The silent path specifically requires no detected grids, not a failed decode of a detected grid.

## Predicted fix shape

After both the normal and inverted decode attempts, explicitly treat `contents.is_empty()` as a decode failure. Add a decode-specific error such as `NoQrCode` with a user-facing message like “no QR code found in the image”, return it from `app::run`, and map it in `main` to a data-error style exit code. Add a regression test using a valid image with no QR code that asserts nonzero exit and clear stderr instead of empty successful output.
