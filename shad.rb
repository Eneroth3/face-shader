module ShadeTest

  # Returns Float in interval 0.0 to 1.0 of how much face should be shaded,
  # 0.0 being the darkest and 1.0 lightest.
  #
  # normal - Normal Vector3d.
  # view   - Sketchup::View object.
  #
  # Examples
  #
  #   model = Sketchup.active_model
  #   shade_value(model.selection.first.normal, model.active_view)
  #
  # Returns float.
  def self.shade_value(normal, view)
    si = view.model.shadow_info
    reference =
      if si["UseSunForAllShading"]
        si["SunDirection"]
      else
        (view.camera.eye - view.camera.target).normalize
      end
      value = normal % reference

      si["UseSunForAllShading"] ? [value, 0].max : value.abs
  end

  # Check what side of face is being viewed.
  # Assume face is in same coordinate system as camera.
  #
  # face - A Face entity.
  # camera - A Camera object (default: the camera of the same model fce is in).
  #
  # Returns Boolean.
  def self.view_back_face?(face, camera = nil)
    camera ||= face.model.active_view.camera
    (camera.eye - camera.eye.project_to_plane(face.plane)) % face.normal < 0
  end

  # Get RGB color of face (not shaded).
  # If face has texture, simply return the average color.
  # For now ignore material inherited by parent group/component.
  #
  # face - A Face Entity.
  #
  # Returns Color object.
  def self.face_color(face)
    if view_back_face?(face)
      if face.back_material
        face.back_material.color
      else
        face.model.rendering_options["FaceBackColor"]
      end
    else
      if face.material
        face.material.color
      else
        face.model.rendering_options["FaceFrontColor"]
      end
    end
  end

  def self.shade_color(color, normal, view)
    si = view.model.shadow_info
    light = si["UseSunForAllShading"] ? si["Light"]/100.0 : 0.81
    dark = si["UseSunForAllShading"] ? si["Dark"]/100.0 : 0.2
    shading = shade_value(normal, view)
    shift = 0.2 + dark + shading*light

    Sketchup::Color.new(*color.to_a[0, 3].map { |c| [(c*shift).to_i, 255].min })
  end

  def self.shade_face_color(face)
    shade_color(face_color(face), face.normal, face.model.active_view)
  end

end

# Select face and run:
ShadeTest.shade_face_color(Sketchup.active_model.selection.first)