# `newsfeed-constants`

This crate defines all the shared constants and static references used across the `newsfeed` workspace.

## Purpose

To prevent hard-coded "magic strings" from being scattered across the codebase, this crate centralizes:
- **Database Types**: `ProcedureMap` and `OptionMode` mappings.
- **HTTP Routing**: Route paths and prefix constants.
- **Regular Expressions**: Pre-compiled regex instances using `once_cell::Lazy` to ensure regex parsing is performed only once at startup, reducing runtime overhead.

## Usage

This crate has zero dependencies on other workspace crates and is safe to import anywhere in the project.
