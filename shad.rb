# Returns Float in interval 0.0 to 1.0 of how much face should be shaded,
# 0.0 being the darkest and 1.0 lightest.
def shade_value(normal, view)
  reference =
    if view.model.shadow_info["UseSunForAllShading"]
      view.model.shadow_info["SunDirection"]
    else
      (view.camera.eye - view.camera.target).normalize
    end

    [normal % reference, 0].max
end

# Select a face and run:
model = Sketchup.active_model
shade_value(model.selection.first.normal, model.active_view)


# Check what side of face is being viewed.
# Assume face is in same coordinate system as camera.
def view_back_face?(face)
  camera = face.model.active_view.camera
  (camera.eye - camera.eye.project_to_plane(face.plane)) % face.normal < 0
end

# Get RGB color of face (not shaded).
# If face has texture, simply return the average color.
# For now ignore material inherited by parent group/component.
def face_color(face)
  if view_back_face?
    if face.back_material
      face.back_material.color
    else
      face.model.rendering_options["FaceFrontColor"]
    end
  else
    if face.material
      face.material.color
    else
      face.model.rendering_options["FaceBackColor"]
    end
  end
end

# Select a face and run:
model = Sketchup.active_model
view_back_face?(model.selection.first)