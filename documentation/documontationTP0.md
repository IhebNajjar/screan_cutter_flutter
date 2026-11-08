# Screen Cutter

Screen Cutter is a Flutter canvas app. Clicking a section cuts that section through its exact center. The two new sections can continue to be cut until they are too small to split.

This document is written for anyone who needs to run, understand, maintain, or extend the app.

## Project Information

- **Framework:** Flutter
- **Language:** Dart
- **Main target:** Web, tested with Microsoft Edge
- **Application folder:** `screan_cutter`
- **Main source:** `lib/main.dart`
- **Widget test:** `test/widget_test.dart`
- **Color dependency:** `flutter_colorpicker`

## Run The App

Always run Flutter commands from the project folder, the folder containing `pubspec.yaml`:

```powershell
cd screan_cutter
flutter pub get
flutter run -d edge
```

Running `flutter run` from the parent `crospllatform` folder causes `No pubspec.yaml file found` because that folder is not the Flutter project root.

## User Guide

### Cut the canvas

1. Click anywhere on the canvas.
2. The app finds the section under the pointer.
3. The section is split exactly through its center, not where the pointer is.
4. Wide sections split vertically. Tall sections split horizontally.
5. Click any new section to split it again.

The app stops splitting a section when both of its dimensions are below two logical pixels.

### Choose a color

1. Open the left drawer with the menu icon.
2. Select **Open color picker**.
3. Choose a color with the standard color picker.
4. Press **Choose** to apply it.

When a color is chosen, existing sections keep their shapes but are recolored with lighter shades of that color. New sections also use lighter shades based on their position.

### Random colors

Press **Randomize colors** in the drawer to:

- Immediately give every existing section a random color.
- Turn random color mode on for future cuts.
- Use a new random color for each new section.

Choosing a specific color in the color picker turns random mode off.

### Canvas settings

The left drawer also contains:

- **Border width:** controls separator thickness from 0.5 to 8.
- **Corner roundness:** rounds the separator stroke corners from 0 to 32.

The colored fills remain square. Only the lighter separator borders are rounded.

### History and reset

- The undo arrow restores the previous canvas state.
- The redo arrow restores an undone state.
- Reset clears all sections and returns the cut count to zero.
- A new edit clears the redo history.

History currently covers cuts, color changes, randomization, and reset. Slider changes are visual settings and are not stored in the undo history.

## Widget And Code Structure

All application code currently lives in `lib/main.dart`.

### `MyApp`

`MyApp` is the root `StatelessWidget`. It creates the `MaterialApp`, sets the application title and theme, and opens `MyHomePage`.

Change this widget when you need to modify:

- Global theme colors.
- Application title.
- The first screen shown at startup.

### `MyHomePage`

`MyHomePage` is a `StatefulWidget` because the canvas changes after clicks and control actions. It owns `_MyHomePageState`.

The widget itself should remain small. Put changing values and interaction logic in `_MyHomePageState`.

### `_MyHomePageState`

This is the main controller for the application. It owns:

- `_tiles`: the current list of colored rectangular sections.
- `_cuts`: the number displayed in the app bar.
- `_selectedColor`: the base color chosen by the user.
- `_randomColors`: whether new colors should be random.
- `_borderWidth` and `_cornerRadius`: drawing settings.
- `_undoStack` and `_redoStack`: canvas history.

Complete function and constructor reference:

