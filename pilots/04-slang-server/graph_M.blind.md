## Symptom

Hover markdown for SystemVerilog macro text containing backticks is emitted as an inline code span delimited by single backticks. For content like:

```systemverilog
`define MACRO_A 10
`define JOIN_MACRO(name) name```MACRO_A
```

the emitted markdown can look like:

```markdown
``define MACRO_A 10`
```

The leading backtick in the macro body merges with or closes the single-backtick delimiter, so the client renders broken markdown instead of literal code.

## Localization

`src/util/Markdown.cpp:53`

```cpp
Paragraph& Paragraph::appendCode(std::string_view code) {
    fmt::format_to(std::back_inserter(buffer), "`{}`", code);
    return *this;
}
```

This is the hover inline-code primitive. It always wraps content with exactly one backtick and does not inspect the content.

Relevant hover call sites include `src/Hovers.cpp:32`, `src/Hovers.cpp:50`, `src/Hovers.cpp:79`, `src/Hovers.cpp:98`, `src/Hovers.cpp:112`, and `src/Hovers.cpp:120`, all via `appendCode(...)`.

Contrast: fenced SystemVerilog hover blocks already account for triple-backtick token paste:

`src/util/Markdown.cpp:74`

```cpp
Paragraph& Paragraph::appendCodeBlock(std::string_view code) {
    // Use quad backticks for SystemVerilog since triple can be used in macro concatenations
    fmt::format_to(std::back_inserter(buffer), "````systemverilog\n{}\n````", code);
    return *this;
}
```

`src/util/Formatting.cpp:341`

```cpp
std::string svCodeBlockString(std::string_view code) {
    ...
    // We use quad backticks since in sv triple can be used for macro concatenations
    return fmt::format("````systemverilog\n{}\n````", res);
}
```

## Root-cause hypothesis

`Paragraph::appendCode` assumes inline code content never contains backticks. That assumption is false for SystemVerilog macros because a macro directive begins with a backtick and token paste can contain up to three consecutive backticks.

The broken output is exactly predicted by `fmt::format("`{}`", code)` when `code` starts with `` `define ``: the opening delimiter and the first content byte become adjacent backticks, and markdown no longer has an unambiguous single-backtick span.

The block-code path is not the vulnerable primitive here; it already uses quad fences because the authors knew triple backticks are valid SystemVerilog. The missing equivalent logic is in the inline-code path.

## Rivals considered and killed

1. Escape backticks inside `appendCode`.

Killed. The repo’s plaintext markdown escaper explicitly treats backticks as markdown syntax at `src/util/Markdown.cpp:193`, but inline code spans are not repaired by backslash-escaping their contents in the same way. The correct markdown mechanism for literal backticks inside inline code is choosing a delimiter run longer than any run in the content, with padding when needed.

2. Use a fixed double or triple backtick delimiter.

Killed. The issue’s second failing snippet contains `name```MACRO_A`, so triple backticks are valid source content. A triple delimiter collides with token paste. A double delimiter also fails on any content with ``. Single already fails on ordinary macro directives. Since this codebase comments that valid SV can use triple backticks, any fixed delimiter shorter than four is insufficient.

## Predicted fix shape

Change `Paragraph::appendCode` to generate a safe inline-code delimiter.

Likely implementation shape:

```cpp
Paragraph& Paragraph::appendCode(std::string_view code) {
    auto delimiter = std::string(maxBacktickRun(code) + 1, '`');
    fmt::format_to(std::back_inserter(buffer), "{} {} {}", delimiter, code, delimiter);
    return *this;
}
```

For SystemVerilog specifically, fixed quad backticks plus one space of padding also handles all valid backtick runs because valid source has at most three consecutive backticks:

```markdown
```` `define MACRO_A 10 ````
```` `define JOIN_MACRO(name) name```MACRO_A ````
```

The more general dynamic version is preferable because it makes `appendCode` correct for all inline markdown content, not only valid SystemVerilog.
