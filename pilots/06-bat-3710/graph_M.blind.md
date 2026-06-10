## Symptom

`stdout` is a pipe, but `bat --color=always --decorations=auto foo | cat` still enters the interactive/highlighting printer with the default decorative style enabled, so it prints headers, grid borders, and line numbers. `--color=always` is supposed to force ANSI colors only; it should not force decorations.

## Localization

`src/bin/bat/app.rs:60`

```rust
let interactive_output = std::io::stdout().is_terminal();
```

This is the only stdout terminal detection used by option resolution.

`src/bin/bat/app.rs:431`

```rust
colored_output: self.matches.get_flag("force-colorization")
    || match self.matches.get_one::<String>("color").map(|s| s.as_str()) {
        Some("always") => true,
        Some("never") => false,
        Some("auto") => !env_no_color() && self.interactive_output,
        _ => unreachable!("other values for --color are not allowed"),
    },
```

`--color=always` correctly sets only `colored_output = true`.

`src/bin/bat/app.rs:440`

```rust
loop_through: !(self.interactive_output
    || self.matches.get_one::<String>("color").map(|s| s.as_str()) == Some("always")
    || self.matches.get_one::<String>("decorations").map(|s| s.as_str()) == Some("always")
    || self.matches.get_flag("force-colorization")
    || self.number_from_cli),
```

This is the bad coupling: `--color=always` disables `loop_through` even when stdout is not a terminal. That routes piped output through `InteractivePrinter`.

`src/controller.rs:192`

```rust
let mut printer: Box<dyn Printer> = if self.config.loop_through {
    Box::new(SimplePrinter::new(self.config))
} else {
    Box::new(InteractivePrinter::new(...)?)
};
```

Once `loop_through` is false, the decorative printer is used.

`src/bin/bat/app.rs:573`

```rust
fn forced_style_components(&self) -> Option<StyleComponents> {
    // No components if `--decorations=never``.
    if self.matches.get_one::<String>("decorations").map(|s| s.as_str()) == Some("never") {
        return Some(StyleComponents(HashSet::new()));
    }
```

`--decorations=never` is honored. `--decorations=auto` is not handled here.

`src/bin/bat/app.rs:610`

```rust
fn style_components(&self) -> Result<StyleComponents> {
    ...
    None => StyleComponents(HashSet::from_iter(
        StyleComponent::Default
            .components(self.interactive_output)
            .iter()
            .cloned(),
    )),
```

The default style is resolved as `Default`, not `Auto`.

`src/style.rs:27`

```rust
StyleComponent::Auto => {
    if interactive_terminal {
        StyleComponent::Default.components(interactive_terminal)
    } else {
        StyleComponent::Plain.components(interactive_terminal)
    }
}
...
StyleComponent::Default => &[
    StyleComponent::Changes,
    StyleComponent::Grid,
    StyleComponent::HeaderFilename,
    StyleComponent::LineNumbers,
    StyleComponent::Snip,
],
```

`Auto` would become plain when piped. But the default path uses `Default`, which always includes decorations.

`src/printer.rs:236`

```rust
if config.style_components.numbers() {
    decorations.push(Box::new(LineNumberDecoration::new(&colors)));
}
...
if config.style_components.grid() && !decorations.is_empty() {
    decorations.push(Box::new(GridBorderDecoration::new(&colors)));
}
```

`InteractivePrinter` turns those resolved style components into actual line numbers/grid.

`src/printer.rs:483`

```rust
if !self.config.style_components.header() {
    ...
} else ...
```

Header printing is likewise controlled by style components, not by a separate `decorations=auto` gate.

## Root-cause hypothesis

The bug is an interaction between two design shortcuts:

1. Piped output normally avoids decorations by staying in `loop_through`/`SimplePrinter`.
2. `--color=always` forces `loop_through = false` so syntax highlighting can still run through `InteractivePrinter`.

Once `--color=always` forces the interactive printer, `--decorations=auto` has no remaining effect. The style resolver falls back to `StyleComponent::Default`, which always includes decorative components, even when `interactive_output == false`.

So the causal chain is:

`stdout is pipe` -> `interactive_output = false` -> `--color=always` -> `loop_through = false` -> `InteractivePrinter` -> default `style_components = Default` -> line numbers/grid/header printed.

The decoration policy is currently implicit in printer selection and partially in `StyleComponent::Auto`; it is not enforced as an independent gate after color forces the non-loop printer path.

## Rivals considered and killed

1. `stdout.is_terminal()` is misdetecting the pipe.

Killed by code and behavior: `interactive_output` comes directly from `std::io::stdout().is_terminal()` at `app.rs:60`, and normal piped output without `--color=always` uses `loop_through`. The failure appears specifically because `--color=always` overrides the loop-through decision at `app.rs:441`.

2. `--decorations=auto` is being parsed as `always`.

Killed by `clap_app.rs:307`: valid values are `auto`, `never`, `always`, default is `auto`. The later code checks `Some("always")` only for loop-through and `Some("never")` only for forced empty style. There is no evidence that parsing changes `auto` into `always`; the problem is that `auto` is not applied as a decoration gate.

## Predicted fix shape

Separate decoration gating from color gating.

Likely shape:

```rust
let decorations = self.matches.get_one::<String>("decorations").map(|s| s.as_str());
let decorations_enabled =
    decorations == Some("always") || (decorations == Some("auto") && self.interactive_output);
```

Then apply that independently of `colored_output`:

- `--color=always` may still set `colored_output = true` and force `loop_through = false` so highlighting can happen.
- If `decorations_enabled == false`, strip decorative style components before building `Config`, or resolve the default style as plain/auto for the noninteractive decoration case.
- `--decorations=always` keeps full decorations when piped.
- `--decorations=never` keeps forcing no decorations.
- `--style=full --decorations=auto` should still suppress decorations when piped, because `decorations=auto` is the final gate over decoration components, not just an input to default style selection.