| Name | What it does |
| --- | --- |
| `main()` | Starts Flutter by passing the root `MyApp` widget to `runApp`. |
| `MyApp()` | Constructor for the root application widget. |
| `MyApp.build(context)` | Creates the `MaterialApp`, applies the title and theme, and selects `MyHomePage` as the home screen. |
| `MyHomePage()` | Constructor for the interactive screen widget. |
| `MyHomePage.createState()` | Creates the mutable `_MyHomePageState` object that owns canvas data and controls. |
| `_MyHomePageState._color` | Chooses a random color in random mode; otherwise chooses the next shade for the tile list. This getter is used when creating the initial full-canvas tile. |
| `_MyHomePageState._shadeForTile(index)` | Converts the chosen base color to HSL and generates a shade using the tile's position in a repeating lightness sequence. |
| `_MyHomePageState._selectColor(color)` | Records history, selects the provided color (or a random color if the next-color flag is set), disables random mode, recolors existing tiles, and refreshes the UI. |
| `_MyHomePageState._pickCustomColor()` | Opens a dialog containing `ColorPicker`. Updates the dialog's temporary color while dragging and applies it only after the user presses Choose. Cancel leaves the canvas color unchanged. |
| `_MyHomePageState._snapshot()` | Makes a snapshot of undoable canvas state, including copied tile objects, cut count, selected color, and color-mode flags. |
| `_MyHomePageState._recordChange()` | Adds the current snapshot to undo history and clears redo history because a new edit has been made. |
| `_MyHomePageState._restore(snapshot)` | Replaces the current canvas and color-mode state with values from a snapshot. The caller is responsible for triggering a UI rebuild. |
| `_MyHomePageState._undo()` | Does nothing if undo history is empty; otherwise saves the current state for redo, restores the most recent undo snapshot, and rebuilds the UI. |
| `_MyHomePageState._redo()` | Does nothing if redo history is empty; otherwise saves the current state for undo, restores the most recent redo snapshot, and rebuilds the UI. |
| `_MyHomePageState._cutAt(point, size)` | Creates the initial full-canvas tile if needed, finds the tile containing the tap, and splits it through its center along its longer dimension. Replaces that tile with two tiles and increments the cut count. |
| `_MyHomePageState._reset()` | If there are tiles, records history, clears the canvas, and resets the cut count. It leaves color and drawing settings unchanged. |
| `_MyHomePageState._randomColor()` | Generates a random opaque HSL color with randomized hue, saturation, and lightness. |
| `_MyHomePageState._randomizeColors()` | Records history, enables random mode, picks a new selected color, randomizes existing tile colors, and rebuilds the UI. |
| `_MyHomePageState.build(context)` | Builds the app bar and history/reset buttons, responsive canvas and tap detector, plus the settings drawer, sliders, and color controls. |
| `_Tile(rect, color)` | Constructs the immutable model for one tile, storing its rectangle and fill color. |
| `_CanvasSnapshot(tiles, cuts, selectedColor, randomColors, randomNextColor)` | Constructs a saved copy of the state that undo and redo can restore. |
| `_CutterPainter(tiles, borderWidth, cornerRadius)` | Constructs the custom canvas painter with the tile data and visual settings to draw. |
| `_CutterPainter.paint(canvas, size)` | Paints the empty-canvas background when there are no tiles; otherwise paints every tile's rectangular fill and a lighter, rounded border. Border width and corner radius are limited to sensible sizes for the canvas and tile. |
| `_CutterPainter.shouldRepaint(oldDelegate)` | Tells Flutter to repaint when the tile-list reference, border width, or corner radius differs from the previous painter. |

#### UI callbacks

The `build` methods also define small callbacks inline rather than giving each one a named method:

| Callback | What it does |
| --- | --- |
| `LayoutBuilder` builder | Reads the available canvas size and creates the canvas gesture and painter for that size. |
| `GestureDetector.onTapDown` | Passes the tap's local canvas position and current canvas size to `_cutAt`. |
| Undo/redo button callbacks | Call `_undo` and `_redo`; the buttons are disabled when their corresponding history stack is empty. |
| Reset button callback | Calls `_reset`. |
| Drawer close callback | Closes the drawer using `Navigator.pop`. |
| Border and corner slider callbacks | Update `_borderWidth` or `_cornerRadius` inside `setState`, causing the painter to draw with the new setting. |
| Color-picker button callback | Starts `_pickCustomColor`. |
| Randomize button callback | Calls `_randomizeColors`. |
| Color dialog builder | Creates the dialog and its local `StatefulBuilder`, which lets the temporary picked color update without rebuilding the whole page. |
| Color picker change callback | Updates the dialog's temporary picked color. |
| Cancel and Choose callbacks | Close the dialog without a result, or close it with the chosen `Color`, respectively. |

The widget test file also has two functions:

| Name | What it does |
| --- | --- |
| Test `main()` | Registers the widget test with Flutter's test runner. |
| `testWidgets` callback | Pumps the app, checks its starting cut count, taps the canvas, verifies a cut was made, resets the canvas, and verifies the count returns to zero. |

#### App building blocks

