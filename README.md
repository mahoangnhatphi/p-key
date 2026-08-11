# P-Key

P-Key is a small Windows Vietnamese input method written in Free Pascal and Lazarus. It runs in the system tray and supports both VNI and Telex typing.

## Features

- VNI and Telex input modes
- Vietnamese Unicode output through the Windows keyboard hook
- System tray operation with a single running instance
- One self-contained Windows executable for distribution

## Requirements

- Windows
- Lazarus with Free Pascal
- Lazarus installed in `C:\lazarus`, or set `LAZARUS_DIR` before running the build script

## Build

```bat
build.bat
```

The output is `src\p_key.exe`. Distribute this EXE alone; it uses only standard Windows system DLLs.

## Run

```bat
src\p_key.exe
```

Choose **VNI** or **Telex** in the window. Closing the window hides it to the system tray. Use **Thoat** to exit completely.

## VNI Keys

| Key | Action |
| --- | --- |
| `1 2 3 4 5` | sac, huyen, hoi, nga, nang |
| `6 7 8 9` | circumflex, horn, breve, d |
| `0` | remove tone |

Example: `tie61ng` becomes `tiếng`.

## Telex Keys

| Key | Action |
| --- | --- |
| `s f r x j` | sac, huyen, hoi, nga, nang |
| `aa aw ee oo ow uw dd` | â, ă, ê, ô, ơ, ư, đ |
| `z` | remove Vietnamese mark |

Example: `tieengs` becomes `tiếng`.

## Tests

```bat
fpc -Fu=src -Fu=tests -FcUTF8 tests\test_vni_engine.pas
tests\test_vni_engine.exe
```

The test program covers VNI and Telex conversion rules.

## Layout

```text
src/
  app.ico                 application icon
  app.rc                  Windows icon resource
  main_form.pas           Lazarus UI and Windows keyboard hook
  p_key.lpr               application entry point
  p_key.lpi               Lazarus project
  syllable_parser.pas     Vietnamese tone placement
  vietnamese_chars.pas    Unicode Vietnamese character map
  vni_engine.pas          shared VNI and Telex conversion engine
tests/
  test_vni_engine.pas     engine tests
```
