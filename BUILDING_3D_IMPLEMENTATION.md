# Navigable 3D Building View

The Building page now contains a real WebGL scene rendered directly by the template, without external network requests or backend changes.

## Controls

- Drag inside the canvas to orbit around the building.
- Use the mouse wheel or trackpad to zoom.
- Switch between day and night environments.
- Enable or disable automatic rotation.
- Reset the camera at any time.
- Select a Fleet Manager floor from the scene-level panel to continue to its floor scheme.

## Data mapping

Fleet Manager groups are rendered as individual building floors. Floor device health changes the visual state of the corresponding 3D level:

- operational floors use the standard blue building material;
- floors with offline or warning devices use an attention material;
- hover and selection highlight the matching 3D floor.

The implementation is located in:

- `templates/preslav-bms/components/building/BuildingScene3D.vue`
- `templates/preslav-bms/components/building/BuildingScene3D.css`