- **Flutter Material widgets:** `MaterialApp`, `Scaffold`, `AppBar`, `Drawer`, buttons, sliders, and dialog provide the app structure and controls.
- **Flutter rendering and geometry:** `CustomPaint`, `CustomPainter`, `Canvas`, `Paint`, `Rect`, `RRect`, `Offset`, and `Size` represent and draw the canvas and tiles.
- **Flutter interaction and state:** `StatefulWidget`, `setState`, `GestureDetector`, `LayoutBuilder`, and `Navigator` handle changing state, taps, responsive sizing, and the color dialog.
- **Dart math library (`dart:math`):** imported as `math`; supplies random-number generation and the `min` function used to bound drawing dimensions.
- **`flutter_colorpicker`:** supplies the hue/saturation/brightness color picker shown in the custom-color dialog.
- **`flutter_test`:** supplies `testWidgets`, `WidgetTester`, and `find` APIs used by the widget test.
- **`flutter_lints`:** development dependency providing recommended Dart and Flutter lint rules, enabled through `analysis_options.yaml`.
- **`cupertino_icons`:** declared in `pubspec.yaml` for Cupertino-style icon assets; the current screen uses Material `Icons` instead.

### `_Tile`

`_Tile` is the data model for one section:

```dart
class _Tile {
  const _Tile(this.rect, this.color);

  final Rect rect;
  final Color color;
}
```

`rect` stores the position and size. `color` stores the fill color. If you add more per-section behavior, add fields here and update `_CanvasSnapshot` too.

### `_CanvasSnapshot`

`_CanvasSnapshot` is a copy of undoable state. It stores the tile list, cut count, selected color, and random-mode flags. Do not store the original mutable tile list directly; snapshots must contain copied tile objects.

### `_CutterPainter`

`_CutterPainter` is a `CustomPainter`. It draws the canvas directly using Flutter's `Canvas` API:

1. Paints each tile as a square rectangle.
2. Calculates a lighter HSL version of that tile color.
3. Draws the lighter separator as a rounded rectangle stroke.

When changing visual rendering, edit `_CutterPainter`. When changing what a click does, edit `_MyHomePageState._cutAt` instead.

## Interaction Flow

```text
Pointer tap
  -> GestureDetector.onTapDown
  -> _cutAt(point, size)
  -> find tile containing point
  -> choose longer dimension
  -> cut at tile.center
  -> replace one _Tile with two _Tile objects
  -> setState
  -> CustomPaint rebuilds and draws the new list
```

Color selection follows this flow:

```text
Open drawer
  -> Open color picker
  -> ColorPicker returns Color
  -> _selectColor(color)
  -> recolor existing tiles
  -> setState
  -> painter redraws
```

## Dependencies

Dependencies are declared in `pubspec.yaml`.

- `flutter`: Flutter framework.
- `flutter_colorpicker`: standard color picker dialog.
- `cupertino_icons`: generated Flutter project icon dependency.

After changing dependencies, run:

```powershell
flutter pub get
```

## Testing And Validation

Run both checks from the project folder:

```powershell
flutter analyze
flutter test
```

The current widget test verifies that:

- The app starts with `Cuts: 0`.
- Tapping the canvas creates the first cut.
- The counter changes to `Cuts: 1`.
- The reset button returns the counter to zero.

When adding a feature, extend `test/widget_test.dart` with a behavior test. Prefer testing visible behavior through `WidgetTester` instead of testing private implementation details.

## Safe Extension Guide

### Add a new canvas setting

1. Add the setting value to `_MyHomePageState`.
2. Add a control to the drawer.
3. Pass the setting into `_CutterPainter` if it only affects drawing.
4. Include it in `_CanvasSnapshot` if undo/redo should restore it.
5. Update `shouldRepaint` when the painter receives the new value.
6. Add a widget test and update this README.

### Change the cutting rule

Edit `_cutAt`. Keep these invariants unless the product requirement changes:

- Only the section under the click is changed.
- The section is cut at its center.
- The replacement rectangles cover the original rectangle without a gap.
- Tiny sections cannot be split forever.
- `setState` wraps changes that must appear on screen.

### Change the color behavior

- Use `_selectColor` for user-selected colors.
- Use `_shadeForTile` for related lighter shades.
- Use `_randomColor` for random colors.
- Keep color changes inside `_recordChange` and `setState` so history and rendering stay correct.

## Common Problems

### `No pubspec.yaml file found`

The command was run from the parent folder. Enter the project first:

```powershell
cd screan_cutter
flutter run -d edge
```

### The app still shows an old version

Use hot reload with `r` in the Flutter terminal. If state is stale, use hot restart with `R`. A full stop and restart may be needed after changing dependencies.

### The color picker import is missing

Run:

```powershell
flutter pub get
```

## Maintenance Checklist

Before handing off a change:

- Keep changes focused in the owning widget or painter.
- Update `README.md` when behavior or controls change.
- Add or update a widget test.
- Run `flutter analyze`.
- Run `flutter test`.
- Confirm the app runs from the `screan_cutter` folder.
